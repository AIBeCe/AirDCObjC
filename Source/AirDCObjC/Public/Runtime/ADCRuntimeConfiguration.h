#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Immutable host paths. Construction validates values but never touches the filesystem.
@interface ADCRuntimeConfiguration : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSURL *profileDirectoryURL;
@property(nonatomic, readonly, copy) NSURL *resourceDirectoryURL;
@property(nonatomic, readonly, copy) NSURL *temporaryDirectoryURL;
- (nullable instancetype)initWithProfileDirectoryURL:(NSURL *)profileDirectoryURL
                                resourceDirectoryURL:(NSURL *)resourceDirectoryURL
                               temporaryDirectoryURL:(NSURL *)temporaryDirectoryURL
                                               error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
