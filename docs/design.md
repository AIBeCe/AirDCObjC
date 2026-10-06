# AirDCObjC design

Status: written design awaiting user review. Date: 2026-10-06.

## Purpose and success

AirDCObjC is Project 2 of a three-project system:

1. AirDCCore-macOS reconstructs and verifies the original C++ Core and static dependencies.
2. AirDCObjC contains that distribution and provides an Objective-C API with private Objective-C++ implementation.
3. Igualada is the future native macOS Swift application consuming AirDCObjC through SPM.

The framework must preserve ALL original Core functional capabilities. A minimal bridge is an intermediate gate, never the project's completion criterion. No capability is silently excluded because bridging it is difficult or because the initial macOS archive disables it.

Completion requires accepted capability coverage, verified lifecycle and event behavior, a working Swift example harness, and independent consumers of the released SPM artifact. Packaging success alone is insufficient.

## Approved direction

- Public language: Objective-C; private bridge: Objective-C++.
- Public API is Swift-friendly and contains no C++ types, headers, pointers, templates, or exception contracts.
- Core implementation is contained in AirDCObjC through static linking.
- Recommended framework linkage: dynamic; publication: XCFramework exposed by an SPM product.
- Initial platform: macOS 14+, ARM64, Apple Clang/libc++/C++20 for bridge compilation.
- Workspace contains framework, native Swift example app, and tests.
- Example app uses SwiftUI with AppKit when needed; it is not a Catalyst app.
- `Source` and `Test` are singular and mirror relative paths. `Example` is singular.
- Swift unit tests use Swift Testing and Given/When/Then.
- Tests and acceptance behavior precede implementation, using TDD where practical.
- The original Core is the functional authority; bridge APIs adapt representation, not semantics.
- GitFlow: `develop` integrates development; every feature/point/phase branch starts from `develop`. See [Git workflow](git-workflow.md).

## Dependency baseline

Planning inspected AirDCCore-macOS v1.0.0 and Core commit `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`. The exact distribution inventory is recorded in [Core integration](core-integration.md). Production acquisition will pin identities and verify checksums; it will not depend on a sibling checkout's mutable working state.

The existing distribution uses macOS 14.0, ARM64, C++20, libc++, Release, and `NO_CLIENT_UPDATER`. Iconv is an explicit system link dependency. Core and non-system static dependencies are already aggregated into one archive.

Current functional gaps include optional modules, NAT-PMP, and updater/platform-specific code. [Coverage policy](core-coverage.md) separates upstream capability from binary availability. Closing a gap that requires Core changes needs a separately approved change in Project 1. Existing Core artifacts are not modified by this documentation work.

## Architecture and boundaries

```text
Igualada / AirDCExample (Swift)
                 |
             SPM product
                 |
       AirDCObjC.xcframework
       + Objective-C public module
       + Objective-C++ private adapters
       + statically linked Core archive
                 |
       Core-owned workers, sockets, storage
```

AirDCObjC owns lifecycle coordination, safe value conversion, event subscription lifetimes, and Core exception translation. Core retains protocol, transfer, queue, share, hash, and persistence algorithms. The example app exercises the framework and does not become a second implementation of Core behavior.

Each capability domain has focused adapters and models. A domain implementation plan must define exact Objective-C signatures, imported Swift signatures, listeners, ownership, synchronization, and tests before code changes. Avoid a single façade containing every Core operation and avoid exposing raw singleton managers.

## Proposed repository layout

```text
AirDCObjC.xcworkspace
AirDCObjC.xcodeproj
Package.swift
Source/AirDCObjC/Public/
Source/AirDCObjC/Private/
Test/AirDCObjC/Public/
Test/AirDCObjC/Private/
Example/AirDCExample/Source/
Example/AirDCExample/Test/
Dependencies/AirDCCore/
config/
scripts/
Build/
Dist/
docs/
```

Example: `Source/AirDCObjC/Private/Queue/ADCQueueAdapter.mm` maps to `Test/AirDCObjC/Private/Queue/ADCQueueAdapterTests.mm`; a Swift consumer test for the public queue model follows its public source-relative path with a `.swift` extension. App `Source/Queue/QueueViewModel.swift` maps to app `Test/Queue/QueueViewModelTests.swift`.

Fixtures and scenario tests reside beside the domain they exercise; tags and test targets classify unit/integration/package tests rather than displacing mirrored paths with a top-level taxonomy. Generated outputs and acquired dependencies are ignored when repository tooling is introduced.

The tree is a specification, not scaffold already created.

## Lifecycle, events, and errors

Core currently uses process-wide singleton managers and its own threads. An initial single-runtime constraint is a design recommendation requiring lifecycle-gate validation; independent concurrent Core instances are not promised.

Preserve startup, module initialization/loading, post-load tasks, shutdown, module unloading, and destruction order. A failed startup must have a proven cleanup policy before public retry behavior is promised.

Core listeners are raw pointers invoked synchronously on emitter threads under a listener lock. Bridge callbacks must copy required data and return promptly; Swift/client execution cannot run inside these callbacks. Validate the dispatch and unsubscribe contract per domain, including ordering and shutdown races.

C++ exceptions cannot cross the Objective-C boundary. Error codes, completion behavior, cancellation meaning, and persistence failures require explicit per-operation contracts. Neither async dispatch nor generic success callbacks may conceal Core failures.

## Example and verification

The Swift app is a small functional harness, not Igualada's final UI. Every coverage capability has an accessible scenario or documented invocation, observable state/events, and a verification outcome. Automated tests remain the acceptance authority; manual interaction is complementary.

Use controlled peers and isolated storage for deterministic integration tests. External hubs, routers, GeoIP data, certificate resources, and optional modules require recorded prerequisites and separate live-test evidence.

The app's unit tests use `@Suite`, `@Test`, `#expect`, and `#require` with Given/When/Then sections. Objective-C++ boundary tests and UI automation use XCTest as necessary.

## Acceptance and review

The roadmap defines gates. Final acceptance requires no unclassified upstream capability, no unexplained parity gap, reviewed bridge contracts, passing relevant tests, a working SPM consumer without private headers, and license/provenance materials.

A platform-specific substitute or unsupported behavior is a proposed scope decision, not automatically accepted parity. No disabled feature counts as implemented. No placeholder API or silent no-op counts as coverage.

## Decisions still requiring evidence

1. Whether the accepted archive can be incorporated into a dynamic framework with the intended exports and no external static dependencies.
2. Partial-startup cleanup, repeated runtime use, callback barriers, and shutdown guarantees.
3. Exact per-domain thread safety, API signatures, event ordering, and identifiers.
4. Which upstream-disabled capabilities require Core work versus platform adapters.
5. Acquisition/publishing mechanism and validated developer toolchain minimums.

These are scoped decisions at explicit gates, not permission to guess during implementation. Detailed implementation plans follow written-design approval.
