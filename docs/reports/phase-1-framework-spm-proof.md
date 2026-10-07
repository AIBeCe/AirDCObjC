# Phase 1 framework and SPM proof

Date: 2026-10-07. **Gate 1 PASS.** Product implementation, final Run/signing additions and documentation/coverage passed independent review. Implementation commit `7cc867b` was integrated into `develop` with merge `180ee8c` and published; this report is the reviewed gate-closure record.

## Verified inputs

The acquisition workflow validated all 16,430 checksum entries, the accepted aggregate digest, 245 installed Core header hashes, pinned metadata and original Core commit before copying into ignored `Dependencies/AirDCCore`. An altered-copy header was rejected. Original Core source and accepted distribution inputs were not modified.

## Behavioral TDD and unit tests

The initial metadata stub failed all four identity assertions and the repeated-read case in the Swift test bundle. Replacing it with original Core version getter calls passed Swift Testing and Objective-C consumer assertions. The example model first failed five identity/title assertions across two tests; the real immutable `BuildInfoSnapshot` then passed. Tests compile the exact model source used by the app.

| Test bundle | Passing tests |
|---|---|
| AirDCObjCPrivateTests (Swift Testing) | 2 |
| AirDCObjCPublicTests (Objective-C XCTest) | 1 |
| AirDCExampleTests (Swift Testing) | 2 |

Shared workspace schemes build test bundles with `xcodebuild build-for-testing`; direct `xcrun xctest` executes them. The host cannot connect to `testmanagerd` through the ordinary `xcodebuild test` action, including one escalated attempt. These results do not claim that action passed.

The expected original identity is commit `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`, version `0.0.0`, build number `0`, name `AirDCCore-macOS`. Metadata calls do not invoke Core startup.

## Full archive containment and public consumers

The framework links the complete 23.1 MiB accepted aggregate with `-force_load`, `DEAD_CODE_STRIPPING=NO`, SDK Iconv/Foundation and an explicit export list. It does not rely on dead stripping unused Core objects to hide missing link dependencies.

Observed Mach-O: ARM64, macOS, minimum OS `14.0`, SDK `26.5`. Loads are SDK `libiconv`, `libobjc`, `libc++`, `libSystem`, Foundation and CoreFoundation. Dynamic exports are exactly `_OBJC_CLASS_$_ADCBuildInfo` and `_OBJC_METACLASS_$_ADCBuildInfo`.

Standalone Objective-C and Swift consumers compiled and ran with the framework search path and public module only. Neither command used Core header/include paths. Full-force-load test bundles passed all five tests.

## XCFramework, SwiftPM and native app

`./scripts/package` archived the Release framework and generated the macOS ARM64 XCFramework. The root SwiftPM package ran four tests (two framework and two example snapshot tests). A relocated package under `Build/relocated-spm/AirDCObjC` contains only the XCFramework, manifest and example sources and public API consumer tests; it contains neither the workspace bridge `Source` nor Core `Dependencies`. Its four tests passed and it built the same complete SwiftUI example source.

The package app embeds the framework in `Contents/Frameworks`, uses an executable-relative rpath, and was ad-hoc signed and launched. Exact executable process checks passed. Strict deep `codesign --verify --deep --strict --verbose=2` checks passed for both `Build/RunDerivedData/Build/Products/Debug/AirDCExample.app` and `Build/RelocatedSPMApp/AirDCExample.app`.

The canonical native launch script built and opened the workspace app. Desktop inspection observed the actual window displaying `AirDCCore-macOS 0.0.0`, the accepted commit, build `0`, and “Phase 1 integration proof — Core runtime lifecycle and networking are not started.” The Codex Run action invokes the same executable script.

## Reproduction and evidence

Validated host: Xcode 26.6 (17F113), Swift 6.3.3, SDK 26.5 and XcodeGen 2.44.1. Root workflows:

```sh
./scripts/acquire-core --dist /path/to/accepted/AirDCCore-macOS/Dist
./scripts/generate-project
./scripts/build
./scripts/test
./scripts/package
./scripts/verify
./script/build_and_run.sh
```

Final `./scripts/verify` exited 0 after review corrections. It verifies copied inputs, five native tests, four root-package tests, four relocated-package tests, full app builds/launches and binary containment. Package test runs repeat the same four Swift test cases in distinct consumption environments; they are not nine additional unique behaviors.

Raw evidence is kept in ignored `Build/Logs`: `objc-framework-tests.log`, `objc-consumer-tests.log`, `example-model-tests.log`, `workspace-package-tests.log`, `relocated-package-tests.log`, and build/package logs. This report preserves normalized findings rather than committing disposable host logs.

## Independent review and coverage

The persistent worker/reviewer pair resolved all three Important findings: launcher process handling now selects the exact executable path; Mach-O verification parses and asserts exact dependency/rpath/install-ID allowlists; and platform/minimum-OS checks assert macOS/14.0 rather than merely printing them. Overall product review and the subsequent Run configuration, cache-ignore and signing review returned **PASS**, with no Critical or Important findings open.

The common-core ledger now has separate verified records for the four implemented metadata getters. The five remaining version getters retain inventoried/unverified status. Current ledgers contain 1,877 records mapping all 11,728 indexed declarations; structural validation reports zero errors. The Phase 0 historical count remains 1,873.

## Limits

This metadata proof does not implement or verify runtime lifecycle, networking or full functional parity. The complete scope and transparent gaps remain in the Phase 0 ledgers; later roadmap gates remain required. Targeting macOS 14 does not establish execution on every supported OS/toolchain combination.

Phase 1 is complete. Work stops before Phase 2; no production release or tag was created.
