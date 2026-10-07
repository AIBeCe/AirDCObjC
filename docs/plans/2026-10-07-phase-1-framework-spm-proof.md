# Phase 1 — Framework and SPM Proof Implementation Plan

> **For agentic workers:** Use subagent-driven development or executing-plans with persistent worker/reviewer ownership. User approved all Phase 0 and Phase 1 points on 2026-10-07; no routine approval stops. Material conflicts still require evidence and explicit scope handling.

**Goal:** Build a real dynamic Objective-C framework containing the verified macOS Core archive, import and run it from Objective-C and Swift, package it as an XCFramework/SPM library, and run a native Swift example with mirrored Swift Testing tests.

**Architecture:** Objective-C public build-information API with private Objective-C++ calls to original Core version functions. A single framework binary contains force-loaded Core and static dependencies, with only intentional Objective-C symbols exported. The workspace uses source targets; package consumers use the generated binary artifact.

**Tech Stack:** Xcode 26.6 / Swift / Objective-C++ C++20 / Foundation / SwiftUI / AppKit / Swift Testing; installed XcodeGen for deterministic project generation; macOS 14+, ARM64. Xcode 26.6 is the observed host, not an asserted minimum compatible toolchain.

**Spec:** [Approved design](../design.md), [API policy](../api-design.md), [Core integration](../core-integration.md), [testing policy](../testing.md).

## Global Constraints

- Public Objective-C API exposes no C++ types or headers.
- Private Objective-C++ compiles as C++20, ARM64, libc++, macOS 14+.
- Core archive digest and installed-header byte hashes must match the Phase 0 baseline.
- No Core source, dependencies, or library pins change in this phase.
- `Source`/`Test` paths mirror; `Example` is singular.
- Swift units use @Suite/@Test/#expect/#require with Given/When/Then.
- Example is native macOS SwiftUI with AppKit where needed.
- GitFlow feature branch starts from develop after Phase 0 integration.
- Phase 1 provides a real proof, not full functional parity; Phases 2–11 remain required.

## Review Focus

1. A consumer imports public headers without private C++/Core includes: compilation and Swift import must succeed.
2. A successful ordinary link hides missing unused Core dependencies: a force-loaded framework must link the full archive.
3. The framework still depends on sibling build/Homebrew paths or leaks C++ symbols: Mach-O load commands and exports must reject them.
4. Package resolution uses workspace source accidentally: run a relocated package consumer against the XCFramework only.
5. Wrong architecture/platform, modified dependency bytes or stale packaged output: acquisition/package verification must fail closed and regenerate from verified source.

## Proposed files and interfaces

- `Source/AirDCObjC/Public/AirDCObjC.h`: umbrella imports Foundation and ADCBuildInfo only.
- `Source/AirDCObjC/Public/ADCBuildInfo.h`: NSObject class with read-only class properties `coreCommit: NSString *`, `coreVersion: NSString *`, `coreBuildNumber: NSInteger`, `coreName: NSString *`; nonnull Objective-C strings import as Swift String.
- `Source/AirDCObjC/Private/ADCBuildInfo.mm`: calls `dcpp::getGitCommit`, `getVersionTag`, `getBuildNumber`, and `getAppName` from `airdcpp/core/version.h` using private string/time declarations.
- `Test/AirDCObjC/Private/ADCBuildInfoTests.swift`: real Core metadata tests mirroring private ADCBuildInfo.mm; no mocks or runtime startup. Public Objective-C consumer tests mirror the public header in a separate Objective-C test target, so both language suites can retain the exact ADCBuildInfoTests basename without object-output collisions.
- `Test/AirDCObjC/Public/ADCBuildInfoTests.m`: Objective-C import/value contract tests.
- `Example/AirDCExample/Source/BuildInfo/BuildInfoSnapshot.swift`: native app's immutable snapshot from public API.
- `Example/AirDCExample/Test/BuildInfo/BuildInfoSnapshotTests.swift`: Swift Testing, real Core snapshot, Given/When/Then.
- `Example/AirDCExample/Source/AirDCExampleApp.swift`: minimal window showing version/name/commit and scope status.
- `config/core-input.json`: accepted Core source/distribution identity, no arbitrary developer paths as published build requirements.
- `config/project.yml`: shared XcodeGen source of workspace framework/app/tests targets.
- `config/AirDCObjC.exports`: intended Objective-C class/metaclass exports only.
- `scripts/acquire-core`: explicit source Dist input copied only after hash validation; generated `Dependencies/AirDCCore` is not tracked.
- `scripts/build`, `scripts/test`, `scripts/package`, `scripts/verify`: stable root workflows.
- `script/build_and_run.sh`: canonical native-app build and launch entry point.
- `Package.swift`: SPM product/binary target and Swift consumer test target using the mirrored metadata tests.
- `AirDCObjC.xcodeproj`, `AirDCObjC.xcworkspace`: generated and versioned from accepted configuration; shared schemes included.
- `.gitignore`: generated Dependencies/Build/Dist, Xcode personal state and SwiftPM caches.

