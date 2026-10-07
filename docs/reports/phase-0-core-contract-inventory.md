# Phase 0 Core contract inventory

Date: 2026-10-07. **Gate 0 PASS.** This accepts the inventory and transparent gaps; it does not establish functional parity or runtime correctness.

## Verified authority

The original Core revision is `55d51ceb817ec006d4ec844d9e3788e1b0ccc352`. Its tracked checkout is clean. The accepted macOS aggregate archive digest is `3e6b1d2be3e7d29e80b19a38633df7d3c9229730f25f1a50abf4f64b588462bb`; actual bytes agree with the recorded distribution metadata. All 245 installed original Core headers match the pinned source and [baseline](../core-baseline.json). The distribution checksum index binds 16,430 input files.

The archive was built in Project 1's private patched stage. The tracked original source remains the functional authority; [integration evidence](../core-integration.md) records the accepted patch identity and generated-input distinction. Ignored checkout `version.inc` has an empty tag/count 1; accepted installed and binary inputs have tag `0.0.0`/count 0. Framework compilation uses the accepted distribution, not checkout-generated files.

## Structural result

| Evidence | Reviewed result |
|---|---|
| Original headers | 263 classified; 245 installed, 18 source-only |
| Implementation files | 146 tracked translation units and one separately recorded observed generated `StringDefs.cpp` |
| Declaration/source index | 11,728 unique records, including 145 complete conditional source regions |
| Special members | Compiler-backed constructors, destructors and conversions; dependency-blocked ZIP members remain explicitly lexical |
| Generated inputs | Current bytes, pinned generators/inputs, build rules and accepted version authority recorded separately |
| Domains | Dedicated ownership consistent across headers, declarations and implementation accounting |

Independent structural review corrected domain ownership, generated provenance and missing inactive source branches, then returned PASS. Exact sets, hashes, index IDs, ranges and text were checked. The [ledger format](../coverage/ledger-format.md) states host-parser and inactive-branch limitations. A conditional source interval accounts for branch text without pretending it is a compiler-validated declaration for another platform.

## Selected archive availability evidence

A fresh `/usr/bin/nm -gUj` scan of the accepted aggregate, excluding archive member headings, found one defined `getGitCommit` symbol, 56 symbols containing `UpdateManager`, and 33 containing `Mapper_MiniUPnPc`. No defined global symbol matched `UpdateDownloader`, `UpdaterCreator`, `AutoSearchManager`, `RSSManager`, `ADLSearchManager`, `Mapper_NATPMP`, `Mapper_WinUPnP`, or `ZipFile`. These observations corroborate the recorded build policy for the sampled implementations; they are not per-declaration runtime proofs, and absence of a standalone symbol cannot establish absence of an inline/header-only operation. The corresponding source capabilities remain explicitly required.

## Semantic result and remaining work

[Domain ledgers](../core-coverage.md#structured-domain-ledgers) connect operation families, model state, events and settings to source anchors and future Given/When/Then scenarios. Runtime and individual binary availability remain separate evidence obligations. Explicit [gaps](../coverage/gaps.md) preserve disabled modules, NAT-PMP, updater/ZIP/platform distinctions, resource policy, partial-startup/restart and event/concurrency contracts.

| Reviewed contract group | Evidence commit | Material corrections accepted |
|---|---|---|
| Files, queues, transfers, sharing, modules and platform facilities | `a9ecbe7` | Complete structural ownership, malformed queue cases, module behavior, share search/list/cache semantics and platform distinctions |
| Shared foundations and utilities | `d0a2bda`, `7e97740` | Filesystem error behavior, text conversion, matching, paths and all nine public version getter contracts |
| Logs, GeoIP, ignore, recents, viewed files, user commands and activity | `5f53b71` | Append behavior and exact log-tail tokenization |
| Lifecycle and resources | `76f8d33` | Startup/shutdown callbacks, ownership and unchecked directory-creation attempts |
| Crypto, connectivity, protocol and favorites | `4f16a21` | Concrete events and mapper scenarios |
| Hubs | `a9be850` | Inline operations, transformations and event payload scenarios |
| Connections and throttling | `3d926b1` | Retry state, silent setup-failure cleanup and observer lifetime |
| Private chat | `4eeb6cc` | Callbacks under manager locks, event order and initial online state |
| Search | `5cba12f` | Case handling, lowercase preconditions and nickname parsing |
| Settings | `e3f2548` | Typed storage/defaults/XML persistence, direct and indirect consumers, exact units, active-source references and concrete fixtures |

All 31 domain scopes have passed review. The final ledger has 1,873 semantic/structural family records accounting for all 11,728 indexed declarations; mapping/source-range checks report zero errors. Settings contains 628 key records, with shared typed storage/default/load-save contracts, concrete source-known consumers and explicit host/future-runtime questions. Remaining setting gaps do not substitute for readable Core behavior. A separate comment-aware direct-use check reports no unexplained references. Given/When/Then scenarios describe future characterization requirements, with stable operation links where workflows are shared; they are not passing runtime tests.

Fresh source/header/archive verification matches the accepted pin, all 263 source headers, 245 installed headers, five metadata identities and the aggregate archive digest. Tracked original source is clean. Earlier complete distribution validation covered the 16,430 checksum entries; Phase 1 revalidates all copied inputs before linking.

Independent review is distributed across persistent domain owners and reviewers. The shared-foundation author did not review its own baseline contracts; Root independently checked them, and the subsequent Root-authored public version correction was independently reviewed by the file-domain owner. Final report review returned PASS for this evidence matrix and the handoff, without treating source inventory as runtime or compiled parity.

## Phase 1 handoff

The [authorized Phase 1 plan](../plans/2026-10-07-phase-1-framework-spm-proof.md) uses original version getters without Core startup. It must prove full aggregate force-load closure, public Objective-C/Swift imports, contained dynamic framework, native Swift example/unit tests and relocated XCFramework/SPM consumption. It must not treat a successful metadata proof as lifecycle or functional-parity verification.

No original Core source or accepted distribution bytes were changed by this audit. No production framework, app or package implementation is claimed by this report.
