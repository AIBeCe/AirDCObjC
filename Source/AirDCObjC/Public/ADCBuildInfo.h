#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Immutable version metadata compiled into the contained AirDC++ Core archive.
@interface ADCBuildInfo : NSObject
@property(class, nonatomic, readonly, copy) NSString *coreCommit;
@property(class, nonatomic, readonly, copy) NSString *coreVersion;
@property(class, nonatomic, readonly) NSInteger coreBuildNumber;
@property(class, nonatomic, readonly, copy) NSString *coreName;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
