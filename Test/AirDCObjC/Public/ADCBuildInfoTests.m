#import <XCTest/XCTest.h>
#import <AirDCObjC/AirDCObjC.h>

@interface ADCBuildInfoTests : XCTestCase
@end

@implementation ADCBuildInfoTests
- (void)testReportsPinnedOriginalCoreIdentity {
    // Given: an Objective-C consumer importing only the public framework umbrella.
    // When: it reads the metadata properties.
    // Then: they match the accepted Core version.inc values.
    XCTAssertEqualObjects(ADCBuildInfo.coreCommit, @"55d51ceb817ec006d4ec844d9e3788e1b0ccc352");
    XCTAssertEqualObjects(ADCBuildInfo.coreVersion, @"0.0.0");
    XCTAssertEqual(ADCBuildInfo.coreBuildNumber, 0);
    XCTAssertEqualObjects(ADCBuildInfo.coreName, @"AirDCCore-macOS");
}
@end
