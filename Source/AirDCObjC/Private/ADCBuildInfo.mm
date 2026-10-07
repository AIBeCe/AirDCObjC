#import <AirDCObjC/ADCBuildInfo.h>
#include <ctime>
#include <string>

namespace dcpp {
using string = std::string;
}

#include <airdcpp/core/version.h>

namespace {
NSString *NSStringFromCoreString(const dcpp::string &value) {
    NSString *result = [[NSString alloc] initWithBytes:value.data()
                                                length:value.size()
                                              encoding:NSUTF8StringEncoding];
    return result ?: @"";
}
}

@implementation ADCBuildInfo
+ (NSString *)coreCommit { return NSStringFromCoreString(dcpp::getGitCommit()); }
+ (NSString *)coreVersion { return NSStringFromCoreString(dcpp::getVersionTag()); }
+ (NSInteger)coreBuildNumber { return static_cast<NSInteger>(dcpp::getBuildNumber()); }
+ (NSString *)coreName {
    const char *name = dcpp::getAppName();
    return name ? [NSString stringWithUTF8String:name] : @"";
}
@end
