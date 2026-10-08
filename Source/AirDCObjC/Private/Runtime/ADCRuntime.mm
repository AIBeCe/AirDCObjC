#import <AirDCObjC/ADCRuntime.h>
#import "ADCRuntime+Private.h"
#import <AirDCObjC/ADCError.h>
#import "ADCRuntimeEvent+Private.h"
#import "ADCSubscription+Private.h"

#pragma push_macro("YES")
#pragma push_macro("NO")
#undef YES
#undef NO

#include <airdcpp/stdinc.h>
#include <airdcpp/DCPlusPlus.h>
#include <airdcpp/core/Singleton.h>
#include <airdcpp/core/classes/Exception.h>
#include <airdcpp/core/geo/GeoManager.h>
#include <airdcpp/core/io/File.h>
#include <airdcpp/core/localization/ResourceManager.h>
#include <airdcpp/core/timer/TimerManager.h>
#include <airdcpp/connectivity/ConnectivityManager.h>
#include <airdcpp/connection/ConnectionManager.h>
#include <airdcpp/connection/socket/BufferedSocket.h>
#include <airdcpp/core/crypto/CryptoManager.h>
#include <airdcpp/events/LogManager.h>
#include <airdcpp/favorites/FavoriteManager.h>
#include <airdcpp/favorites/FavoriteUserManager.h>
#include <airdcpp/filelist/DirectoryListingManager.h>
#include <airdcpp/hash/HashManager.h>
#include <airdcpp/hub/ClientManager.h>
#include <airdcpp/hub/activity/ActivityManager.h>
#include <airdcpp/hub/user_command/UserCommandManager.h>
#include <airdcpp/private_chat/PrivateChatManager.h>
#include <airdcpp/protocol/ProtocolCommandManager.h>
#include <airdcpp/queue/QueueManager.h>
#include <airdcpp/queue/partial_sharing/PartialSharingManager.h>
#include <airdcpp/recents/RecentManager.h>
#include <airdcpp/search/SearchManager.h>
#include <airdcpp/connection/UDPServer.h>
#include <airdcpp/settings/SettingsManager.h>
#include <airdcpp/share/ShareManager.h>
#include <airdcpp/share/temp_share/TempShareManager.h>
#include <airdcpp/transfer/TransferInfoManager.h>
#include <airdcpp/transfer/download/DownloadManager.h>
#include <airdcpp/transfer/upload/UploadManager.h>
#include <airdcpp/transfer/upload/upload_bundles/UploadBundleManager.h>
#include <airdcpp/connection/ThrottleManager.h>
#include <airdcpp/core/update/UpdateManager.h>
#include <airdcpp/util/AppUtil.h>
#include <airdcpp/user/ignore/IgnoreManager.h>
#include <airdcpp/viewed_files/ViewFileManager.h>

#pragma pop_macro("NO")
#pragma pop_macro("YES")

#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#include <condition_variable>
#include <cerrno>
#include <cstring>
#include <deque>
#include <exception>
#include <functional>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>

namespace {

class CoreExecutor final {
public:
    CoreExecutor() : stopping(false), worker([this] { run(); }) { }

    ~CoreExecutor() {
        {
            std::lock_guard<std::mutex> guard(mutex);
            stopping = true;
        }
        condition.notify_one();
        if (worker.joinable()) {
            worker.join();
        }
    }

    void enqueue(std::function<void()> task) {
        {
            std::lock_guard<std::mutex> guard(mutex);
            if (stopping) {
                throw std::runtime_error("Core executor is stopping");
            }
            tasks.emplace_back(std::move(task));
        }
        condition.notify_one();
    }

private:
    void run() noexcept {
        while (true) {
            std::function<void()> task;
            {
                std::unique_lock<std::mutex> lock(mutex);
                condition.wait(lock, [this] { return stopping || !tasks.empty(); });
                if (stopping && tasks.empty()) return;
                task = std::move(tasks.front());
                tasks.pop_front();
            }
            @autoreleasepool {
              try {
                task();
              } catch (...) {
                // Each submitted runtime operation translates its own Core boundary.
              }
            }
        }
    }

