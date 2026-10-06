# Public API design policy

Status: design requirements; concrete API signatures are not approved yet.

## Boundary

Public headers import Foundation and bridge-owned Objective-C headers only. C++ includes, STL values, raw Core object addresses, and Core compilation definitions stay private. Swift consumers import `AirDCObjC` without enabling C++ interoperability.

Use focused domain services, immutable snapshots where appropriate, stable typed identifiers, and documented commands/events. The proposed `ADC` class prefix is subject to the first API proposal; it is not an implemented contract.

## Semantic preservation

For each operation record its Core method, preconditions, side effects, persistence, errors, completion meaning, and emitted events. Preserve Core sorting, matching, queue priority, share rules, protocol behavior, and cancellation semantics. Conversion cannot silently discard fields or events.

Do not turn a request being accepted into a claim that asynchronous work finished. Do not invent a new algorithm where Core already defines one. Reentrant and event-triggered commands require a validated synchronization contract.

## Type and error checklist for each domain

- Nullability, generics, enums/options, and Swift-imported names are explicit.
- Text encoding and invalid input behavior are verified; binary payloads are not coerced into strings.
- Integer widths, byte counts, timestamps, paths, URLs, and Core identifiers are mapped without truncation.
- Collection snapshots remain valid after Core objects mutate or disappear.
- C++ exceptions are caught at every reachable boundary and mapped to a stable NSError domain/code.
- Asynchronous completion signatures are tested from Swift; Swift async import is verified rather than assumed.
- Cancellation distinguishes requested, completed, and failed cancellation as Core permits.
- Subscriptions have explicit registration, removal, ownership, ordering, and queue rules.
- Settings retain upstream meanings, defaults, units, and persistence behavior.

## Required proposal format

Before implementing a domain, show complete reasonably sized new headers, focused implementation changes, representative imported Swift calls, and failing tests with Given/When/Then assertions. List unresolved semantic choices explicitly.

The coverage ledger links the approved interface and tests back to Core. API evolution must preserve or explicitly version behavior used by Igualada.
