#import "ADCSubscription+Private.h"

@interface ADCSubscription () {
    NSLock *_lock;
    dispatch_queue_t _deliveryQueue;
    void (^_observer)(ADCRuntimeEvent *event);
    BOOL _valid;
    uint64_t _stageGeneration;
    uint64_t _scheduledProgressGeneration;
    BOOL _progressScheduled;
    ADCRuntimeEvent *_pendingProgressEvent;
}
@property(nonatomic, readwrite, getter=isValid) BOOL valid;
@end

@implementation ADCSubscription

- (instancetype)initWithTargetQueue:(dispatch_queue_t)targetQueue
                           observer:(void (^)(ADCRuntimeEvent *event))observer {
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _deliveryQueue = targetQueue;
        _observer = [observer copy];
        _valid = YES;
    }
    return self;
}

- (BOOL)isValid {
    [_lock lock];
    BOOL valid = _valid;
    [_lock unlock];
    return valid;
}

- (void)invalidate {
    [self invalidateWithCompletion:^{}];
}

- (void)invalidateWithCompletion:(void (^)(void))completion {
    NSParameterAssert(completion != nil);
    [_lock lock];
    _valid = NO;
    _pendingProgressEvent = nil;
    _observer = nil;
    [_lock unlock];
    dispatch_async(_deliveryQueue, [completion copy]);
}

- (void)enqueueEvent:(ADCRuntimeEvent *)event stageGeneration:(uint64_t)stageGeneration {
    if (!event) return;

    [_lock lock];
    if (!_valid) {
        [_lock unlock];
        return;
    }

    if (event.kind == ADCRuntimeEventStep) {
        _stageGeneration = stageGeneration;
        dispatch_async(_deliveryQueue, ^{ [self deliverEvent:event]; });
        [_lock unlock];
        return;
    }

    if (event.kind == ADCRuntimeEventProgress) {
        if (stageGeneration != _stageGeneration) {
            [_lock unlock];
            return;
        }
        _pendingProgressEvent = event;
        if (!_progressScheduled || _scheduledProgressGeneration != stageGeneration) {
            _progressScheduled = YES;
            _scheduledProgressGeneration = stageGeneration;
            dispatch_async(_deliveryQueue, ^{ [self deliverPendingProgressForGeneration:stageGeneration]; });
        }
        [_lock unlock];
        return;
    }

    dispatch_async(_deliveryQueue, ^{ [self deliverEvent:event]; });
    [_lock unlock];
}

- (void)deliverPendingProgressForGeneration:(uint64_t)generation {
    [_lock lock];
    ADCRuntimeEvent *event = nil;
    if (_valid && generation == _stageGeneration && generation == _scheduledProgressGeneration) {
        event = _pendingProgressEvent;
    }
    if (generation == _scheduledProgressGeneration) {
        _progressScheduled = NO;
        _pendingProgressEvent = nil;
    }
    void (^observer)(ADCRuntimeEvent *) = event ? [_observer copy] : nil;
    [_lock unlock];
    if (observer) observer(event);
}

- (void)deliverEvent:(ADCRuntimeEvent *)event {
    [_lock lock];
    void (^observer)(ADCRuntimeEvent *) = _valid ? [_observer copy] : nil;
    [_lock unlock];
    if (observer) observer(event);
}

@end
