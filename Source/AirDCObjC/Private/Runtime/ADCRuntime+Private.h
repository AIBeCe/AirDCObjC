#import <AirDCObjC/ADCRuntime.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^ADCRuntimeCoreOperation)(NSError * _Nullable *error);
typedef void (^ADCRuntimeCoreOperationCompletion)(id _Nullable result, NSError * _Nullable error);

@interface ADCRuntime (PrivateCoreOperations)

// Core operations are serialized with startup and shutdown. The operation runs only while
// Running, returns an Objective-C value copied from Core-owned state, and never calls clients.
- (void)submitCoreOperation:(ADCRuntimeCoreOperation)operation
                 completion:(ADCRuntimeCoreOperationCompletion)completion;

// Schedules a callback containing already-copied values on this runtime's serial delivery queue.
- (void)deliverClientCallback:(dispatch_block_t)callback;

@end

NS_ASSUME_NONNULL_END
