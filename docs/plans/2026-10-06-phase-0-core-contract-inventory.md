# Phase 0 — Core Contract Inventory Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task by task. Preserve existing worker/reviewer ownership through each review/fix lifecycle as required by AGENTS.md. Steps use checkbox tracking.

**Goal:** Establish a complete, evidence-backed inventory of original Core functionality and the integration constraints needed to propose the Objective-C framework accurately.

**Architecture:** Audit the pinned original Core and the accepted macOS distribution without modifying either. Structured coverage records connect source semantics and binary availability to future API proposals, tests, and example scenarios; the bridge remains unimplemented during this phase.

**Tech Stack:** Markdown, JSON, CSV, Python 3 for reproducible evidence checks, Git/RTK, existing Core source and distribution metadata. No framework/tooling dependency installation.

**Spec:** [Approved design](../design.md), supported by [coverage policy](../core-coverage.md), [integration contract](../core-integration.md), [testing policy](../testing.md), and [roadmap](../roadmap.md).

## Global Constraints

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
- GitFlow: `develop` integrates development; every feature/point/phase branch starts from `develop`.
- ALL original Core functional capabilities remain tracked; disabled capabilities are gaps rather than silent exclusions.
- No product code, new build scripts, dependency changes, Core source changes, or production release in Phase 0.
- Concrete proposals remain documented. User authorization on 2026-10-07 covers every Phase 0 and Phase 1 point; no routine approval stops are required. Material conflicts still require explicit handling.

## Review Focus

1. A header declaration exists but its implementation is absent from the macOS archive: record availability separately from discoverability.
2. Inline methods, settings defaults, event overloads, module hooks or source-only operations escape a header-only inventory: trace declarations, definitions, registrations and call sites.
3. Callback payloads reference transient Core objects or are emitted under locks: record concrete lifetime/threading evidence before API design.
4. Windows/optional code is classified as internal to conceal a missing capability: require a functional rationale and explicit gap resolution.
5. Local source/archive/configuration changes invalidate coverage evidence: bind records to source hashes and actual distribution bytes, and fail verification on drift.

The steps below exercise each focus through audit evidence and integrity checks. These are documentation tasks, so artificial product unit tests are not required. For later code, the owning phase plan must supply real Given/When/Then behavioral tests and a red/green cycle.

## Execution boundaries

The initial planning branch is `feature/phase-0-plan`, created from `develop`. After approval, Phase 0 execution uses a feature branch based on the latest approved `develop` state. Continuing an existing unmerged feature retains its ownership and branch where appropriate.

Use the available local Core checkout as read-only input only after verifying the pin. Initial paths are `/Users/davidalarcon/Development/Projects/AirDCCore-macOS/Source/airdcpp-core` and its sibling project `Dist`. These are audit input locations, not production dependency paths.

Prefer bounded discovery delegation for large API families and an independent reviewer for the completed ledger. Root owns scope, semantics, proposed APIs, gaps, and approval decisions. Return concise source anchors and conclusions; avoid raw transcripts.

## Planned durable files

| File | Responsibility |
|---|---|
| `docs/core-baseline.json` | Verified original source identity, actual archive/header hashes, selected metadata identities and feature-policy evidence |
| `docs/core-header-inventory.csv` | One classified record per pinned Core header; retain byte and installed-header observations |
| `docs/coverage/ledger-format.md` | Exact coverage record schema and controlled vocabulary |
| `docs/coverage/domains/*.json` | Per-domain capabilities, operations, events, settings and internal classifications |
| `docs/coverage/source-accounting.json` | Relevant C++ source/registration sites and the records that account for them |
| `docs/coverage/gaps.md` | Functional gaps, evidence, proposed resolutions and required approvals |
| `docs/core-coverage.md` | Human-readable index linking every domain record and gap |
| `docs/core-integration.md` | Validated integration and resource constraints |
| `docs/lifecycle-and-threading.md` | Validated lifecycle/listener/thread evidence and unresolved contracts |
| `docs/reports/phase-0-core-contract-inventory.md` | Reviewed audit result, limits and gate outcome |
| `docs/progress.md` | Completion state and remaining work |

### Task 1: Bind the audit to actual source and distribution inputs

**Files:** Create `docs/core-baseline.json`; modify `docs/core-integration.md` only where evidence changes an observation.

**Consumes:** Approved Core pin, existing inventory, original Git checkout, distribution manifest and link interface.

