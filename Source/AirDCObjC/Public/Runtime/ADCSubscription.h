#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADCSubscription : NSObject

@property(nonatomic, readonly, getter=isValid) BOOL valid;

- (void)invalidate;
- (void)invalidateWithCompletion:(void (^)(void))completion;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
