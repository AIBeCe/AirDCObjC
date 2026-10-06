# AirDCObjC

An Objective-C framework for the original AirDC++ Core on macOS, with a private Objective-C++ bridge and a Swift-friendly public API. Igualada will consume it through Swift Package Manager (SPM).

## Project status

Design and documentation stage. No framework, example app, package manifest, or build scripts exist yet. The documentation describes the approved project direction; implementation starts only after written-design review and approval of the relevant implementation proposal.

## Goals

- Contain the verified AirDCCore-macOS static distribution inside AirDCObjC.
- Preserve the original Core's functionality and semantics through Objective-C APIs usable from Swift.
- Track every capability, operation, setting, and event through an explicit coverage matrix.
- Provide a native macOS example app in Swift using SwiftUI and AppKit where needed.
- Distribute an XCFramework through SPM for Igualada.
- Develop from observable behavior and tests, using TDD where practical.

Initial platform: macOS 14 or later, Apple Silicon ARM64. Intel, iOS, and Mac Catalyst are outside the currently approved platform scope.

## Start here

1. [Design](docs/design.md): authoritative requirements and architectural boundaries.
2. [Core coverage](docs/core-coverage.md): functional scope, inventory, and gaps.
3. [Roadmap](docs/roadmap.md): implementation phases and acceptance gates.
4. [Progress](docs/progress.md): current state and outstanding decisions.

## Documentation

- [API design](docs/api-design.md)
- [Lifecycle and threading](docs/lifecycle-and-threading.md)
- [Core integration](docs/core-integration.md)
- [Example app](docs/example-app.md)
- [Testing and TDD](docs/testing.md)
- [Build and distribution](docs/build-and-distribution.md)
- [Architectural decisions](docs/decisions/README.md)

Build and installation commands will be published when they are implemented and verified. This repository currently supplies neither a binary nor a runnable app.

Original Core: https://github.com/airdcpp/airdcpp-core

Core and dependency notices and corresponding source provenance must accompany future distributions. See [Core integration](docs/core-integration.md).
