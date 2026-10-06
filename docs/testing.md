# Testing and TDD

## Behavioral authority

Original Core behavior at the pinned revision defines expectations. Tests must verify observable semantics, not mirror bridge implementation. Each planned operation links to its Core authority and coverage row.

Before implementation specify inputs, preconditions, state transitions, effects, emitted events, failure conditions, and completion/cancellation meaning. If those are unclear, inspect Core before proposing code.

## Mirrored paths

`Source/A/B/C.m` -> `Test/A/B/CTests.m`.

`Source/A/B/C.mm` -> `Test/A/B/CTests.mm` for private Objective-C++ tests. Public API tests from Swift use the same relative domain/unit path with `Tests.swift`. Different test targets may select different files from this mirrored tree.

`Example/AirDCExample/Source/A/B/C.swift` -> `Example/AirDCExample/Test/A/B/CTests.swift`.

Keep fixtures/scenarios with their owning domain. Use test targets and tags to classify suites, not a language-based replacement for mirrored structure.

## Frameworks and organization

Swift units and callable integration tests use Swift Testing with `@Suite`, `@Test`, `#expect`, and `#require`. Every test follows Given / When / Then, expressed in comments or clearly named helpers. Suites describe behavior; tests state a specific outcome.

Objective-C/Objective-C++ tests use XCTest. UI automation uses XCTest/XCUIAutomation. Swift Testing does not replace those interfaces.

Prefer isolated, parallel-safe tests. Real Core singleton lifecycle tests may require separate processes; suite serialization alone does not protect against other suites/processes sharing directories or ports. Test-only state cannot touch a user's profile.

## TDD cycle

1. Write an approved behavioral test with explicit Given/When/Then assertions.
2. Run it and confirm failure for the intended missing behavior.
3. Implement the smallest correct approved change.
4. Run focused tests and confirm success.
5. Refactor while preserving behavior; rerun affected tests.
6. Complete relevant integration/consumer verification and review.

For tooling or binary probes that cannot meaningfully begin with a unit failure, record the acceptance command and expected result first. Document a specific reason for any departure; do not replace tests with blanket TDD claims.

## Verification layers

- Pure conversion/models: encoding, overflow, invalid input, nullability, immutable snapshots.
- Objective-C boundary: exceptions, NSError translation, ownership, callback capture and cancellation.
- Swift import: expected names/types, async completion behavior, public-only module import.
- Real Core integration: controlled hubs/peers, files, queue, hashes, shares and persisted state.
- Lifecycle/concurrency: partial startup, teardown during work, stale events, unsubscribe and ordering.
- Example units: scenario/view-model behavior through injected public service contracts.
- Binary/SPM consumers: relocation, architecture, deployment, symbols, containment and resource behavior.
- Live prerequisites: routers, external hubs, GeoIP/resources and optional capability evidence.

## Coverage acceptance

A header inventory is not method or functional coverage. Each capability/operation/event/settings row must have exact API, test, and scenario evidence. Passing fakes cannot prove real Core parity; an archive that links cannot prove runtime behavior.

Final gate includes the relevant complete suite, controlled end-to-end scenarios, actual package consumers, all unresolved gaps reviewed, and meaningful limitations recorded. Commands are added to per-phase plans only after corresponding tooling exists.

References: [Swift Testing](https://developer.apple.com/documentation/testing), [Xcode testing](https://developer.apple.com/documentation/xcode/testing).
