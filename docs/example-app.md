# AirDCExample

## Purpose

A native macOS Swift app that exercises AirDCObjC as Igualada will. Use SwiftUI for the harness and AppKit where native controls or window behavior require it. UIKit and Mac Catalyst are outside this design.

Keep UI simple and focused on Core behavior. The harness is not a production client and must not duplicate queue, protocol, search, or share algorithms.

## Structure

```text
Example/AirDCExample/Source/<domain>/<type>.swift
Example/AirDCExample/Test/<domain>/<type>Tests.swift
```

The mirrored path is preserved for view models, scenario controllers, and other app units. Domain fixtures/scenarios stay near those units. Visual automation uses a separate test target but keeps source-relative domain organization.

## Current integration proof

`Source/BuildInfo/BuildInfoSnapshot.swift` captures the four public `ADCBuildInfo` properties into an immutable Swift value. Its mirrored `Test/BuildInfo/BuildInfoSnapshotTests.swift` uses Swift Testing and Given/When/Then assertions against real framework values. `BuildInfoView.swift` presents the snapshot in a native SwiftUI window.

Run `./script/build_and_run.sh` from the repository root. The inspected window shows `AirDCCore-macOS 0.0.0`, commit `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`, build `0`, and the explicit Phase 1 scope message. This proof does not initialize Core or contact a network.

The workspace source target and relocated SwiftPM executable build the same app source. `./scripts/package` stages, embeds and ad-hoc signs the package-built app, then checks its launch. The root package's `AirDCExampleModel` target compiles the exact snapshot source used by the app; its two tests pass alongside two binary-framework metadata tests. Workspace tests also pass through the direct test-bundle runner described in [build guidance](build-and-distribution.md).

## Functional scenarios

The coverage ledger determines the scenario set: lifecycle/settings; hubs/users/messages; private chat; connectivity; search; sharing/hashing/profiles; file lists; queue/bundles/download/upload; favorites/recents/ignore/commands/viewed files; logs/security resources; optional modules.

Each scenario defines Given prerequisites and isolated state, When user actions/framework commands, and Then expected state, events, errors, and cleanup. Provide visibility into asynchronous progress and failure rather than only a start button.

Every supported capability must have a discoverable exercise. Some low-level operations can share a parameterized scenario instead of requiring their own screen. Unavailable capabilities show their precise reason and coverage status rather than a disabled control without explanation.

## Consumption modes

Development configuration uses the workspace framework target for fast source debugging. Package-validation configuration resolves the actual generated XCFramework through a local SPM package; release acceptance also verifies the published package from a clean external consumer.

Both modes use the same app source and public API. The package mode must not gain private header paths or sibling Core linking. It verifies the integration Igualada will receive.

## Tests

Use Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`) for app units and callable integration scenarios, with Given/When/Then sections. Inject framework-facing test doubles for app orchestration tests; real Core integration tests remain separate and prove the doubles do not replace functional acceptance.

Use controlled peers and temporary profiles. Live hub/router scenarios require explicit prerequisites and recorded results; no success claim is inferred from a manual screen opening.
