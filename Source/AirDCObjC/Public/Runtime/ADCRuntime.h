#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCRuntimeConfiguration.h>
#import <AirDCObjC/ADCRuntimeEvent.h>
#import <AirDCObjC/ADCSubscription.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADCRuntime : NSObject

@property(nonatomic, readonly) ADCRuntimeState state;
@property(nonatomic, readonly, nullable, copy) ADCRuntimeConfiguration *configuration;
@property(nonatomic, readonly, nullable, copy) NSError *lastError;
@property(nonatomic, readonly) BOOL uncleanShutdownDetected;

- (instancetype)initWithDeliveryQueue:(dispatch_queue_t)deliveryQueue NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (void)startWithConfiguration:(ADCRuntimeConfiguration *)configuration
 resetUnavailableBindAddresses:(BOOL)resetUnavailableBindAddresses
                   completion:(void (^)(NSError * _Nullable error))completion;
- (void)stopWithCompletion:(void (^)(NSError * _Nullable error))completion;

- (ADCSubscription *)observeEvents:(void (^)(ADCRuntimeEvent *event))observer;

@end

NS_ASSUME_NONNULL_END
