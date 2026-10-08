#import <AirDCObjC/ADCRuntime.h>
#import <AirDCObjC/ADCError.h>
#import "ADCRuntime+Private.h"

#include <stdexcept>

namespace {
dispatch_semaphore_t operationEntered;
dispatch_semaphore_t operationRelease;

void writeLine(NSString *line) {
    NSData *data = [[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

bool wait(dispatch_semaphore_t semaphore, NSTimeInterval seconds) {
    return dispatch_semaphore_wait(semaphore,
        dispatch_time(DISPATCH_TIME_NOW, static_cast<int64_t>(seconds * NSEC_PER_SEC))) == 0;
}

void submit(ADCRuntime *runtime, NSInteger kind, void (^completion)(NSString *, NSError *)) {
    [runtime submitCoreOperation:^id(NSError **error) {
        switch (kind) {
            case 1:
                dispatch_semaphore_signal(operationEntered);
                if (!wait(operationRelease, 20)) {
                    if (error) *error = [NSError errorWithDomain:@"RuntimeProbe" code:20
                        userInfo:@{ NSLocalizedDescriptionKey: @"operation barrier timed out" }];
                    return nil;
                }
                return [@"copied-result" copy];
            case 2:
                throw std::runtime_error("deliberate probe operation failure");
            case 3:
                return [@"next-operation-ok" copy];
            default:
                if (error) *error = [NSError errorWithDomain:@"RuntimeProbe" code:21
                    userInfo:@{ NSLocalizedDescriptionKey: @"unknown operation kind" }];
                return nil;
        }
    } completion:^(id result, NSError *error) {
        completion([result isKindOfClass:NSString.class] ? result : nil, error);
    }];
}

int run(NSString *profile, NSString *resources, NSString *temporary) {
    operationEntered = dispatch_semaphore_create(0);
    operationRelease = dispatch_semaphore_create(0);
    dispatch_queue_t delivery = dispatch_queue_create("org.airdcpp.RuntimeProbePrivate.delivery", DISPATCH_QUEUE_SERIAL);
    ADCRuntime *runtime = [[ADCRuntime alloc] initWithDeliveryQueue:delivery];
    ADCRuntimeConfiguration *configuration = [[ADCRuntimeConfiguration alloc]
        initWithProfileDirectoryURL:[NSURL fileURLWithPath:profile isDirectory:YES]
        resourceDirectoryURL:[NSURL fileURLWithPath:resources isDirectory:YES]
        temporaryDirectoryURL:[NSURL fileURLWithPath:temporary isDirectory:YES]
        error:nil];
    if (!configuration) {
        writeLine(@"CONFIGURATION_FAILED");
        return 1;
    }

    dispatch_semaphore_t started = dispatch_semaphore_create(0);
    __block NSError *startError = nil;
    [runtime startWithConfiguration:configuration resetUnavailableBindAddresses:NO completion:^(NSError *error) {
        startError = error;
        dispatch_semaphore_signal(started);
    }];
    if (!wait(started, 60) || startError) {
        writeLine([NSString stringWithFormat:@"START_FAILED %@", startError.localizedDescription ?: @"timeout"]);
        return 1;
    }

    NSLock *resultLock = [[NSLock alloc] init];
    dispatch_semaphore_t preliminaryDone = dispatch_semaphore_create(0);
    NSMutableArray<NSString *> *preliminary = [NSMutableArray array];
    submit(runtime, 2, ^(NSString *result, NSError *error) {
        [resultLock lock];
        [preliminary addObject:error ? @"throw-caught" : @"throw-missing"];
        [resultLock unlock];
        dispatch_semaphore_signal(preliminaryDone);
    });
    submit(runtime, 3, ^(NSString *result, NSError *error) {
        [resultLock lock];
        [preliminary addObject:error ? @"next-error" : [@"next-" stringByAppendingString:result ?: @"nil"]];
        [resultLock unlock];
        dispatch_semaphore_signal(preliminaryDone);
    });
    if (!wait(preliminaryDone, 15) || !wait(preliminaryDone, 15)) {
        writeLine(@"OPERATION_RECOVERY_TIMEOUT");
        return 1;
    }
    [resultLock lock];
    NSArray<NSString *> *preliminarySnapshot = [preliminary copy];
    [resultLock unlock];
    if (![preliminarySnapshot isEqualToArray:@[@"throw-caught", @"next-next-operation-ok"]]) {
        writeLine([NSString stringWithFormat:@"OPERATION_RECOVERY_FAILED %@", preliminarySnapshot]);
        return 1;
    }

    dispatch_semaphore_t callbacksDone = dispatch_semaphore_create(0);
    NSMutableArray<NSString *> *callbackOrder = [NSMutableArray array];
    submit(runtime, 1, ^(NSString *result, NSError *error) {
        [resultLock lock];
        [callbackOrder addObject:error ? @"blocking-error" : [@"blocking-" stringByAppendingString:result ?: @"nil"]];
        [resultLock unlock];
        dispatch_semaphore_signal(callbacksDone);
    });
    if (!wait(operationEntered, 15)) {
        writeLine(@"OPERATION_BARRIER_NOT_ENTERED");
        return 1;
    }

    [runtime stopWithCompletion:^(NSError *error) {
        [resultLock lock];
        [callbackOrder addObject:error ? @"stop-error" : @"stop"];
        [resultLock unlock];
        dispatch_semaphore_signal(callbacksDone);
    }];
    submit(runtime, 3, ^(NSString *result, NSError *error) {
        [resultLock lock];
        [callbackOrder addObject:error.code == ADCErrorRuntimeBusy ? @"late-rejected" : @"late-accepted"];
        [resultLock unlock];
        dispatch_semaphore_signal(callbacksDone);
    });
    dispatch_semaphore_signal(operationRelease);
    if (!wait(callbacksDone, 45) || !wait(callbacksDone, 45) || !wait(callbacksDone, 45)) {
        writeLine(@"OPERATION_DRAIN_TIMEOUT");
        return 1;
    }

    [resultLock lock];
    NSArray<NSString *> *order = [callbackOrder copy];
    [resultLock unlock];
    NSUInteger acceptedIndex = [order indexOfObject:@"blocking-copied-result"];
    NSUInteger stopIndex = [order indexOfObject:@"stop"];
    if (acceptedIndex == NSNotFound || stopIndex == NSNotFound || acceptedIndex >= stopIndex ||
        ![order containsObject:@"late-rejected"]) {
        writeLine([NSString stringWithFormat:@"OPERATION_DRAIN_FAILED %@", order]);
        return 1;
    }
    writeLine([NSString stringWithFormat:@"OPERATION_CONTRACT_OK %@ %@",
        [preliminarySnapshot componentsJoinedByString:@","], [order componentsJoinedByString:@","]]);
    return 0;
}
} // namespace

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 4) {
            writeLine(@"ARGUMENT_ERROR");
            return 2;
        }
        NSString *profile = [NSString stringWithUTF8String:argv[1]];
        NSString *resources = [NSString stringWithUTF8String:argv[2]];
        NSString *temporary = [NSString stringWithUTF8String:argv[3]];
        return run(profile, resources, temporary);
    }
}