    std::mutex mutex;
    std::condition_variable condition;
    std::deque<std::function<void()>> tasks;
    bool stopping;
    std::thread worker;
};

std::mutex executorMutex;
std::unique_ptr<CoreExecutor> processExecutor;
std::mutex ownerMutex;
__strong ADCRuntime *processOwner = nil;

CoreExecutor& getCoreExecutor() {
    std::lock_guard<std::mutex> guard(executorMutex);
    if (!processExecutor) {
        processExecutor = std::make_unique<CoreExecutor>();
    }
    return *processExecutor;
}

NSError *runtimeError(ADCErrorCode code, NSString *description, NSError * _Nullable underlying = nil) {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[NSLocalizedDescriptionKey] = description ?: @"Runtime operation failed";
    if (underlying) info[NSUnderlyingErrorKey] = underlying;
    return [NSError errorWithDomain:ADCErrorDomain code:code userInfo:info];
}

NSString *stringFromCore(const std::string& value) {
    NSString *result = [[NSString alloc] initWithBytes:value.data()
                                                 length:value.size()
                                               encoding:NSUTF8StringEncoding];
    return result ?: @"<Core message is not valid UTF-8>";
}

std::string utf8Path(NSString *path) {
    NSData *data = [path dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!data) throw std::runtime_error("A runtime path cannot be represented as UTF-8");
    return std::string(static_cast<const char *>(data.bytes), data.length);
}

std::string withTrailingSlash(std::string path) {
    if (path.empty() || path.back() != '/') path.push_back('/');
    return path;
}

NSString *xmlEscaped(NSString *value) {
    NSString *escaped = [value stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    return escaped;
}

bool inspectDirectory(NSString *path, bool shouldExist, bool writable, NSString **error) {
    struct stat info = {};
    if (lstat(path.fileSystemRepresentation, &info) != 0) {
        if (errno != ENOENT || shouldExist) {
            if (error) *error = [NSString stringWithFormat:@"Directory is unavailable: %@", path];
            return false;
        }
        return true;
    }
    if (!S_ISDIR(info.st_mode)) {
        if (error) *error = [NSString stringWithFormat:@"Expected a directory at %@", path];
        return false;
    }
    int required = R_OK | X_OK | (writable ? W_OK : 0);
    if (access(path.fileSystemRepresentation, required) != 0) {
        if (error) *error = [NSString stringWithFormat:@"Directory permissions do not meet the runtime requirements: %@", path];
        return false;
    }
    return true;
}

bool prepareDirectory(NSString *path, bool create, bool writable, NSString **error) {
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL isDirectory = NO;
    BOOL exists = [manager fileExistsAtPath:path isDirectory:&isDirectory];
    if (!exists && create) {
        NSError *createError = nil;
        if (![manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{ NSFilePosixPermissions: @0700 } error:&createError]) {
            if (error) *error = createError.localizedDescription ?: @"Unable to create runtime directory";
            return false;
        }
        exists = YES;
        isDirectory = YES;
    }
    if (!exists || !isDirectory || !inspectDirectory(path, true, writable, error)) {
        if (error && !*error) *error = [NSString stringWithFormat:@"Expected an accessible directory at %@", path];
        return false;
    }
    return true;
}

bool writeBootConfiguration(NSString *bootstrapPath,
                            NSString *profilePath,
                            NSString *resourcePath,
                            NSString *temporaryPath,
                            NSString **error) {
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL directory = NO;
    if ([manager fileExistsAtPath:bootstrapPath isDirectory:&directory]) {
        struct stat info = {};
        if (lstat(bootstrapPath.fileSystemRepresentation, &info) != 0 || !S_ISDIR(info.st_mode) || S_ISLNK(info.st_mode)) {
            if (error) *error = @"The runtime bootstrap directory must be a real directory";
            return false;
        }
    } else {
        NSError *createError = nil;
        if (![manager createDirectoryAtPath:bootstrapPath withIntermediateDirectories:NO attributes:@{ NSFilePosixPermissions: @0700 } error:&createError]) {
            if (error) *error = createError.localizedDescription ?: @"Unable to create runtime bootstrap directory";
            return false;
        }
    }

    NSString *userOverridePath = [bootstrapPath stringByAppendingPathComponent:@"dcppboot.xml.user"];
    struct stat overrideInfo = {};
    if (lstat(userOverridePath.fileSystemRepresentation, &overrideInfo) == 0) {
        if (error) *error = @"The framework-owned bootstrap directory contains an unexpected dcppboot.xml.user override";
        return false;
    }
    if (errno != ENOENT) {
        if (error) *error = [NSString stringWithFormat:@"Unable to inspect the runtime boot override path: %s", strerror(errno)];
        return false;
    }

    NSString *bootPath = [bootstrapPath stringByAppendingPathComponent:@"dcppboot.xml"];
    struct stat bootInfo = {};
    if (lstat(bootPath.fileSystemRepresentation, &bootInfo) == 0 && (!S_ISREG(bootInfo.st_mode) || S_ISLNK(bootInfo.st_mode))) {
        if (error) *error = @"The runtime boot configuration must be a regular file";
        return false;
    }

    NSString *xml = [NSString stringWithFormat:
        @"<Boot><LocalMode>1</LocalMode><ConfigPath>%@</ConfigPath><TempPath>%@</TempPath><ResourcePath>%@</ResourcePath></Boot>",
        xmlEscaped(profilePath), xmlEscaped(temporaryPath), xmlEscaped(resourcePath)];
    NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    int descriptor = open(bootPath.fileSystemRepresentation, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (descriptor < 0) {
        if (error) *error = [NSString stringWithFormat:@"Unable to write runtime boot configuration: %s", strerror(errno)];
        return false;
    }
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    size_t remaining = data.length;
    while (remaining > 0) {
        ssize_t written = write(descriptor, bytes, remaining);
        if (written <= 0) {
            int savedError = errno;
            close(descriptor);
            if (error) *error = [NSString stringWithFormat:@"Unable to finish runtime boot configuration: %s", strerror(savedError)];
            return false;
        }
        bytes += written;
        remaining -= static_cast<size_t>(written);
    }
    if (close(descriptor) != 0) {
        if (error) *error = [NSString stringWithFormat:@"Unable to close runtime boot configuration: %s", strerror(errno)];
        return false;
    }
    return true;
}

bool runningMarkerIsRegularFile(const std::string& profilePath) {
    auto marker = profilePath + "RUNNING";
    struct stat info = {};
    return lstat(marker.c_str(), &info) == 0 && S_ISREG(info.st_mode) && !S_ISLNK(info.st_mode);
}

bool removeRunningMarker(const std::string& profilePath) {
    auto marker = profilePath + "RUNNING";
    struct stat info = {};
    if (lstat(marker.c_str(), &info) != 0) return errno == ENOENT;
    if (!S_ISREG(info.st_mode) || S_ISLNK(info.st_mode)) return false;
    return unlink(marker.c_str()) == 0;
}

bool prepareCertificateDirectory(const std::string& profilePath, NSString **error) {
    std::string path = profilePath + "Certificates";
    bool created = false;
    if (mkdir(path.c_str(), 0700) == 0) {
        created = true;
    } else if (errno != EEXIST) {
        if (error) *error = [NSString stringWithFormat:@"Unable to create the runtime certificate directory: %s", strerror(errno)];
        return false;
    }

    struct stat info = {};
    if (lstat(path.c_str(), &info) != 0 || !S_ISDIR(info.st_mode) || S_ISLNK(info.st_mode) || info.st_uid != geteuid()) {
        if (error) *error = @"The runtime certificate path must be a real directory owned by this user";
        return false;
    }
    if (created && fchmodat(AT_FDCWD, path.c_str(), 0700, 0) != 0) {
        if (error) *error = [NSString stringWithFormat:@"Unable to restrict the runtime certificate directory: %s", strerror(errno)];
        return false;
    }
    if ((info.st_mode & (S_IRWXG | S_IRWXO)) != 0) {
        if (error) *error = @"The runtime certificate directory must not be accessible by group or other users";
        return false;
    }
    return true;
}

NSString *coreExceptionDescription() {
    try {
        throw;
    } catch (const dcpp::Exception& exception) {
        return stringFromCore(exception.getError());
    } catch (const std::exception& exception) {
        return [NSString stringWithUTF8String:exception.what()] ?: @"Unknown Core exception";
    } catch (...) {
        return @"Unknown Core exception";
    }
}

void deleteCoreManagers() {
    dcpp::TempShareManager::deleteInstance();
    dcpp::UserCommandManager::deleteInstance();
    dcpp::UploadBundleManager::deleteInstance();
    dcpp::PartialSharingManager::deleteInstance();
    dcpp::TransferInfoManager::deleteInstance();
    dcpp::IgnoreManager::deleteInstance();
    dcpp::RecentManager::deleteInstance();
    dcpp::ActivityManager::deleteInstance();
    dcpp::ViewFileManager::deleteInstance();
    dcpp::UpdateManager::deleteInstance();
    dcpp::GeoManager::deleteInstance();
    dcpp::ConnectivityManager::deleteInstance();
    dcpp::ProtocolCommandManager::deleteInstance();
    dcpp::CryptoManager::deleteInstance();
    dcpp::ThrottleManager::deleteInstance();
    dcpp::DirectoryListingManager::deleteInstance();
    dcpp::FavoriteUserManager::deleteInstance();
    dcpp::QueueManager::deleteInstance();
    dcpp::DownloadManager::deleteInstance();
    dcpp::UploadManager::deleteInstance();
    dcpp::PrivateChatManager::deleteInstance();
    dcpp::ConnectionManager::deleteInstance();
    dcpp::SearchManager::deleteInstance();
    dcpp::FavoriteManager::deleteInstance();
    dcpp::ClientManager::deleteInstance();
    dcpp::ShareManager::deleteInstance();
    dcpp::HashManager::deleteInstance();
    dcpp::LogManager::deleteInstance();
    dcpp::SettingsManager::deleteInstance();
    dcpp::TimerManager::deleteInstance();
    dcpp::ResourceManager::deleteInstance();
}

void disconnectAndDrainSearch() {
    auto search = dcpp::SearchManager::getInstance();
    if (!search) return;

    search->disconnect();
    struct DrainState {
        std::mutex mutex;
        std::condition_variable condition;
        bool complete = false;
    };
    auto state = std::make_shared<DrainState>();
    search->getUdpServer().addTask([state] {
        {
            std::lock_guard<std::mutex> guard(state->mutex);
            state->complete = true;
        }
        state->condition.notify_one();
    });

    std::unique_lock<std::mutex> guard(state->mutex);
    if (!state->condition.wait_for(guard, std::chrono::seconds(10), [&] { return state->complete; })) {
        throw std::runtime_error("Timed out draining Core search UDP callbacks");
    }
}

void stopPartialCore() {
    if (auto timer = dcpp::TimerManager::getInstance()) timer->shutdown();
    disconnectAndDrainSearch();
    if (auto share = dcpp::ShareManager::getInstance()) {
        share->abortRefresh();
    }
    if (auto hash = dcpp::HashManager::getInstance()) hash->shutdown(nullptr);
    if (auto share = dcpp::ShareManager::getInstance()) share->shutdown(nullptr);
    if (auto connections = dcpp::ConnectionManager::getInstance()) connections->shutdown(nullptr);
    if (auto connectivity = dcpp::ConnectivityManager::getInstance()) connectivity->close();
    if (auto geo = dcpp::GeoManager::getInstance()) geo->close();
    dcpp::BufferedSocket::waitShutdown();
    deleteCoreManagers();
}

void releaseProcessOwner(ADCRuntime *runtime) {
    std::lock_guard<std::mutex> guard(ownerMutex);
    if (processOwner == runtime) processOwner = nil;
}

} // namespace

@interface ADCRuntime () {
    NSLock *_stateLock;
    NSLock *_subscriptionsLock;
    dispatch_queue_t _deliveryQueue;
    NSMutableArray<ADCSubscription *> *_subscriptions;
    ADCRuntimeState _state;
    ADCRuntimeConfiguration *_configuration;
    NSError *_lastError;
    BOOL _uncleanShutdownDetected;
    int _profileLockDescriptor;
    std::string _profilePath;
    uint64_t _stageGeneration;
}
@end

@implementation ADCRuntime

- (instancetype)init {
    return [self initWithDeliveryQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithDeliveryQueue:(dispatch_queue_t)deliveryQueue {
    NSParameterAssert(deliveryQueue != nil);
    self = [super init];
    if (self) {
        _stateLock = [[NSLock alloc] init];
        _subscriptionsLock = [[NSLock alloc] init];
        _deliveryQueue = dispatch_queue_create("org.airdcpp.AirDCObjC.runtime-delivery", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_deliveryQueue, deliveryQueue);
        _subscriptions = [NSMutableArray array];
        _state = ADCRuntimeStateStopped;
        _profileLockDescriptor = -1;
    }
    return self;
}

- (ADCRuntimeState)state {
    [_stateLock lock];
    ADCRuntimeState value = _state;
    [_stateLock unlock];
    return value;
}

- (ADCRuntimeConfiguration *)configuration {
    [_stateLock lock];
    ADCRuntimeConfiguration *value = [_configuration copy];
    [_stateLock unlock];
    return value;
}

- (NSError *)lastError {
    [_stateLock lock];
    NSError *value = [_lastError copy];
    [_stateLock unlock];
    return value;
}

- (BOOL)uncleanShutdownDetected {
    [_stateLock lock];
    BOOL value = _uncleanShutdownDetected;
    [_stateLock unlock];
    return value;
}

- (ADCSubscription *)observeEvents:(void (^)(ADCRuntimeEvent *event))observer {
    NSParameterAssert(observer != nil);
    ADCSubscription *subscription = [[ADCSubscription alloc] initWithTargetQueue:_deliveryQueue observer:observer];
    [_subscriptionsLock lock];
    [_subscriptions addObject:subscription];
    [_subscriptionsLock unlock];
    return subscription;
}

- (void)submitCoreOperation:(ADCRuntimeCoreOperation)operation
                 completion:(ADCRuntimeCoreOperationCompletion)completion {
    NSParameterAssert(operation != nil);
    NSParameterAssert(completion != nil);

    NSError *rejection = nil;
    @synchronized (ADCRuntime.class) {
        std::lock_guard<std::mutex> ownerGuard(ownerMutex);
        if (processOwner != self || self.state != ADCRuntimeStateRunning) {
            rejection = runtimeError(ADCErrorRuntimeBusy, @"Core operations are accepted only while this runtime is running");
        } else {
            CoreExecutor *executor = nullptr;
            {
                std::lock_guard<std::mutex> executorGuard(executorMutex);
                executor = processExecutor.get();
            }
            if (!executor) {
                rejection = runtimeError(ADCErrorOperationFailed, @"The Core executor is unavailable");
            } else {
                ADCRuntimeCoreOperation operationCopy = [operation copy];
                ADCRuntimeCoreOperationCompletion completionCopy = [completion copy];
                try {
                    executor->enqueue([self, operationCopy, completionCopy] {
                        NSError *operationError = nil;
                        id result = nil;
                        @try {
                            try {
                                result = operationCopy(&operationError);
                            } catch (...) {
                                operationError = runtimeError(ADCErrorOperationFailed,
                                    [NSString stringWithFormat:@"Core operation failed: %@", coreExceptionDescription()]);
                            }
                        } @catch (NSException *exception) {
                            operationError = runtimeError(ADCErrorOperationFailed,
                                [NSString stringWithFormat:@"Core operation raised an exception: %@", exception.reason ?: exception.name]);
                        }
                        [self deliverClientCallback:^{ completionCopy(result, operationError); }];
                    });
                } catch (...) {
                    rejection = runtimeError(ADCErrorOperationFailed,
                        [NSString stringWithFormat:@"Unable to queue Core operation: %@", coreExceptionDescription()]);
                }
            }
        }
    }

    if (rejection) {
        ADCRuntimeCoreOperationCompletion completionCopy = [completion copy];
        [self deliverClientCallback:^{ completionCopy(nil, rejection); }];
    }
}

- (void)deliverClientCallback:(dispatch_block_t)callback {
    NSParameterAssert(callback != nil);
    dispatch_async(_deliveryQueue, [callback copy]);
}

- (void)startWithConfiguration:(ADCRuntimeConfiguration *)configuration
 resetUnavailableBindAddresses:(BOOL)resetUnavailableBindAddresses
                   completion:(void (^)(NSError * _Nullable error))completion {
    NSParameterAssert(configuration != nil);
    NSParameterAssert(completion != nil);

    CoreExecutor *executor = nullptr;
    try {
        executor = &getCoreExecutor();
    } catch (...) {
        NSError *error = runtimeError(ADCErrorOperationFailed, [NSString stringWithFormat:@"Unable to create the Core executor: %@", coreExceptionDescription()]);
        [self recordError:error];
        [self complete:completion error:error];
        return;
    }

    NSError *admissionError = nil;
    @synchronized (ADCRuntime.class) {
        std::lock_guard<std::mutex> guard(ownerMutex);
        if (processOwner && processOwner != self) {
            admissionError = runtimeError(ADCErrorRuntimeBusy, @"Another runtime currently owns Core in this process");
        } else if (self.state != ADCRuntimeStateStopped) {
            admissionError = runtimeError(ADCErrorRuntimeBusy, @"This runtime is not stopped");
        } else {
            processOwner = self;
            [_stateLock lock];
            _configuration = [configuration copy];
            _lastError = nil;
            _state = ADCRuntimeStateStarting;
            _stageGeneration = 0;
            [_stateLock unlock];
        }
    }
    if (admissionError) {
        [self recordError:admissionError];
        [self complete:completion error:admissionError];
        return;
    }

    [self emitState:ADCRuntimeStateStarting];
    ADCRuntimeConfiguration *configurationCopy = [configuration copy];
    void (^completionCopy)(NSError *) = [completion copy];
    try {
        executor->enqueue([self, configurationCopy, resetUnavailableBindAddresses, completionCopy] {
            [self startOnCore:configurationCopy resetUnavailableBindAddresses:resetUnavailableBindAddresses completion:completionCopy];
        });
    } catch (...) {
        NSError *error = runtimeError(ADCErrorOperationFailed, [NSString stringWithFormat:@"Unable to queue Core startup: %@", coreExceptionDescription()]);
        [self setState:ADCRuntimeStateStopped error:error];
        [self releaseProfileLock];
        releaseProcessOwner(self);
        [self complete:completion error:error];
    }
}

- (void)stopWithCompletion:(void (^)(NSError * _Nullable error))completion {
    NSParameterAssert(completion != nil);
    NSError *admissionError = nil;
    BOOL alreadyStopped = NO;
    @synchronized (ADCRuntime.class) {
        std::lock_guard<std::mutex> guard(ownerMutex);
        ADCRuntimeState currentState = self.state;
        if (currentState == ADCRuntimeStateStopped) {
            alreadyStopped = YES;
        } else if (currentState == ADCRuntimeStateFailed) {
            admissionError = self.lastError ?: runtimeError(ADCErrorCleanupFailed, @"Core cleanup failed; this process owner remains retained until exit");
        } else if (processOwner != self || currentState != ADCRuntimeStateRunning) {
            admissionError = runtimeError(ADCErrorRuntimeBusy, @"Core startup or shutdown is already in progress");
        } else {
            [_stateLock lock];
            _state = ADCRuntimeStateStopping;
            [_stateLock unlock];
        }
    }
    if (alreadyStopped) {
        [self complete:completion error:nil];
        return;
    }
    if (admissionError) {
        [self complete:completion error:admissionError];
        return;
    }

    [self emitState:ADCRuntimeStateStopping];
    void (^completionCopy)(NSError *) = [completion copy];
    try {
        getCoreExecutor().enqueue([self, completionCopy] {
            NSError *error = nil;
            try {
                dcpp::StepFunction step = [self](const std::string& value) {
                    [self emitStep:stringFromCore(value) state:ADCRuntimeStateStopping];
                };
                dcpp::ProgressFunction progress = [self](float value) {
                    [self emitProgress:static_cast<double>(value) state:ADCRuntimeStateStopping];
                };
                dcpp::ShutdownUnloadCallback stopSearchListener = [](dcpp::StepFunction&, dcpp::ProgressFunction&) {
                    disconnectAndDrainSearch();
                };
                dcpp::shutdown(step, progress, stopSearchListener);
                if (!removeRunningMarker(self->_profilePath)) {
                    error = runtimeError(ADCErrorCleanupFailed, @"Core stopped, but its RUNNING marker could not be removed safely");
                }
            } catch (...) {
                error = runtimeError(ADCErrorShutdownFailed, [NSString stringWithFormat:@"Core shutdown failed: %@", coreExceptionDescription()]);
            }

            if (error) {
                [self setState:ADCRuntimeStateFailed error:error];
            } else {
                [self releaseProfileLock];
                [self setState:ADCRuntimeStateStopped error:nil];
                releaseProcessOwner(self);
            }
            [self complete:completionCopy error:error];
        });
    } catch (...) {
        NSError *error = runtimeError(ADCErrorShutdownFailed, [NSString stringWithFormat:@"Unable to queue Core shutdown: %@", coreExceptionDescription()]);
        [self setState:ADCRuntimeStateFailed error:error];
        [self complete:completion error:error];
    }
}

- (void)startOnCore:(ADCRuntimeConfiguration *)configuration
 resetUnavailableBindAddresses:(BOOL)resetUnavailableBindAddresses
         completion:(void (^)(NSError * _Nullable error))completion {
    NSError *error = nil;
    bool coreStartupEntered = false;
    try {
        if (![self prepareProfile:configuration error:&error]) {
            [self failStartup:error completion:completion coreStartupEntered:false];
            return;
        }

        std::string bootstrap = _profilePath + ".airdcpp-runtime/";
        NSString *bootstrapPath = [NSString stringWithUTF8String:bootstrap.c_str()];
        NSString *profilePath = [NSString stringWithUTF8String:_profilePath.c_str()];
        NSString *resourcePath = configuration.resourceDirectoryURL.path;
        NSString *temporaryPath = configuration.temporaryDirectoryURL.path;
        NSString *bootError = nil;
        if (!writeBootConfiguration(bootstrapPath, profilePath, resourcePath, temporaryPath, &bootError)) {
            error = runtimeError(ADCErrorInvalidConfiguration, bootError);
            [self failStartup:error completion:completion coreStartupEntered:false];
            return;
        }

        std::string fakeApplicationPath = bootstrap + "AirDCObjC";
        dcpp::AppUtil::setApp(fakeApplicationPath);
        dcpp::initializeUtil();

        std::string expectedProfile = withTrailingSlash(utf8Path(profilePath));
        std::string expectedResources = withTrailingSlash(utf8Path(resourcePath));
        std::string expectedTemporary = withTrailingSlash(utf8Path(temporaryPath));
        if (!dcpp::AppUtil::usingLocalMode() ||
            dcpp::AppUtil::getPath(dcpp::AppUtil::PATH_USER_CONFIG) != expectedProfile ||
            dcpp::AppUtil::getPath(dcpp::AppUtil::PATH_USER_LOCAL) != expectedProfile ||
            dcpp::AppUtil::getPath(dcpp::AppUtil::PATH_RESOURCES) != expectedResources ||
            dcpp::AppUtil::getPath(dcpp::AppUtil::PATH_TEMP) != expectedTemporary) {
            error = runtimeError(ADCErrorInvalidConfiguration, @"Core did not retain the isolated runtime paths supplied by the host");
            [self failStartup:error completion:completion coreStartupEntered:false];
            return;
        }

        coreStartupEntered = true;
        dcpp::StepFunction step = [self](const std::string& value) {
            [self emitStep:stringFromCore(value) state:ADCRuntimeStateStarting];
        };
        dcpp::ProgressFunction progress = [self](float value) {
            [self emitProgress:static_cast<double>(value) state:ADCRuntimeStateStarting];
        };
        dcpp::MessageFunction message = [self, resetUnavailableBindAddresses](const std::string& value, bool question, bool errorMessage) {
            [self emitMessage:stringFromCore(value) question:question errorMessage:errorMessage state:ADCRuntimeStateStarting];
            return question ? static_cast<bool>(resetUnavailableBindAddresses) : false;
        };
        dcpp::startup(step, message, nullptr, progress);
        [_stateLock lock];
        _uncleanShutdownDetected = dcpp::AppUtil::wasUncleanShutdown;
        [_stateLock unlock];

        // Core's startup constructs TimerManager but does not start its per-second thread.
        // Keeping this call on the dedicated executor preserves its timed-mutex owner thread through shutdown.
        if (auto timer = dcpp::TimerManager::getInstance()) timer->start();
        if (!runningMarkerIsRegularFile(_profilePath)) {
            throw std::runtime_error("Core startup did not create a safe RUNNING marker");
        }
        [self setState:ADCRuntimeStateRunning error:nil];
        [self complete:completion error:nil];
        return;
    } catch (...) {
        error = runtimeError(ADCErrorStartupFailed,
            [NSString stringWithFormat:@"Core startup failed: %@", coreExceptionDescription()]);
        if (coreStartupEntered) {
            [_stateLock lock];
            _uncleanShutdownDetected = dcpp::AppUtil::wasUncleanShutdown;
            [_stateLock unlock];
        }
    }

    [self failStartup:error completion:completion coreStartupEntered:coreStartupEntered];
}

- (BOOL)prepareProfile:(ADCRuntimeConfiguration *)configuration error:(NSError **)errorOut {
    NSString *profilePath = configuration.profileDirectoryURL.path;
    NSString *resourcePath = configuration.resourceDirectoryURL.path;
    NSString *temporaryPath = configuration.temporaryDirectoryURL.path;
    NSString *directoryError = nil;
    if (!prepareDirectory(profilePath, true, true, &directoryError) ||
        !prepareDirectory(resourcePath, false, false, &directoryError) ||
        !prepareDirectory(temporaryPath, true, true, &directoryError)) {
        if (errorOut) *errorOut = runtimeError(ADCErrorInvalidConfiguration, directoryError ?: @"Runtime paths are invalid");
        return NO;
    }

    NSString *profileProbe = [profilePath stringByAppendingPathComponent:@".airdcpp-write-check"];
    int probe = open(profileProbe.fileSystemRepresentation, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (probe < 0) {
        if (errorOut) *errorOut = runtimeError(ADCErrorInvalidConfiguration, [NSString stringWithFormat:@"Profile directory is not safely writable: %s", strerror(errno)]);
        return NO;
    }
    close(probe);
    unlink(profileProbe.fileSystemRepresentation);

    std::string profile;
    try {
        profile = withTrailingSlash(utf8Path(profilePath));
    } catch (...) {
        if (errorOut) *errorOut = runtimeError(ADCErrorInvalidConfiguration, @"A runtime path cannot be represented as UTF-8");
        return NO;
    }
    std::string lockPath = profile + ".airdcpp-runtime.lock";
    int descriptor = open(lockPath.c_str(), O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (descriptor < 0) {
        if (errorOut) *errorOut = runtimeError(ADCErrorOperationFailed, [NSString stringWithFormat:@"Unable to open the profile lock: %s", strerror(errno)]);
        return NO;
    }
    struct stat lockInfo = {};
    if (fstat(descriptor, &lockInfo) != 0 || !S_ISREG(lockInfo.st_mode) || fchmod(descriptor, 0600) != 0) {
        int savedError = errno;
        close(descriptor);
        if (errorOut) *errorOut = runtimeError(ADCErrorOperationFailed, [NSString stringWithFormat:@"Profile lock is not a regular private file: %s", strerror(savedError)]);
        return NO;
    }
    if (flock(descriptor, LOCK_EX | LOCK_NB) != 0) {
        int savedError = errno;
        close(descriptor);
        ADCErrorCode code = savedError == EWOULDBLOCK || savedError == EAGAIN ? ADCErrorProfileInUse : ADCErrorOperationFailed;
        if (errorOut) *errorOut = runtimeError(code, code == ADCErrorProfileInUse ? @"Another process currently owns this profile" : [NSString stringWithFormat:@"Unable to lock the profile: %s", strerror(savedError)]);
        return NO;
    }
    _profileLockDescriptor = descriptor;
    _profilePath = profile;
    if (!prepareCertificateDirectory(_profilePath, &directoryError)) {
        if (errorOut) *errorOut = runtimeError(ADCErrorInvalidConfiguration, directoryError ?: @"The runtime certificate directory is unsafe");
        return NO;
    }
    return YES;
}

- (void)failStartup:(NSError *)startupError
         completion:(void (^)(NSError * _Nullable error))completion
 coreStartupEntered:(bool)coreStartupEntered {
    NSError *failure = startupError;
    BOOL cleanupSucceeded = YES;
    if (coreStartupEntered) {
        try {
            stopPartialCore();
            if (!removeRunningMarker(_profilePath)) {
                cleanupSucceeded = NO;
                failure = runtimeError(ADCErrorCleanupFailed, @"Startup failed and the Core RUNNING marker could not be removed safely", startupError);
            }
        } catch (...) {
            cleanupSucceeded = NO;
            failure = runtimeError(ADCErrorCleanupFailed,
                [NSString stringWithFormat:@"Startup failed and guarded Core cleanup failed: %@", coreExceptionDescription()], startupError);
        }
    }

    if (cleanupSucceeded) {
        [self releaseProfileLock];
        [self setState:ADCRuntimeStateStopped error:startupError];
        releaseProcessOwner(self);
    } else {
        [self setState:ADCRuntimeStateFailed error:failure];
    }
    [self complete:completion error:failure];
}

- (void)recordError:(NSError *)error {
    [_stateLock lock];
    _lastError = [error copy];
    [_stateLock unlock];
}

- (void)setState:(ADCRuntimeState)state error:(NSError *)error {
    [_stateLock lock];
    _state = state;
    _lastError = [error copy];
    [_stateLock unlock];
    [self emitState:state];
}

- (void)emitState:(ADCRuntimeState)state {
    ADCRuntimeEvent *event = [[ADCRuntimeEvent alloc] initWithKind:ADCRuntimeEventStateChanged
                                                           state:state message:nil progress:0
                                                        question:NO errorMessage:NO error:nil];
    [self emitEvent:event generation:0];
}

- (void)emitStep:(NSString *)step state:(ADCRuntimeState)state {
    uint64_t generation;
    [_stateLock lock];
    generation = ++_stageGeneration;
    [_stateLock unlock];
    ADCRuntimeEvent *event = [[ADCRuntimeEvent alloc] initWithKind:ADCRuntimeEventStep
                                                           state:state message:step progress:0
                                                        question:NO errorMessage:NO error:nil];
    [self emitEvent:event generation:generation];
}

- (void)emitProgress:(double)progress state:(ADCRuntimeState)state {
    [_stateLock lock];
    uint64_t generation = _stageGeneration;
    [_stateLock unlock];
    ADCRuntimeEvent *event = [[ADCRuntimeEvent alloc] initWithKind:ADCRuntimeEventProgress
                                                           state:state message:nil progress:progress
                                                        question:NO errorMessage:NO error:nil];
    [self emitEvent:event generation:generation];
}

- (void)emitMessage:(NSString *)message question:(BOOL)question errorMessage:(BOOL)errorMessage state:(ADCRuntimeState)state {
    ADCRuntimeEvent *event = [[ADCRuntimeEvent alloc] initWithKind:ADCRuntimeEventMessage
                                                           state:state message:message progress:0
                                                        question:question errorMessage:errorMessage error:nil];
    [self emitEvent:event generation:0];
}

- (void)emitEvent:(ADCRuntimeEvent *)event generation:(uint64_t)generation {
    [_subscriptionsLock lock];
    NSArray<ADCSubscription *> *subscriptions = [_subscriptions copy];
    NSIndexSet *invalid = [_subscriptions indexesOfObjectsPassingTest:^BOOL(ADCSubscription *subscription, NSUInteger idx, BOOL *stop) {
        return !subscription.valid;
    }];
    if (invalid.count) [_subscriptions removeObjectsAtIndexes:invalid];
    [_subscriptionsLock unlock];
    for (ADCSubscription *subscription in subscriptions) {
        [subscription enqueueEvent:event stageGeneration:generation];
    }
}

- (void)complete:(void (^)(NSError * _Nullable error))completion error:(NSError *)error {
    void (^completionCopy)(NSError *) = [completion copy];
    dispatch_async(_deliveryQueue, ^{ completionCopy(error); });
}

- (void)releaseProfileLock {
    if (_profileLockDescriptor >= 0) {
        flock(_profileLockDescriptor, LOCK_UN);
        close(_profileLockDescriptor);
        _profileLockDescriptor = -1;
    }
}

@end
