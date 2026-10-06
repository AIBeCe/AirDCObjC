# Build and distribution design

Status: requirements; no build or package commands are implemented.

## Development

The workspace contains the Objective-C framework target, native Swift example app, and test targets. The framework compiles private `.mm` files as C++20 against verified Core inputs. Public module headers must compile as Objective-C and import from Swift independently of Core headers.

Pin the supported Xcode/SDK/toolchain after the first real build gate. The Core README records a validated host but does not prove this framework has been tested on that host or every macOS version from 14 onward.

## First packaging gate

Build a minimal real bridge and dynamic framework containing Core. Compile/run an Objective-C consumer and a Swift consumer. Inspect Mach-O architecture, platform/minimum OS, dependency load commands, exports and symbol closure. Validate both ordinary use and full Core closure; dead-stripped unused objects cannot conceal missing dependencies.

If archive containment or export policy cannot be achieved safely, stop and propose a correction before changing the approved packaging design.

## SPM publication

Package `AirDCObjC.framework` in `AirDCObjC.xcframework`, initially with one macOS ARM64 variant. Expose a named SPM library product backed by a binary target. Final manifest, artifact location, checksum, tool-version floor, and any auxiliary target must be proposed after the gate establishes exact requirements.

Local development artifacts may use a path-based binary target. Published artifacts require a stable downloadable archive and matching SPM checksum. Source and provenance remain available according to the release policy; binary packaging does not imply closed-source distribution.

The example's package mode and a clean external consumer must resolve the package and run without sibling source/build paths or Homebrew libraries. Verify required system link information is carried correctly through the chosen package, rather than assuming XCFramework metadata supplies it.

## Outputs and resources

`Build` contains disposable build/test evidence. `Dist` contains publishable XCFramework/artifact, metadata/checksums and attribution materials. Keep runtime resources explicit and verify bundle/resource lookup after relocation and app embedding.

A dynamic framework must be embedded and signed correctly by the app. Signing identity, artifact signing, release hosting and distribution automation need their own concrete proposal; do not assume notarization or deployment is authorized.

## Final verification

Check package resolution, public API import, actual runtime scenarios, binary containment, clean-host-path independence, tests, resource configuration, and license/provenance inventory. Define byte reproducibility versus semantic reproducibility based on observed Xcode outputs, without claiming either in advance.

References: [Binary frameworks through SPM](https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages), [XCFramework bundles](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle).
