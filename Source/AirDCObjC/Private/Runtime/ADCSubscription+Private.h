#import <AirDCObjC/ADCSubscription.h>
#import <AirDCObjC/ADCRuntimeEvent.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADCSubscription (Private)

- (instancetype)initWithTargetQueue:(dispatch_queue_t)targetQueue
                           observer:(void (^)(ADCRuntimeEvent *event))observer;
- (void)enqueueEvent:(ADCRuntimeEvent *)event stageGeneration:(uint64_t)stageGeneration;

@end

NS_ASSUME_NONNULL_END