**Produces:** Schema-1 baseline with `upstream_url`, `upstream_commit`, `source_tree_clean`, `archive_sha256`, `core_headers`, `metadata_sha256`, `platform`, and `feature_evidence`. `core_headers` maps installed relative paths to byte hashes; `metadata_sha256` maps inspected metadata paths to byte hashes. `feature_evidence` is an array of `{name, value, source, evidence_kind}` records; distinguish observed build policy from upstream default.

- [x] **Step 1: Present the baseline capture proposal.** Show the exact JSON structure and the inspection commands, including the scope of source/header hashing, without dumping large manifests. Approval applies only to recording evidence.
- [x] **Step 2: Verify source identity and cleanliness.** Run `rtk git -C /Users/davidalarcon/Development/Projects/AirDCCore-macOS/Source/airdcpp-core rev-parse HEAD` and `rtk git -C /Users/davidalarcon/Development/Projects/AirDCCore-macOS/Source/airdcpp-core status --porcelain`. Expected: exact pinned commit and no tracked source changes. Inspect relevant ignored/generated files if they affect the source used for the audit.
- [x] **Step 3: Independently hash actual artifact/header bytes.** Read `Dist/lib/libairdcpp.a` and installed Core headers with Python `hashlib.sha256`. Compare the actual archive digest with the manifest claim `3e6b1d2be3e7d29e80b19a38633df7d3c9229730f25f1a50abf4f64b588462bb`. A mismatch stops baseline acceptance; explain the evidence rather than updating the pin silently.
- [x] **Step 4: Extract bounded metadata.** Read selected JSON fields for platform, definitions, source pin and link closure; record metadata file hashes. Avoid printing entire aggregate manifests. Cross-check NAT-PMP/TBB/module/updater availability against actual source exclusions and distribution evidence. A CMake default alone is insufficient evidence of the built configuration.
- [x] **Step 5: Write the approved baseline and verify it.** Assert exact commit, actual digest equality, `arm64`, `14.0`, C++20, libc++, and explicit Iconv. Expected: all assertions pass, or a recorded blocker prevents acceptance.
- [x] **Step 6: Commit the cohesive baseline evidence.** Use `rtk git add docs/core-baseline.json docs/core-integration.md` and `rtk git commit -m "docs: bind Core audit to verified inputs"` after relevant verification.

### Task 2: Classify the complete structural surface

**Files:** Modify `docs/core-header-inventory.csv`; create `docs/coverage/source-accounting.json` and `docs/coverage/ledger-format.md`.

**Consumes:** Verified Task 1 baseline and existing 263-row inventory.

**Produces:** Complete structural classifications with stable header references and a schema for Task 3. Header inventory adds `classification_rationale`, `capability_ids` and `source_evidence` to its existing columns. Source accounting has schema version 1 and `files`: records `{path, sha256, kind, domain_ids, classification_rationale}` covering original `.cpp`/`.c` units and behavior-bearing registration/generated-input sites discovered in this audit.

- [x] **Step 1: Propose the inventory-column and ledger-schema changes.** Present the focused CSV header change and one full JSON record example. Retain existing source hashes and installed-byte evidence; do not overwrite historical input identities.
- [x] **Step 2: Inspect every header family.** Begin with the source anchors in `docs/core-coverage.md`; classify each header as public functionality, event, setting, internal helper, dependency detail or platform-specific implementation. Multiple roles require linked records rather than loss of behavior. Provide evidence and rationale; naming alone is insufficient.
- [x] **Step 3: Account for non-header behavior.** Enumerate pinned `.cpp`/`.c` units and settings/listener/module registrations. Link their behavior to domain IDs or justify an internal/dependency classification. Inspect enough call flow to avoid omitting externally meaningful source-only operations. The file ledger is discovery accounting, not proof of exhaustive methods by itself.
- [x] **Step 4: Explain all source/distribution differences.** The initial snapshot has 18 absent headers: 17 optional-module headers and ZipFile.h. Verify this observation against Task 1 and record each feature gap or implementation distinction; header presence never implies binary availability.
- [x] **Step 5: Verify structural coverage.** Assert no duplicate/missing pinned header paths, source hashes still match, no unclassified rows, every functionality row links capability IDs, and every source-accounting row has a rationale/domain reference. Expected: no unexplained structural gaps. Do not hardcode 263 for future pins; this pinned baseline must equal 263.
- [x] **Step 6: Commit the classified structural inventory.** `rtk git add docs/core-header-inventory.csv docs/coverage/source-accounting.json docs/coverage/ledger-format.md`; `rtk git commit -m "docs: classify Core source and header surface"`.

### Task 3: Enumerate functional contracts domain by domain

