# AirDCObjC progress

Updated: 2026-10-06.

## Current stage

Phase 0: written design approved by user on 2026-10-06; detailed Phase 0 plan prepared for review. No product code, workspace, package manifest, build scripts, or runnable example exist.

## Established decisions

- Objective-C public framework, private Objective-C++ bridge, contained static Core.
- Dynamic framework/XCFramework via SPM is the approved recommended direction, subject to real linking proof.
- Native macOS ARM64, macOS 14+; Swift example with SwiftUI/AppKit.
- Singular `Source`, `Test`, and `Example`; test paths mirror source paths.
- Swift Testing and Given/When/Then for Swift units; XCTest for required ObjC++/UI coverage.
- TDD where practical and original Core functional authority.
- Full functional parity tracked explicitly, including disabled/optional feature gaps.

## Evidence baseline

Inspected pinned Core source, packaged headers, upstream CMake feature exclusions, lifecycle declarations, and listener dispatch behavior. Generated a source-header inventory with source byte hashes and distribution-header availability. This inventory supports discovery; it does not establish operation-level parity or runtime correctness.

## Open work

1. User review of the [detailed Phase 0 plan](plans/2026-10-06-phase-0-core-contract-inventory.md) and execution mode.
2. Expand the header inventory into complete operations/events/settings/capability rows with exact source locations and availability evidence.
3. Review disabled capability resolution and any separately required Core work.
4. After plan approval, present the Task 1 baseline capture proposal; product implementation remains deferred.
5. Integrate the approved planning feature into `develop`; every execution feature continues to branch from `develop`.

## Repository setup

Public repository https://github.com/AIBeCe/AirDCObjC created using `Momachilles`. Initialized `develop` with a minimal empty bootstrap commit; created `feature/project-documentation` from it. `main` is reserved for a future production release. Approved initial documentation was integrated into `develop`; detailed planning is on `feature/phase-0-plan`. No product code was introduced.

## Limitations and ownership

No tests or builds ran because no implementation exists. No Core files were modified. API signatures, lifecycle failure/restart semantics, event dispatch policy, toolchain floor and release hosting remain decisions at their specified evidence gates.

The documentation does not claim the framework is functional or that all upstream features are already represented by the initial header ledger. Subsequent phases must maintain this file and coverage evidence as durable state.

## Documentation verification

Local-link/code-fence checks and the 263-row header inventory consistency check passed. Independent documentation review found one stale repository-visibility prerequisite; it was corrected to the selected public visibility and completed setup. Final scoped re-review: PASS.
