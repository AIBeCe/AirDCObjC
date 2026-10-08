# AirDCObjC roadmap

Status: approved master roadmap. This is not an executable implementation plan.

Detailed plans: [Phase 0 — Core contract inventory](plans/2026-10-06-phase-0-core-contract-inventory.md), [Phase 1 — Framework/SPM proof](plans/2026-10-07-phase-1-framework-spm-proof.md), [Phase 2 — Runtime foundation](plans/2026-10-07-phase-2-runtime-foundation.md), and [Phase 3 — Settings and identity](plans/2026-10-08-phase-3-settings-and-identity.md). Phases 0 and 1 are complete and independently accepted; implementation is integrated on `develop`. The user subsequently authorized full Phases 2 and 3; Phase 2 implementation and verification are active.

Every phase follows analysis -> focused code/test proposal -> explicit approval -> implementation -> relevant verification -> independent review where material -> durable progress update. Work proceeds point by point; the user explicitly authorized all points of Phases 0–3 without routine stops. That authorization does not extend to Phase 4 or later.

Repository setup occurs early on GitFlow: `AIBeCe/AirDCObjC` under `Momachilles`; `develop` is the integration branch and all features/points/phases start there. See [Git workflow](git-workflow.md).

Detailed phase plans under `docs/plans/` will define exact files, interfaces, behavioral tests, commands, dependencies and checkable steps after written-design approval. Later domain plans use the accepted coverage ledger, not guessed signatures.

| Phase | Deliverable | Acceptance gate |
|---|---|---|
| 0 — Specification and inventory | Reviewed design, expanded API/event/settings ledger, dependency contract and open decisions | All 263 source headers classified; installed-vs-source differences explained; every functional domain assigned; exact operations inventory reviewed before its implementation |
| 1 — Framework/SPM proof | Workspace, private Core integration, minimal public bridge, Swift example skeleton and local package consumer | ARM64 dynamic framework contains real Core; ObjC and Swift consumers run; public module contains no C++; local SPM import/link/run succeeds |
| 2 — Runtime foundation | Lifecycle, explicit paths, errors, event/lifetime machinery | Real startup/shutdown; proven failure cleanup; no stale listener access; defined conflicting-call/restart contract; isolated tests |
| 3 — Settings and identity | Settings, persisted state, certificates, logs, favorites and users | Upstream defaults/semantics preserved; state round trips; error/resource behavior tested |
| 4 — Connectivity and hubs | Connectivity, mappings, connections, protocols, authentication, hub users and messaging | Controlled peer/hub exercises and event ordering; disconnect/reconnect/failure tests; platform gaps recorded |
| 5 — Search | Searches, instances, results, filters and cancellation | Upstream matching and result semantics; controlled search; cancellation and stale-result behavior |
| 6 — Sharing and hashing | Shares/profiles, refresh, indexes, temporary shares and hash operations | Deterministic fixtures; original hashes; refresh/cancellation/persistence/event tests |
| 7 — File lists | Retrieval, parsing, browsing, matching and related commands | Controlled complete/partial listings; original matching behavior; invalid data/failure tests |
| 8 — Queues and transfers | Bundles, sources, priorities, downloads, uploads, limits and progress | Real controlled transfer round trip; queue persistence; failures, cancellation, limits and shutdown during work |
| 9 — Remaining functionality | Private chat, recents, ignore, viewed files, user commands, activity and optional modules | Every assigned capability has API, verified semantics, tests and app scenario; required Core changes separately approved |
| 10 — Parity closure | Complete traceability and cross-domain scenarios | No unclassified capability/operation/event/setting; no silently excluded upstream behavior; user-reviewed platform resolutions; real Core evidence |
| 11 — Distribution acceptance | Released-artifact-ready XCFramework/SPM package, consumer docs and attribution | Clean external consumer and example package mode pass; actual integration scenarios; complete tests and review; resources/provenance verified |

## Dependencies and scope

Phases 0–2 establish shared contracts. Domain work follows dependencies discovered from Core: e.g. search/file-list results feed queueing, shares/hashes feed uploads, identities feed chat. The numerical order is a default sequence, not evidence that domains are independent.

Each domain phase adds example scenarios and tests concurrently with its bridge. Do not postpone all app coverage to Phase 10.

Optional modules and NAT-PMP may need a revised Core artifact. Their dependency work is a separate Project 1 proposal, tracked here as blocking parity where applicable. Windows implementation details may require a macOS capability equivalent or explicit user-approved resolution. Do not quietly redefine ALL as only v1.0.0 compiled features.

Final publication/push/tag actions need authorization at the appropriate release step. The authorized Phase 0/1 publication is development progress; no production release is part of these phases.
