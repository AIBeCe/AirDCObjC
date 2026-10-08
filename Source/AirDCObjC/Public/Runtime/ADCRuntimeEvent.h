#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ADCRuntimeState) {
    ADCRuntimeStateStopped = 0,
    ADCRuntimeStateStarting = 1,
    ADCRuntimeStateRunning = 2,
    ADCRuntimeStateStopping = 3,
    ADCRuntimeStateFailed = 4,
};

typedef NS_ENUM(NSInteger, ADCRuntimeEventKind) {
    ADCRuntimeEventStateChanged = 0,
    ADCRuntimeEventStep = 1,
    ADCRuntimeEventProgress = 2,
    ADCRuntimeEventMessage = 3,
};

@interface ADCRuntimeEvent : NSObject

@property(nonatomic, readonly) ADCRuntimeEventKind kind;
@property(nonatomic, readonly) ADCRuntimeState state;
@property(nonatomic, readonly, copy) NSString *message;
@property(nonatomic, readonly) double progress;
@property(nonatomic, readonly, getter=isDeterminateProgress) BOOL determinateProgress;
@property(nonatomic, readonly) BOOL question;
@property(nonatomic, readonly) BOOL errorMessage;
@property(nonatomic, readonly, nullable, copy) NSError *error;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
