# Core coverage gaps

Date: 2026-10-07. These are evidence/implementation gaps, not scope exclusions. ALL functional capabilities remain in the project's ledger.

| Stable ID | Evidence and impact | Owning resolution |
|---|---|---|
| `availability.unverified` | Source/installed declarations alone do not prove each API's linkability or runtime semantics. Accepted aggregate proof does not replace domain scenarios. | Each owning domain phase verifies real public calls, events and failure paths; no verified status until evidence exists. |
| `modules.disabled` | 17 source module headers absent from accepted installed headers; manifest excludes `airdcpp/modules/**`; upstream non-Windows default BUILD_CORE_MODULES is OFF. AutoSearch/ADL/direct/listing search/history/highlight/hublist/preview/RSS remain required capabilities. | Separate approved Project 1 module build/integration work, then bridge tests. Do not alter Core artifacts in Phase 1. |
| `natpmp.disabled` | Accepted manifest sets enable_natpmp false; mapping implementation requires optional dependency/source enablement. | Separate Core input revision/integration proposal in connectivity phase. |
| `updater.trust-policy` | UpdateManager.cpp:235-284 reports signature failure but continues XML parsing and link replacement with verified=false; the updater downloader additionally gates autoUpdate on verification. | Before public network update APIs, decide and test host trust behavior from original source; do not claim failed signatures stop all processing. |
| `updater.platform` | Upstream excludes updater/downloader sources on non-Windows and defines NO_CLIENT_UPDATER. Not all UpdateManager/version functionality is thereby absent. | Trace exact updater capabilities and propose macOS equivalents/Project 1 change where required; no silent exclusion. |
| `platform.zip` | ZipFile.h is absent and upstream filters ZipFile implementation outside Windows. | Determine externally meaningful ZIP capability and propose platform-equivalent behavior; internal implementation differences are not automatic parity loss. |
| `platform.win-mapper` | Mapper_WinUPnP.cpp excluded on non-Windows; miniupnpc remains a built component. | Preserve mapping capabilities through supported macOS mapper; validate equivalence and record any unmet behavior. |
| `settings.semantic-contract-unresolved` | Remaining setting questions concern host/UI ownership for keys without an identified Core consumer, application of changes to already-running/cached consumers, and specific isolated-runtime edges. Known Core type/default/normalization/unit/persistence and consumer behavior stay in the setting record; this gap cannot replace readable source semantics. | Resolve the recorded host/runtime facet before promising that setting's corresponding public behavior; preserve the inspected Core contracts and original defaults. |
| `lifecycle.partial-startup` | startup creates process singletons before hash/share/connectivity loading can fail. Normal shutdown is not assumed safe at every partial point. | Phase 2 inspects all failure/teardown paths, implements guarded cleanup, and proves retry guarantees before advertising them. |
| `lifecycle.restart` | Core process-global managers and static state require validation before concurrent/multiple/repeated runtimes are promised. | Phase 2 single-runtime and restart contract tests. |
| `temp-share.concurrent-snapshot` | TempShareManager::getTempShares(TTH) traverses tempShares without cs; search, getRealPaths and upload resolution call this overload. | Sharing phase must establish coordinated access or separately approved Core synchronization fix, then prove concurrent mutation/snapshot behavior. A serial bridge queue alone cannot synchronize Core threads. |
| `events.delivery-contract` | Speaker::fire invokes raw listeners on emitting threads under a lock. Wrappers need payload/lifetime/order/unsubscribe contracts per listener family. | Phase 2 foundation plus owning domain source tracing and race tests. |
| `resources.host-policy` | Core paths, profiles, localization, certificates/trust, OpenSSL configuration and GeoIP resources are not automatically supplied by an archive. | Phase 2/3 explicit host configuration and isolated resource tests; metadata-only Phase 1 requires no Core startup resources. |

## Resource observations

`DCPlusPlus.cpp:64-187` initializes paths/utilities, attempts RUNNING flag creation without checking its boolean result, and creates singleton managers, loads settings/favorites/language/certificates/hash/queue/share/ignore/recents, optionally initializes GeoIP, starts connectivity, and invokes module/post-load hooks. These reads and writes make arbitrary real-profile startup inappropriate for a metadata link proof.

`util/AppUtil.cpp:228-260` uses configured global/resource directories on non-Windows, defaults user config to `$HOME/.airdc++/`, sets downloads and user-local paths, and attempts to ensure profile/local/language directories without checking those return values. Boot configuration and an explicit config path can affect this behavior. Phase 2 must bind all paths safely for a macOS host, not only change one directory string.

`core/crypto/CryptoManager.cpp:152-243,387-390` covers TLS availability and certificate generation/path configuration; defaults alone do not establish trust policy. `core/geo/GeoManager.cpp` owns database initialization/closure; the data source is a runtime prerequisite. Preserve original certificate/keyprint semantics and inspect them before exposing security-sensitive options.

## Gate interpretation

A transparent source-accounting inventory may contain an explicit evidence gap. A semantic record must not replace inspected original behavior with a guessed name-based contract. Open gaps remain linked and block implementation or final parity at their owning gate. Phase 1 demonstrates only real Core metadata and binary/package containment.