**Files:** Create `docs/coverage/domains/<domain-id>.json`; update `docs/core-coverage.md`, `docs/lifecycle-and-threading.md` and relevant structural references.

**Consumes:** Task 2 schema, structural classification and Task 1 source/binary baseline.

**Produces:** Domain records consumed by later exact Objective-C API proposals. Each JSON file has `{schema_version: 1, domain_id, upstream_commit, records}`. Each record requires:

```json
{
  "id": "lifecycle.startup",
  "kind": "operation",
  "upstream_symbols": ["dcpp::startup"],
  "source_refs": [{"path": "airdcpp/DCPlusPlus.h", "start_line": 1, "end_line": 1}],
  "availability": {
    "source": true,
    "installed_declaration": true,
    "compiled": "unverified",
    "evidence_refs": []
  },
  "behavior": {
    "inputs": [],
    "preconditions": [],
    "defaults": [],
    "effects": [],
    "events": [],
    "errors": [],
    "completion": "source inspection required",
    "cancellation": "source inspection required",
    "persistence": [],
    "resources": []
  },
  "ownership_evidence": [],
  "threading_evidence": [],
  "proposed_bridge_requirement": "Preserve the inspected startup contract without exposing C++ callback types.",
  "acceptance_scenarios": [],
  "bridge_api": null,
  "implementation_tests": [],
  "example_scenario": null,
  "status": "inventoried",
  "gap_ids": []
}
```

This is a schema example, not accepted evidence: line numbers and behavior must be replaced by verified content before accepting a record. `bridge_api` and implementation tests remain empty because implementation has not occurred. `proposed_bridge_requirement` is a functional requirement, not an approved signature. Values `source inspection required` cannot survive the Phase 0 gate.

Controlled record kinds: `capability`, `operation`, `event`, `setting`, `internal`, `platform-implementation`. `compiled` values: `verified-present`, `verified-absent`, `unverified`; unverified availability must link an explicit unresolved evidence gap. Internal classifications require rationale in the behavior/evidence fields and cannot conceal a public capability.

- [x] **Step 1: Present the first domain-record proposal.** Show one fully inspected capability/operation/event/setting record where those kinds apply, with exact source locations and concrete Given/When/Then acceptance scenarios. Approval is for the record content, not product code.
- [x] **Step 2: Audit lifecycle and shared foundations first.** Trace startup/load/post-load/shutdown, exception paths, listener locking and object destruction. Enumerate every callback/hook and externally meaningful option. Record partial-startup/restart uncertainty as an explicit gap instead of promising cleanup semantics.
- [x] **Step 3: Repeat the reviewed audit sequence for each domain below, one implementation point at a time.** Each point reads relevant declarations/definitions/call sites, records the concrete proposal, applies the existing phase authorization, writes them, verifies references, and commits a cohesive unit. Do not batch domains without user authorization.

Domain audit checklist:

- [x] `lifecycle` and common externally meaningful facilities.
- [x] `settings` with every setting/default/unit/persistence behavior.
- [x] `logs`, crypto/TLS/certificates and GeoIP.
- [x] Connections, throttling, connectivity and mapping.
- [x] Hub clients/users/identities/messages and protocol commands.
- [x] Search instances/results/filtering/cancellation.
- [x] Private chat.
- [x] Queues/items/bundles/sources/priorities/persistence.
- [x] Downloads, uploads/slots/limits and transfer information.
- [x] File lists and directory browsing/matching.
- [x] Hashes/trees/database and sharing/profiles/temporary shares.
- [x] Favorites/favorite users/reserved slots.
- [x] Ignore rules, recents, viewed files, user commands and activity.
- [x] AutoSearch/ADL/direct/directory-listing search modules.
- [x] Finished history, highlighting, hub lists, preview and RSS modules.
- [x] Update-related functionality and platform facilities, including ZIP/Windows mapping capability distinctions.
- [x] Every remaining structural row not accounted for above.

- [x] **Step 4: Verify each domain before its commit.** Assert unique IDs; valid pinned source lines; all referenced header/source rows exist; documented inputs/defaults/effects/errors/events; each functionality record has acceptance scenarios with Given/When/Then; internal classifications have rationale. Inspect overloads and event payload fields explicitly. Expected: no guessed source references or vague behavioral placeholders.
- [x] **Step 5: Commit each approved domain unit.** Use a meaningful domain-specific documentation commit. Preserve the same worker/reviewer pair for a non-trivial domain's routine review/fix loop until PASS.

### Task 4: Resolve binary availability, runtime prerequisites and parity gaps