## Task 1 — Verified Core inputs and test-first public contract

- [x] Copy only verified Core distribution inputs into ignored Dependencies/AirDCCore; validate source digest/metadata/header bytes against Phase 0 baseline. Add a failure check with a deliberately changed copy, never modify accepted original files.
- [x] Write Swift/Objective-C metadata tests first. Given imported framework, When reading Core metadata, Then exact commit `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`, version `0.0.0`, build number 0 and Core name `AirDCCore-macOS`. Verify the original version.inc/getters before pinning these assertions.
- [x] Generate minimal framework/test target configuration with public declarations and deliberately missing/stubbed implementation. Observe an expected missing-behavior test failure, not an unrelated tool error.
- [x] Implement complete public API and private version calls. No runtime initialization in metadata getters.
- [x] Run focused Swift and Objective-C tests, verify repeated/threaded reads remain consistent, and commit the bounded bridge.

## Task 2 — Dynamic containment and real consumers

- [x] Force-load the aggregate Core archive into the framework with `DEAD_CODE_STRIPPING=NO` in all framework configurations, link SDK Iconv/libc++/Foundation and restrict exports to intended Objective-C class/metaclass symbols.
- [x] Compile/run standalone Objective-C and Swift consumers using only the framework public module. Use no Core include paths in consumer commands.
- [x] Inspect binary architecture/platform/minimum OS, exports and load commands. Expected ARM64 macOS, no Homebrew/private archive loads and no public dcpp/third-party C++ API exports.
- [x] Full Core force-load closure succeeds; do not use dead-strip success as a replacement. Preserve normalized link/consumer evidence under a tracked report and raw output under ignored Build.
- [x] Verify all public headers as Objective-C, independently of private implementation include paths.

## Task 3 — Swift example and its unit tests

- [x] Write Given/When/Then @Suite/@Test tests for the app view model's public-framework snapshot. Observe expected missing/incorrect behavior before production implementation.
- [x] Implement the minimal real snapshot model and native SwiftUI window. Avoid adding later-phase lifecycle/network APIs or claiming completed Core feature coverage.
- [x] Build app and run tests through workspace shared schemes. Launch .app through the project run script; inspect actual window contents if desktop automation is available.
- [x] Confirm UI displays real Core values and clearly labels this as the Phase 1 integration proof.

## Task 4 — XCFramework and package-only consumption

- [x] Archive/package the dynamic macOS ARM64 framework as `Dist/AirDCObjC.xcframework`.
- [x] Define SPM library product AirDCObjC backed by `.binaryTarget(name: "AirDCObjC", path: "Dist/AirDCObjC.xcframework")` for the local proof. Remote ZIP hosting/checksum release is a later publication task.
- [x] Run `swift test` for public-interface tests against the binary target.
- [x] Create a temporary relocated package consumer using copied XCFramework and public app/test sources; resolve/import/build/run without workspace targets or Core distribution inputs.
- [x] Build the same native example against the SPM artifact in its package-validation configuration, rather than a different demo program.
- [x] Verify framework embedding, resource-free metadata behavior and ad-hoc signing for the local app proof. Production signing/notarization is outside this phase.

