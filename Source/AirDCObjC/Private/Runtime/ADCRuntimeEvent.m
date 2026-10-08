#import <math.h>
#import "ADCRuntimeEvent+Private.h"

@interface ADCRuntimeEvent ()
@property(nonatomic, readwrite) ADCRuntimeEventKind kind;
@property(nonatomic, readwrite) ADCRuntimeState state;
@property(nonatomic, readwrite, copy) NSString *message;
@property(nonatomic, readwrite) double progress;
@property(nonatomic, readwrite, getter=isDeterminateProgress) BOOL determinateProgress;
@property(nonatomic, readwrite) BOOL question;
@property(nonatomic, readwrite) BOOL errorMessage;
@property(nonatomic, readwrite, nullable, copy) NSError *error;
@end

@implementation ADCRuntimeEvent

- (instancetype)initWithKind:(ADCRuntimeEventKind)kind
                       state:(ADCRuntimeState)state
                     message:(NSString *)message
                    progress:(double)progress
                    question:(BOOL)question
                 errorMessage:(BOOL)errorMessage
                       error:(NSError *)error {
    self = [super init];
    if (self) {
        _kind = kind;
        _state = state;
        _message = [message copy] ?: @"";
        _progress = kind == ADCRuntimeEventProgress ? progress : 0.0;
        _determinateProgress = kind == ADCRuntimeEventProgress && isfinite(progress) && progress >= 0.0 && progress <= 1.0;
        _question = question;
        _errorMessage = errorMessage;
        _error = [error copy];
    }
    return self;
}

@end
