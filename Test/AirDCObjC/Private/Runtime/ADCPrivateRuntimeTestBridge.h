#import <AirDCObjC/ADCSubscription.h>
#import <AirDCObjC/ADCRuntimeEvent.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT ADCRuntimeEvent *ADCMakeRuntimeEvent(ADCRuntimeEventKind kind,
                                                      ADCRuntimeState state,
                                                      NSString * _Nullable message,
                                                      double progress,
                                                      BOOL question,
                                                      BOOL errorMessage,
                                                      NSError * _Nullable error);
FOUNDATION_EXPORT ADCSubscription *ADCMakeRuntimeTestSubscription(dispatch_queue_t targetQueue,
                                                                  void (^observer)(ADCRuntimeEvent *event));
FOUNDATION_EXPORT void ADCEnqueueRuntimeTestEvent(ADCSubscription *subscription,
                                                   ADCRuntimeEvent *event,
                                                   uint64_t stageGeneration);

NS_ASSUME_NONNULL_END