## Task 5 — Gate review and integration

- [x] Run all available framework/example tests plus acquisition/containment/package consumer checks.
- [x] Independent review checks implemented code, tests, Core containment, public module, exact example/SPM path, mirrored test paths and evidence.
- [x] Preserve worker/reviewer identity through all fixes until blocking findings PASS.
- [x] Update README/build guides, coverage rows for only implemented metadata APIs, progress and the Phase 1 report with exact commands/results and limitations.
- [x] Commit small cohesive changes, integrate the passing phase into develop and publish authorized project progress.
- [x] Stop at the end of Phase 1; do not start runtime lifecycle Phase 2 or publish a production release/tag.

## Acceptance scope

Gate 1 proves original Core metadata through a real contained binary, both public languages, workspace app/testing, XCFramework and SPM package-only consumption. It does not prove startup/shutdown, networking, full functional parity, or compatibility with every macOS/SDK/toolchain version. Those remain explicit future gates.

## Concrete initial public API and behavioral tests

The user has authorized all Phase 1 points. These exact units define the initial metadata proof before implementation; they do not expose runtime lifecycle.

```objc
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCBuildInfo : NSObject
@property(class, nonatomic, readonly, copy) NSString *coreCommit;
@property(class, nonatomic, readonly, copy) NSString *coreVersion;
@property(class, nonatomic, readonly) NSInteger coreBuildNumber;
@property(class, nonatomic, readonly, copy) NSString *coreName;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```swift
import Testing
import AirDCObjC

@Suite("Original Core build identity")
struct ADCBuildInfoTests {
    @Test("Reports the pinned original Core identity")
    func reportsCoreIdentity() {
        // Given: the framework containing the accepted Core archive.
        let expectedCommit = "55d51ceb817ec006d4ec844d9e3788e1b0ccc352"
        // When: the consumer reads the public metadata API.
        let commit = ADCBuildInfo.coreCommit
        let version = ADCBuildInfo.coreVersion
        let build = ADCBuildInfo.coreBuildNumber
        let name = ADCBuildInfo.coreName
        // Then: values come from the original Core getters.
        #expect(commit == expectedCommit)
        #expect(version == "0.0.0")
        #expect(build == 0)
        #expect(name == "AirDCCore-macOS")
    }
}
```

Private implementation includes `<string>`, `<ctime>`, a private `dcpp::string` alias and `<airdcpp/core/version.h>`; each getter calls the corresponding original Core function. Tests first run against deliberately incomplete getter behavior and must fail for the expected metadata assertions. The placeholder is replaced by real Core calls before acceptance; none may survive the gate.

The app view model is an immutable Swift value snapshot with Core name/version/commit/build number and a display title. Its Given/When/Then tests assert real framework values; UI composition uses that snapshot and does not initialize Core or contact the network.

## Implementation observations

The example’s immutable value model is named `BuildInfoSnapshot`, with mirrored `BuildInfoSnapshotTests`, to reflect capture of the public metadata rather than mutable UI state. Its behavior and native-app scope are unchanged. The observed host cannot connect to `testmanagerd` through `xcodebuild test`, including one escalated attempt. Shared schemes build the test bundles with `build-for-testing`; direct `xcrun xctest` execution provides the actual Swift Testing/XCTest assertion results. Record this distinction in Gate 1 evidence rather than claiming the ordinary test action succeeded.


## Verified gate evidence

The full verification workflow exited 0 after independent review corrections. Five native tests pass; four SwiftPM tests pass in both root and isolated relocated-package environments. Both native and package-built app bundles pass strict deep signature checks. The actual native window displays the accepted metadata and Phase 1 scope label. The public framework exports only the intended Objective-C class/metaclass and its load commands pass exact SDK allowlists. Product review, including the Run configuration and cache-ignore additions, is PASS. See the [normalized report](../reports/phase-1-framework-spm-proof.md).

Implementation committed on the Phase 1 feature branch as `7cc867b` after independent product review PASS. Documentation/coverage review returned PASS. The implementation was integrated into develop at `180ee8c` and published. This reviewed documentation records Gate 1 PASS and the stop before Phase 2.
