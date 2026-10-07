#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const ADCErrorDomain;

typedef NS_ERROR_ENUM(ADCErrorDomain, ADCErrorCode) {
    ADCErrorInvalidConfiguration = 1,
    ADCErrorRuntimeBusy = 2,
    ADCErrorNotRunning = 3,
    ADCErrorProfileInUse = 4,
    ADCErrorStartupFailed = 5,
    ADCErrorShutdownFailed = 6,
    ADCErrorCleanupFailed = 7,
    ADCErrorUnsupportedOperation = 8,
    ADCErrorInvalidArgument = 9,
    ADCErrorOperationFailed = 10,
    ADCErrorCancelled = 11,
    ADCErrorInvalidState = 12,
};
