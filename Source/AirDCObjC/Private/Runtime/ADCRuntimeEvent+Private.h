#import <AirDCObjC/ADCRuntimeEvent.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADCRuntimeEvent (Private)

- (instancetype)initWithKind:(ADCRuntimeEventKind)kind
                       state:(ADCRuntimeState)state
                     message:(nullable NSString *)message
                    progress:(double)progress
                    question:(BOOL)question
                 errorMessage:(BOOL)errorMessage
                       error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
