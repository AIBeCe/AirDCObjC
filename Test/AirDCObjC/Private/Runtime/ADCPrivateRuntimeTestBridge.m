#import "ADCPrivateRuntimeTestBridge.h"
#import "ADCRuntimeEvent+Private.h"
#import "ADCSubscription+Private.h"

ADCRuntimeEvent *ADCMakeRuntimeEvent(ADCRuntimeEventKind kind,
                                    ADCRuntimeState state,
                                    NSString *message,
                                    double progress,
                                    BOOL question,
                                    BOOL errorMessage,
                                    NSError *error) {
    return [[ADCRuntimeEvent alloc] initWithKind:kind
                                           state:state
                                         message:message
                                        progress:progress
                                        question:question
                                     errorMessage:errorMessage
                                           error:error];
}

ADCSubscription *ADCMakeRuntimeTestSubscription(dispatch_queue_t targetQueue,
                                                void (^observer)(ADCRuntimeEvent *event)) {
    return [[ADCSubscription alloc] initWithTargetQueue:targetQueue observer:observer];
}

void ADCEnqueueRuntimeTestEvent(ADCSubscription *subscription,
                                ADCRuntimeEvent *event,
                                uint64_t stageGeneration) {
    [subscription enqueueEvent:event stageGeneration:stageGeneration];
}