**Files:** Create `docs/coverage/gaps.md`; update domain availability evidence, `docs/core-integration.md` and `docs/lifecycle-and-threading.md`.

**Consumes:** Complete Task 3 records and Task 1 distribution evidence.

**Produces:** Stable gap IDs, upstream semantics, observed availability, affected capabilities, proposed resolution, required project/approval, and status. A gap record separates verified absence from missing evidence.

- [x] **Step 1: Present the availability/resource audit proposal.** Limit actions to read-only configuration, selected manifest fields, symbols and source tracing. Do not run startup, network calls, new builds or destructive cleanup without a separate bounded proposal.
- [x] **Step 2: Bind compiled availability.** Inspect actual symbols and build policy as necessary, recognizing inline/header-only operations need different evidence. A missing standalone symbol is not proof an inline operation is unavailable. Record optional module/NAT-PMP/updater/platform exclusions explicitly.
- [x] **Step 3: Trace resource prerequisites.** Account for profiles/settings/storage, localization, certificates/trust, OpenSSL configuration/providers, GeoIP data, logs, module resources and preview/application integration. Record host-supplied versus framework-supplied resources with source evidence. Do not silently reuse a user's profile or invent bundled resources.
- [x] **Step 4: Present each functional-gap resolution.** Propose separate Core work, platform-equivalent capability, or an explicitly scoped decision. Only user-approved resolutions can change the scope; unavailable features remain gaps until actually verified. TBB is classified as execution strategy rather than automatically a missing user feature.
- [x] **Step 5: Verify gap linkage.** Every verified-absent or unverified functional availability record must link a gap; every gap links affected IDs and its exact evidence. Expected: no silent downgrade from ALL functionality to only compiled v1.0.0 functionality.
- [x] **Step 6: Commit the audited integration/gap documentation.** Preserve unresolved technical decisions as explicit blockers for their owning future phase, rather than fabricating their resolution.

### Task 5: Independent gate review and Phase 1 planning handoff

**Files:** Create `docs/reports/phase-0-core-contract-inventory.md`; update `docs/core-coverage.md` and `docs/progress.md`.

**Consumes:** All approved Phase 0 artifacts.

**Produces:** Explicit Phase 0 PASS or blocker report, evidence references, reviewed limitations and requirements for the Phase 1 implementation plan.

- [x] **Step 1: Verify input freshness.** Recompute actual source/header/archive identities and compare with the accepted baseline. Fail on unexplained drift. Do not refresh the baseline to make stale records appear current.
- [x] **Step 2: Check all ledger references and coverage obligations.** No unclassified header/source behavior, duplicate IDs, invalid source lines, orphan capabilities, unexplained missing settings/events, or unsupported completion claims. Every externally meaningful record has specific future acceptance behavior and a domain owner.
- [x] **Step 3: Obtain independent review.** Reviewer samples source and follows omitted/optional/platform cases, callbacks, overloads and settings registrations, then checks complete accounting. Keep the same reviewer through fixes; Critical/Important findings require PASS before gate acceptance.
- [x] **Step 4: Report the actual gate result.** Phase 0 PASS means an accepted inventory and transparent gaps, not implemented framework parity. Source-only/unavailable capabilities may remain blocked for later separately approved work, but their existence and affected contracts must be fully accounted for.
- [x] **Step 5: Commit the reviewed report and progress update.** Integrate into `develop` according to GitFlow only when review and checks pass. Do not create a production release or tag.
- [x] **Step 6: Prepare the Phase 1 plan for user review.** Define exact workspace/target/source/test paths, public minimal API and imported Swift signatures, Core input acquisition/checksum contract, build settings, package manifest, Given/When/Then tests and real consumer commands. Use Phase 0 evidence. The user has already approved the complete Phase 1 scope; begin its implementation after Gate 0 review and GitFlow integration, without another routine approval stop.

## Plan acceptance

This plan implements roadmap Phase 0 only. Phases 1–11 remain required by the approved roadmap; their detailed plans are authored when prerequisite contracts are known. Nothing here reduces the full project scope.

Execution is authorized for all points of Phases 0 and 1. Bounded delegated discovery and persistent review ownership are in use; Root retains semantic and architectural authority. Task 1 baseline evidence was independently verified and committed as 77694fc. Tasks 1–4 have passed their checks and scoped independent reviews. Task 5 final documentation review returned PASS after the settings scope closed. Accepted report committed as bf4ddc2 and integrated/published on develop as f2896c7. Phase 0 is complete; Phase 1 executes on feature/framework-spm-proof. No runtime parity is implied.
