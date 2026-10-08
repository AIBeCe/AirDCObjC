# Phase 2 runtime foundation evidence

Updated: 2026-10-08. **Gate 2 PASS.** Runtime implementation, native assertions, root/relocated binary consumers and inspected native lifecycle passed independent review and canonical verification.

## Accepted configuration boundary

Task 1 commit `b13959e` introduces immutable local-file host URLs and the stable `org.airdcpp.AirDCObjC` error domain/codes. Construction standardizes copies and rejects invalid URL forms without touching the filesystem. Behavioral TDD and independent review passed; the Root-found source/test Runtime-folder mismatch was corrected and re-reviewed.

Canonical verification rebuilt the binary and passed nine native tests (six private Swift, one public Objective-C, two example Swift) plus eight Swift tests in each root and relocated package environment. The public export list contains the original metadata class, the configuration class, their metaclasses and ADCErrorDomain. These are configuration/metadata tests, not runtime startup tests.

## Disposable Core feasibility evidence

The unchanged accepted aggregate linked into an isolated C++ child using ARM64/C++20/macOS 14, SDK Iconv/Foundation and accepted distribution headers. Synthetic application/boot paths used explicit LocalMode, ConfigPath, TempPath and ResourcePath; emitted files stayed under the scratch root. Offline/Geo-disabled settings were test fixtures only.

Fresh startup/shutdown passed and removed RUNNING. Same-profile restart in one process passed. Module-init exception and actual HashData-open failure propagated recoverable exceptions; without guarded cleanup each left RUNNING. Normal shutdown after arbitrary partial construction was not assumed safe.

A null-aware cleanup probe stopped timers/hash/share/connections/connectivity/Geo, waited buffered sockets, deleted managers in upstream order and removed RUNNING last. It skipped serialization of unloaded settings/favorites/queue/recents/ignore state. Each probe preserved Settings/Favorites/Queue/ShareCache sentinel bytes at its cleanup checkpoint, then completed same-profile retry and ordinary stop.

| Failure input | Probe cleanup/retry result |
|---|---|
| module-init callback throws after managers are constructed | PASS |
| real HashData open/LOCK failure | PASS |
| pthread_create EAGAIN at LogManager dispatcher | PASS |
| pthread_create EAGAIN at Search UDP dispatcher | PASS |
| pthread_create EAGAIN at QueueManager dispatcher | PASS |
| pthread_create EAGAIN at HashManager Hasher | PASS |
| pthread_create EAGAIN at host-started TimerManager (extended fixture ordinal 5) | PASS |

The thread fault helper defined a strong executable pthread_create wrapper forwarding through dlsym(RTLD_NEXT), failing once at a configured ordinal. The original fixture reached four startup thread creations without the host-owned timer. The extended fixture starts TimerManager and fails its fifth thread creation with EAGAIN. Guarded cleanup removed RUNNING, preserved Settings/Favorites/Queue/ShareCache bytes, and same-profile retry/start/stop passed. Its cleanup also uses the current search disconnect/dispatcher barrier. Child alarms bounded each test. These ordinals describe this isolated fixture, not every possible connectivity/workload thread. These are disposable Core/cleanup-algorithm observations, not public framework fault assertions or a blanket guarantee of every allocation/workload failure.

Source anchors: DCPlusPlus.cpp:64–265; Singleton.h:39–49; LogManager.cpp:31; SearchManager.cpp:38–42; QueueManager.cpp:71–74; HashManager.cpp:370–395; Hasher.cpp:45–47; ShareManager.cpp:114–120; DispatcherQueue.h:35–46. Core original source/artifact were not changed.

## Accepted runtime decisions

Task 2 design review PASS after clarifying failed-cleanup ownership and progress. Incomplete cleanup retains process/profile ownership until exit rather than admitting unsafe reuse. Runtime events preserve original raw fractional progress with an explicit determinate predicate and non-progress defaults. Startup bind-address reset is an explicit caller choice; notices/automatic database repair do not become a fictitious host repair veto. Client delivery stays outside Core callbacks/locks.

