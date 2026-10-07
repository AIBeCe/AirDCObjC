# AirDCObjC

An Objective-C framework containing the original AirDC++ Core for macOS, with a private Objective-C++ bridge and a Swift-friendly public API. Igualada will consume it through Swift Package Manager.

The framework, XCFramework packaging and native Swift example now provide a tested integration proof. The current public API exposes Core commit, version, build number and application name. Full original Core functionality remains the project goal; lifecycle, networking and other functional APIs follow the [roadmap](docs/roadmap.md) and [coverage ledger](docs/core-coverage.md).

## Build and run

Initial platform: macOS 14 or later, Apple Silicon ARM64. The validated host uses Xcode 26.6, Swift 6.3.3, SDK 26.5 and XcodeGen 2.44.1. This records the tested toolchain rather than compatibility with every newer or older version. Install Xcode with its command-line tools, XcodeGen, Python 3 and ripgrep.

Clone this repository and obtain the accepted distribution from [AirDCCore-macOS](https://github.com/AIBeCe/AirDCCore-macOS). From the repository root:

```sh
./scripts/acquire-core --dist /path/to/AirDCCore-macOS/Dist
./scripts/verify
./script/build_and_run.sh
```

Acquisition checks the pinned archive, headers and metadata before copying inputs. Verification builds and tests the framework and example, packages the XCFramework, and tests a relocated SwiftPM consumer. The example displays real Core build information without starting Core or connecting to the network.

Open `AirDCObjC.xcworkspace` for source development. [Build and distribution](docs/build-and-distribution.md) describes individual commands, generated outputs and test-runner limitations.

## Swift Package Manager

Run `./scripts/package` after acquiring Core to generate `Dist/AirDCObjC.xcframework`. Add this repository as a **local package** and select its `AirDCObjC` library product:

```swift
import AirDCObjC

let commit = ADCBuildInfo.coreCommit
let version = ADCBuildInfo.coreVersion
let buildNumber = ADCBuildInfo.coreBuildNumber
let name = ADCBuildInfo.coreName
```

The manifest uses a local binary target. A fresh clone needs the generated XCFramework before package resolution. Hosted binary releases and remote package consumption are later release work.

## Documentation

- [Design and requirements](docs/design.md)
- [Core coverage and explicit gaps](docs/core-coverage.md)
- [Roadmap](docs/roadmap.md)
- [API design](docs/api-design.md)
- [Lifecycle and threading](docs/lifecycle-and-threading.md)
- [Core integration and provenance](docs/core-integration.md)
- [Native example](docs/example-app.md)
- [Testing and TDD](docs/testing.md)
- [Build and distribution](docs/build-and-distribution.md)
- [Architectural decisions](docs/decisions/README.md)
- [Framework integration evidence](docs/reports/phase-1-framework-spm-proof.md)

Original Core: [airdcpp/airdcpp-core](https://github.com/airdcpp/airdcpp-core). Core and dependency notices and corresponding source provenance must accompany future distributions; the local integration artifact is not a production release.
