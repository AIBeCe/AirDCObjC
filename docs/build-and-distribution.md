# Build and distribution

## Inputs and tools

Use macOS on Apple Silicon with Xcode and its command-line tools, XcodeGen, Python 3 and ripgrep. Phase 1 was verified with Xcode 26.6 (17F113), Swift 6.3.3, SDK 26.5 and XcodeGen 2.44.1. The framework targets macOS 14+, ARM64 and C++20/libc++; execution on macOS 14 and other toolchains is not yet established.

Acquire the accepted AirDCCore-macOS distribution explicitly:

```sh
./scripts/acquire-core --dist /path/to/AirDCCore-macOS/Dist
```

The accepted Core commit is `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`. Acquisition validates the distribution's 16,430 checksum entries and the [baseline](core-baseline.json), including the aggregate archive, 245 installed Core headers and pinned metadata. It copies validated inputs into ignored `Dependencies/AirDCCore/Dist`. A deliberately altered header copy was rejected. Original source and distribution inputs remain unchanged.

## Workspace workflows

From the repository root:

```sh
./scripts/generate-project
./scripts/build
./scripts/test
./script/build_and_run.sh
```

XcodeGen reads `config/project.yml`; the generated project/workspace and shared schemes are versioned. The workspace builds the framework from `Source`, tests from mirrored `Test` paths, and the native Swift example from `Example/AirDCExample/Source`.

`./scripts/test` builds test bundles through shared schemes and runs them with `xcrun xctest`: two Swift framework tests, one Objective-C XCTest and two Swift example tests. The observed host could not connect to `testmanagerd` through `xcodebuild test`, including an escalated attempt. Direct execution ran the actual assertions successfully; ordinary Xcode test-action execution remains a host limitation.

The canonical app script supports `--debug`, `--logs`, `--telemetry` and `--verify` as well as normal build-and-launch. Its process handling selects the exact built app path. The Codex Run action invokes this script.

## Containment and binary package

```sh
./scripts/package
./scripts/verify
```

The dynamic framework force-loads the complete accepted Core aggregate with dead-code stripping disabled. Public headers expose Foundation types only. An explicit export list exposes the Objective-C class and metaclass; Core and dependency C++ APIs stay private. The verifier asserts ARM64/macOS/minimum OS 14.0, the install ID, rpaths, dynamic exports and exact SDK dependency allowlists.

Packaging archives the Release framework and creates `Dist/AirDCObjC.xcframework`, initially with one macOS ARM64 variant. `Package.swift` uses a path-based binary target for the `AirDCObjC` library. Generate this artifact before resolving the package; it is intentionally absent from a fresh clone.

Package verification runs four Swift Testing tests and copies only the XCFramework, manifest and example sources and public API consumer tests into an isolated package under `Build/relocated-spm`. That copy has no workspace bridge `Source` or Core `Dependencies`. It builds the same SwiftUI example, stages and ad-hoc signs an app with the embedded dynamic framework, launches it and verifies the exact executable process. No sibling Core archive or private include path is available to that consumer.

`./scripts/verify` runs acquisition integrity, native tests, package/relocation, source build and canonical launch checks, then inspects Mach-O containment. [Phase 1 evidence](reports/phase-1-framework-spm-proof.md) records results and limits.

## Outputs and release scope

`Build` holds disposable build/test logs and staged validation apps. `Dependencies`, `Dist`, SwiftPM caches and personal Xcode state are ignored. `Dist/AirDCObjC.xcframework` is a local integration artifact; release metadata, attribution and provenance packaging still need their release gate.

Hosted ZIP/checksum publication, production signing/notarization, clean-machine execution, all runtime resources and full functional parity remain future work. Embedded OpenSSL configuration/provider defaults are distinct from Mach-O dylib dependencies; metadata-only execution does not validate TLS resource configuration. Byte reproducibility of Xcode outputs is not claimed.