Original AppUtil.wasUncleanShutdown is sticky across cycles; no silent Core-global reset is planned. Fatal original noexcept termination is distinct from recoverable NSError translation.

Core operations use a private process-owned dedicated OS thread. Timer construction and shutdown's lock/unlock stay on that thread; a serial dispatch queue alone does not guarantee this identity. The runtime explicitly starts TimerManager after Core startup before reporting running. Each executor task has an autorelease pool; copied client events/results use a separate serial delivery queue. Private service admission is synchronized with stop and must prove FIFO drain/rejection through direct tests.

Periodic timer callbacks are not public runtime events. Successful start/stop will exercise the timer startup path; real timed reservation expiry in Phase 3 will prove periodic behavioral delivery. Do not add a production observer solely for a test or link another Core copy into a helper to inspect its different singletons. Timer-start failure gets focused disposable cleanup evidence separately.

The production private drain test reproduced a shutdown SIGSEGV in Socket.disconnect from UDPServer.run. Source inspection established that normal Core shutdown closes connectivity mappers but does not join search UDP reception, and SearchManager/UDPServer destructors do not do it. Framework teardown therefore invokes original SearchManager.disconnect before manager destruction, through the normal shutdown module-unload hook and explicitly in guarded partial cleanup, then waits for a queued dispatcher barrier. Timer shutdown remains a single call. Focused private drain and repeated public lifecycle now pass. Direct injection of queued UDP work from an external helper was rejected because Core C++ symbols intentionally remain hidden; no exports or production test selectors were added. The successful stop path exercises the internal barrier, while controlled packet/transfer workload coverage belongs to its later domain phase.

The native example selects resources explicitly rather than assuming a bundled runtime resource directory. Its model and termination coordinator use only public framework calls, copied Swift values and main-actor UI ownership. Real Core proof belongs to the subprocess assertions and inspected native scenario, not to the model's fake adapter tests.

## Gate verification and limits

Canonical native `scripts/test` now passes 14 private Swift tests, 9 public lifecycle subprocess tests, 1 public Objective-C metadata assertion and 15 example Swift tests. These results include profile ownership, restart, real HashData failure/repair/retry, bind-address policy, boot-override rejection, sticky unclean state and bounded reader behavior. Subprocess pipe reads use readiness/deadline handling; a silent child cannot hang the suite. Custom-queue Swift callbacks use nonisolated functions; the example uses default main delivery with copied main-actor state.

TDD limitation: Foundation event/subscription missing interfaces produced compile RED; no observed behavior RED is claimed for that stage or for the initial public runtime implementation. This deviates from the planned behavior-failing stub sequence. The current suites assert real behavior, but a passing final suite does not retroactively establish test-first implementation. Subsequent Phase 3 points must record genuine expected behavior failures before implementation.

Canonical `rtk ./scripts/verify` completed with exit 0. Each root and relocated SwiftPM environment passed 30 tests in 7 suites, including nine public runtime subprocess cases. The relocated consumer contains no framework Source, Dependencies or private runtime probe. Its full SwiftUI app built and launched. Native and relocated app bundles passed `codesign --verify --deep --strict`; the framework passed ARM64/MACOS/minOS 14.0, exact 11-symbol exports, SDK-only load commands and unchanged aggregate/header containment (16,430 checksums and 245 accepted headers). These are local binary-development package proofs, not a remote production SPM release or fresh-machine/macOS 14 runtime claim.

The inspected native Debug app used disposable `Build/Phase2UI/{Profile,Resources,Temporary}` directories. UI actions reached Running, Stop returned Stopped and removed RUNNING, restart reached Running, and Command-Q terminated the running app with RUNNING removed. The fixture uses the actual `AutoDetectIncomingConnection` and `AutoDetectIncomingConnection6` XML names; the extended timer failure fixture was corrected and rerun with those names. This validates default-main delivery and real AppKit orderly termination. Independent runtime, example and final packaging reviews returned PASS; the example stale-progress finding was corrected and re-reviewed. The [Phase 2 plan](../plans/2026-10-07-phase-2-runtime-foundation.md) owns executable steps. Stop only after the subsequent authorized Phase 3 gate, with no Phase 4 work or production release.
