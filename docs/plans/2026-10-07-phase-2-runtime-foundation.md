# Phase 2 — Runtime Foundation Implementation Plan

> **For agentic workers:** Use persistent worker/reviewer ownership. The user authorized every point of Phases 2 and 3 without routine stops. Tasks 1–3 are accepted under the full-phase authorization; scoped evidence and limitations are recorded in the gate report.

**Goal:** Expose a real, isolated, single-runtime Core lifecycle with safe exception/value/event boundaries, proven startup failure cleanup and an honest restart contract.

**Architecture:** An in-process coordinator serializes bridge commands while respecting Core-owned threads. Explicit host configuration establishes profile, local, resource and temporary paths before initialization. Core remains responsible for its algorithms and manager order.

**Tech Stack:** Objective-C public API, private C++20 Objective-C++, Foundation/dispatch, native Swift example and Swift Testing; ARM64/macOS 14+; unchanged Phase 0 Core input and contained XCFramework.

**Spec:** [Accepted design](../design.md), [lifecycle/threading contract](../lifecycle-and-threading.md), [API policy](../api-design.md), [Core baseline](../core-baseline.json).

## Authorization and boundary

Phase 2 starts at develop `073fb60` on `feature/runtime-foundation`. Complete this phase and integrate before creating the Phase 3 feature from develop. Do not start Phase 4 or publish a production release.

## Resolved preflight boundaries

- [x] Prove host path isolation before Core utility initialization, including boot configuration, local mode, migrations, resource directories and absence of fallback home-profile writes.
- [x] Trace startup construction and define guarded cleanup, with module-init/hash-open and five thread-position failure evidence. Arbitrary allocation/noexcept/workload failure recovery is not established; never assume normal shutdown is valid for partial construction.
- [x] Run an isolated disposable Core start/stop probe, then characterize restart and controlled startup failures. Disposable probes are evidence, not product coverage.
- [x] Define conflict, failure/retry/restart, profile-lock, callback and shutdown-drain contracts from these observations.
- [x] Present complete public headers and exact Given/When/Then tests; replace this preflight section with checkable implementation tasks before product edits.

## Binding constraints

- Only one active Core runtime per process; do not expose C++ singletons or raw Core pointers.
- No recoverable C++ exception crosses public entry points or callbacks. Fatal upstream noexcept termination is distinct and must not be disguised as a recoverable NSError guarantee.
- Copy listener payloads before return; client code runs outside Core listener locks. Lifetime covers copied in-flight listener emissions, not merely registration.
- State transitions, queued event invalidation, unsubscribe and shutdown completion semantics must be explicit and tested.
- Real Core tests use isolated state and process isolation when shared singletons prevent independent tests.
- Preserve mirrored Source/Test and Example/Source/Test paths, Swift Testing and Given/When/Then, native SwiftUI/AppKit and both workspace/SPM consumers.
- Keep the accepted archive and Core source unchanged. If the accepted Core prevents a required gate, record the evidence instead of declaring a smaller proof complete.

## Evidence and decisions

Core `DCPlusPlus.cpp:64–265` separates initialization, startup and shutdown; startup creates managers without a rollback block. The original `initializeUtil` signature is noexcept. AppUtil has no public arbitrary path setter; explicit path setup must follow its actual supported boot/configuration interface.

Independent architecture critique favors an in-process coordinator because a helper would require IPC for every future API/event. A quarantined failure can restrict unsafe calls, but it cannot alone satisfy the accepted proven-cleanup gate. Process hosting remains a larger fallback if cleanup cannot be established.

Task 1 is implemented and reviewed. Tasks 2 and 3 passed production native/packaged consumer tests and independent review; see the [gate report](../reports/phase-2-runtime-foundation.md). Root retains architecture and API authority.


## Task 1 — Immutable host configuration and errors

**Files:** Source/AirDCObjC/Public/Runtime/ADCError.h, Source/AirDCObjC/Private/Runtime/ADCError.m, Source/AirDCObjC/Public/Runtime/ADCRuntimeConfiguration.h, Source/AirDCObjC/Private/Runtime/ADCRuntimeConfiguration.m; mirrored Swift tests Test/AirDCObjC/Private/Runtime/ADCErrorTests.swift and ADCRuntimeConfigurationTests.swift. Update umbrella/header visibility, exports and verifier expectations, regenerate project. The configuration does not initialize Core or touch the filesystem.

**Proposed public units:**

```objc
#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSErrorDomain const ADCErrorDomain;
typedef NS_ERROR_ENUM(ADCErrorDomain, ADCErrorCode) {
    ADCErrorInvalidConfiguration = 1,
    ADCErrorRuntimeBusy = 2,
    ADCErrorNotRunning = 3,
    ADCErrorProfileInUse = 4,
    ADCErrorStartupFailed = 5,
    ADCErrorShutdownFailed = 6,
    ADCErrorCleanupFailed = 7,
    ADCErrorUnsupportedOperation = 8,
    ADCErrorInvalidArgument = 9,
    ADCErrorOperationFailed = 10,
    ADCErrorCancelled = 11,
    ADCErrorInvalidState = 12,
};
```

```objc
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCRuntimeConfiguration : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSURL *profileDirectoryURL;
@property(nonatomic, readonly, copy) NSURL *resourceDirectoryURL;
@property(nonatomic, readonly, copy) NSURL *temporaryDirectoryURL;
- (nullable instancetype)initWithProfileDirectoryURL:(NSURL *)profileDirectoryURL
                              resourceDirectoryURL:(NSURL *)resourceDirectoryURL
                             temporaryDirectoryURL:(NSURL *)temporaryDirectoryURL
                                             error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

The error domain string is `org.airdcpp.AirDCObjC`. Configuration accepts absolute file URLs with nonempty absolute paths, no query/fragment, NUL or remote host (empty/localhost is allowed). It stores standardized copies, without resolving symlinks or requiring directories to exist; the real runtime must check and prepare paths immediately before use. Reject non-file URLs and return ADCErrorInvalidConfiguration. Copying an immutable configuration may return self. No default profile, HOME fallback or private C++ type is introduced.

- [x] Write Given/When/Then Swift Testing cases: three valid temporary file-directory URLs retain standardized values; configuration/copy values remain immutable; no profile/resource/temp directory is created by construction; HTTPS, remote-host file URL, empty-path file URL, query/fragment and NUL-containing file URL are rejected with domain/code and no state changes.
- [x] Observe expected missing/incorrect behavior before implementation. A compile failure may establish missing interfaces, but follow with a behavior-failing stub before the final constructor.
- [x] Implement the complete units above and update the public module/configuration/export verification.
- [x] Run relevant native Swift/Objective-C consumer tests and standalone public-header checks; preserve the existing contained-Core/export allowlist checks. No runtime startup yet.
- [x] Independent review and fixes with persistent worker/reviewer; commit after PASS.

## Disposable runtime observations

Unchanged accepted Core linked with C++20/ARM64/minOS14, Iconv/Foundation. Isolated local-mode boot configuration kept writes under a scratch root. Startup/shutdown succeeded and removed RUNNING; two start/stop cycles in one process also succeeded for the same profile. Fixtures disabled automatic connectivity/GeoIP only in the isolated test profile.

A module-init exception after manager construction and a real HashData-open failure both propagated recoverable exceptions and left RUNNING. No normal shutdown was attempted after these failures. Guarded non-persisting cleanup is implemented and tested below; ownership quarantine applies only when cleanup fails and does not count as successful cleanup.


Task 1 completed as `b13959e`. TDD behavioral RED/GREEN and independent review PASS; a source/test Runtime-folder mismatch found by Root was fixed and independently re-reviewed. The full verifier rebuilt the artifact and passed eight Swift tests in each root/relocated package plus native suites and containment checks. The app remained metadata-only; no Core startup was claimed. Workspace/SwiftPM sandbox limitations required authorized escalated execution.

## Task 2 — Real single-runtime lifecycle and delivery foundation

**Files:** Create Source/AirDCObjC/Public/Runtime/{ADCRuntime.h,ADCRuntimeEvent.h,ADCSubscription.h} and mirrored Private/Runtime implementations (.mm for Core coordinator/cleanup, .m for Foundation value/delivery units). Create corresponding Test/AirDCObjC/Private/Runtime/*Tests.swift plus Runtime/Fixtures public-consumer subprocess helper sources as required. Update umbrella/header configuration, explicit exports/verifier, project/test/package fixture exclusions. Keep private command/lifecycle-service hooks in Private/Runtime only for Phase 3 consumers.

**Concrete public contract:**

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCRuntimeConfiguration.h>
#import <AirDCObjC/ADCRuntimeEvent.h>
#import <AirDCObjC/ADCSubscription.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCRuntime : NSObject
@property(nonatomic, readonly) ADCRuntimeState state;
@property(nonatomic, readonly, nullable, copy) ADCRuntimeConfiguration *configuration;
@property(nonatomic, readonly, nullable, copy) NSError *lastError;
@property(nonatomic, readonly) BOOL uncleanShutdownDetected;
- (instancetype)initWithDeliveryQueue:(dispatch_queue_t)deliveryQueue NS_DESIGNATED_INITIALIZER;
- (instancetype)init;
- (void)startWithConfiguration:(ADCRuntimeConfiguration *)configuration
 resetUnavailableBindAddresses:(BOOL)resetUnavailableBindAddresses
                   completion:(void (^)(NSError * _Nullable error))completion;
- (void)stopWithCompletion:(void (^)(NSError * _Nullable error))completion;
- (ADCSubscription *)observeEvents:(void (^)(ADCRuntimeEvent *event))observer;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ADCRuntimeState) {
    ADCRuntimeStateStopped = 0, ADCRuntimeStateStarting = 1,
    ADCRuntimeStateRunning = 2, ADCRuntimeStateStopping = 3,
    ADCRuntimeStateFailed = 4,
};
typedef NS_ENUM(NSInteger, ADCRuntimeEventKind) {
    ADCRuntimeEventStateChanged = 0, ADCRuntimeEventStep = 1,
    ADCRuntimeEventProgress = 2, ADCRuntimeEventMessage = 3,
};
@interface ADCRuntimeEvent : NSObject
@property(nonatomic, readonly) ADCRuntimeEventKind kind;
@property(nonatomic, readonly) ADCRuntimeState state;
@property(nonatomic, readonly, copy) NSString *message;
@property(nonatomic, readonly) double progress;
@property(nonatomic, readonly, getter=isDeterminateProgress) BOOL determinateProgress;
@property(nonatomic, readonly) BOOL question;
@property(nonatomic, readonly) BOOL errorMessage;
@property(nonatomic, readonly, nullable, copy) NSError *error;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCSubscription : NSObject
@property(nonatomic, readonly, getter=isValid) BOOL valid;
- (void)invalidate;
- (void)invalidateWithCompletion:(void (^)(void))completion;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

`init` targets main delivery; initWithDeliveryQueue builds a bridge-owned serial delivery queue targeting the supplied queue, preserving order even when the supplied target is concurrent. Admission/state is synchronized separately from the serial Core operation queue. Lifecycle requests are asynchronous; completions are delivered once on the serial delivery queue. Public state/configuration/lastError reads are safe without synchronously waiting on the Core queue.

States: stopped→starting→running→stopping→stopped. A second start (same object or another object) while Core is owned returns ADCErrorRuntimeBusy without changing the owner. Stop when already stopped succeeds idempotently; stop/start while starting or stopping is rejected as busy. Admission stops immediately on accepted stop, previously admitted Core work drains before teardown, and later services must reject operations unless running. A recoverable startup failure executes guarded cleanup before completion/state returns stopped; cleanup failure sets failed and prevents unsafe reuse, and cannot count as a successful cleanup gate. Failed retains the process owner and profile lock until process exit, including configuration/error snapshots; stop does not attempt unsafe reuse/release. File-lock release is allowed only after successful proven cleanup. Test failed cleanup naturally by replacing the owned RUNNING file with a nonempty directory after startup: never recursively delete unexpected marker contents; report cleanup failure and prove a second process remains locked until owner exit.

Same-process restart and changing isolated profiles must be tested before acceptance. Preserve the original sticky AppUtil.wasUncleanShutdown flag rather than silently resetting Core globals; document its observed meaning.

Startup questions are answered from the explicitly supplied Boolean, with no client/UI execution inside Core callbacks. At this pin the meaningful question is whether to clear an unavailable configured bind address. Notifications (including hash-database errors and automatic repair notices) copy into events; their callback return is ignored by Core. Do not describe the Boolean as a repair veto or an abort request.

Subscriptions copy event payloads before callback return. Invalidating immediately stops new admissions and skips queued undelivered callbacks; an already running callback may finish. invalidateWithCompletion queues a serial delivery barrier and completes only after earlier in-flight client work has returned, including self-invalidation without deadlock. No client code executes under Core/bridge listener or admission locks. Step/state/message events retain order; progress may coalesce to the latest value with at most one active pending progress-delivery job. Coalescing is scoped to the current step/lifecycle generation: never deliver a newer stage’s progress before that stage’s step event; obsolete queued progress jobs skip delivery. This behavior is explicitly tested/documented.

Progress units are original Core fractional completion: 0 is beginning, 1 is complete. Progress events preserve the original float promoted to double, including out-of-range/nonfinite values rather than silently clamping Core output. determinateProgress is true only for Progress-kind events with finite values in [0,1]; otherwise UI must show indeterminate state. Non-progress events have progress=0 and determinateProgress=false. Tests cover 0/0.5/1, NaN, infinities, negative/>1 values and non-progress events.

### Core paths, ownership and cleanup algorithm

Preflight resources/profile/temp directory kinds, readability/writability, path encoding and boot path isolation before utility initialization. Create owned profile subdirectories with restricted permissions; reject conflicting file paths and unsafe boot-directory symlinks. A profile lock protects simultaneous cooperating framework processes; keep it until cleanup/stop is complete. It does not protect a client that ignores that lock. Generate local-mode boot config only under an owned profile bootstrap directory, use a synthetic application path there, pass explicit profile/temp/resources, verify all effective AppUtil paths stay at their configured/derived locations, and disable migration via actual Core local mode. Do not override host's real settings/defaults merely to make tests offline; offline/Geo-disabled values are isolated fixtures.

Call original initializeUtil/startup/shutdown without modifying Core. After startup succeeds, start the original TimerManager through its inherited Thread.start before reporting running: its constructor only locks its shutdown mutex and Core startup never starts the timer. Timer-start exceptions are startup failures and must use guarded cleanup. The previous four-thread disposable fixture did not start this host-owned timer; extend fault/behavior evidence rather than treating it as a complete running-runtime proof.

Core lifecycle and service work use a private dedicated OS thread, rather than relying on serial dispatch to retain thread identity. Timer construction locks its shutdown mutex and shutdown unlocks it; these operations must stay on the same thread. The executor is created lazily inside the translated start boundary, reused across stopped cycles, and owned by the process rather than by its own queued runtime task. Its construction/enqueue failures must become completion errors without escaping Objective-C entry points. Runtime release must not cause self-join or destroy the executor while its loop still uses it. Foundation client delivery remains on the separate serial dispatch queue. Wrap the entire reachable operation and conversion/callback boundary for recoverable C++ exceptions. Upstream noexcept termination/allocation failure is not a recoverable NSError guarantee.

The accepted disposable cleanup algorithm null-checks every manager: stop Timer; abort share refresh; stop/join Hash workers; stop Share tasks through original shutdown; stop search UDP reception and connections/connectivity/Geo; wait BufferedSocket shutdown; delete managers in exact upstream teardown order while dependencies still live; remove RUNNING last. On failed startup it skips settings/favorites/queue/recents/ignore persistence that would serialize unloaded state. Record startup stage and justify any stage-specific cleanup; never assume normal full shutdown works for partial construction.

Production regression evidence exposed a missing host teardown responsibility: SearchManager's destructor unregisters its timer listener but UDPServer's destructor does not disconnect/join its receiver. Core shutdown only closes connectivity mappers. A live UDP thread can therefore access its destroyed socket/manager. The host invokes original SearchManager.disconnect before manager deletion. For normal shutdown use its original module-unload callback, after the single original Timer shutdown and while managers still exist; do not call Timer.shutdown twice. Guarded partial cleanup explicitly disconnects search when constructed. Test the real listening path and repeated lifecycle, rather than disabling search to avoid the defect. The original Core archive/source remain unchanged.

Receiver join alone does not drain UDPServer's packet dispatcher: queued handlePacket jobs touch ProtocolCommandManager/CryptoManager that original teardown deletes before SearchManager. After disconnect, append an original getUdpServer.addTask barrier and wait for preceding packet tasks to finish outside listener/admission locks before manager destruction. Its completion only signals private synchronization; it never executes client code. A bounded barrier failure retains/quarantines ownership instead of deleting live dependencies. This proves the currently queued receiver workload; later transfer/search phases must prove quiescence of their additional Core producers.

Disposable tests passed module-init exception, actual HashData-open failure and all four reachable pthread-create failure positions (Log dispatcher, Search UDP dispatcher, Queue dispatcher, Hasher). Each null-aware cleanup preserved existing Settings/Favorites/Queue/ShareCache sentinel bytes, removed RUNNING, then same-profile retry and ordinary stop succeeded. This is focused evidence for the algorithm and source dependencies, not a claim of arbitrary allocation-failure recovery or every possible future workload.

### Test-first and acceptance steps

- [x] Write Foundation delivery/subscription Given/When/Then tests for event snapshots, ordered serial delivery, queued cancellation, active callback barrier, self-invalidation and bounded progress coalescing; final behavior assertions pass. Planned behavior RED was not observed for this point; the report records the TDD deviation.
- [x] Write public-API subprocess tests using isolated profiles/resources and explicit barriers: fresh start/stop marker; same/profile-change restart; unavailable bind-address question false/true; sticky unclean flag; concurrent objects/requests and same-profile cross-process lock and failed-cleanup lock retention until owner exit; invalid/nonwritable/file-conflicting roots leave stopped/retriable; real HashData failure returns NSError only after cleanup with sentinels unchanged; retry after repair succeeds. No sleeps as synchronization.
- [x] Include Core-thread failure fault injection in a test-only child fixture where possible, without adding production test controls or public C++ symbols. Keep the accepted four-position disposable probe as source-backed cleanup evidence and distinguish it from public framework assertion coverage.
- [x] Implement exact public units, profile preflight, serial admission/Core work, safe Foundation events, original startup callbacks and guarded cleanup.
- [x] Verify all introduced tests through canonical native workflows and the generated/relocated binary package, public ObjC+Swift imports, updated intentional exports and unchanged full-Core containment. Every failed-start completion must occur after its cleanup/lock release.
- [x] Independent review of concurrency/lifetimes/error/path boundaries, all fixes and re-review PASS; commit this point only after acceptance. Root records normalized evidence and scoped lifecycle coverage.

## Task 3 — Native runtime scenario and Phase 2 gate

- [x] Add a focused native Swift runtime scenario/model with mirrored Swift Testing Given/When/Then tests. Use only public `AirDCObjC` APIs in the production adapter; use an internal injectable API seam for model/termination tests. Keep framework test controls out of public headers.
- [x] Show three explicit directory choices: an isolated Application Support profile directory, an explicit existing Core resource directory selected by the user, and an isolated Application Support temporary directory. Do not assume the app bundle contains Core resources. Constructing the configuration must not create directories; missing/unreadable resources and invalid paths are visible errors before Start.
- [x] Show copied state, ordered event snapshots, determinate/indeterminate progress, messages/errors, and Start/Stop. Keep BuildInfo metadata visible and avoid implying networking/domain parity.
- [x] Coordinate orderly app termination: Stopped permits termination; Starting records one pending termination request and waits for start completion before stopping; Running starts stop; Stopping waits for the existing stop completion; Failed keeps the native failure visible and may permit process exit without claiming cleanup. Use AppKit `terminateLater`/exactly-once `reply(toApplicationShouldTerminate:)`; no sleeps or delayed polling.
- [x] Build/run the same model sources in workspace and relocated package configurations; inspect native scenario and real startup/stop, verify embedding/signatures. Package model/value sources in the separate `AirDCExampleModel` target and app-only view/entry sources in `AirDCExample`; do not edit package/config/scripts as part of this point.
- [x] Final independent whole-phase review, exact commands/results/limits in tracked report, per-operation coverage and progress/roadmap, cohesive feature commits and GitFlow develop integration/publication.
- [ ] After Phase 2 PASS create Phase 3 feature from integrated develop and execute its accepted scope; stop only after Phase 3.

### Proposed units and ownership

`RuntimeStateSnapshot`, `RuntimeEventSnapshot`, `RuntimeDirectories`, `RuntimeModel`, and the termination coordinator are public Swift types in the example package module because the app view/delegate consume them. `RuntimeAPI`, its production adapter, its observation token, and test initializer are internal; tests use `@testable import AirDCExampleModel`. None of these types are added to the Objective-C framework. The model contains only Sendable value snapshots and does not store Objective-C runtime/event objects. There is no `@unchecked Sendable` conformance.

This is an interface sketch; the complete compilable implementations are [RuntimeAPI.swift](../../Example/AirDCExample/Source/Runtime/RuntimeAPI.swift), [RuntimeModel.swift](../../Example/AirDCExample/Source/Runtime/RuntimeModel.swift), and [RuntimeTerminationCoordinator.swift](../../Example/AirDCExample/Source/Runtime/RuntimeTerminationCoordinator.swift):

```swift
import Combine
import Foundation

public enum RuntimeStateSnapshot: Int, Sendable, Equatable {
    case stopped, starting, running, stopping, failed
}

public struct RuntimeDirectories: Sendable, Equatable {
    public let profileDirectoryURL: URL
    public let resourceDirectoryURL: URL
    public let temporaryDirectoryURL: URL
    public init(profileDirectoryURL: URL, resourceDirectoryURL: URL, temporaryDirectoryURL: URL) {
        self.profileDirectoryURL = profileDirectoryURL
        self.resourceDirectoryURL = resourceDirectoryURL
        self.temporaryDirectoryURL = temporaryDirectoryURL
    }
}

public struct RuntimeModelError: Error, LocalizedError, Sendable, Equatable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public struct RuntimeEventSnapshot: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable { case state, step, progress, message }
    public let id: UInt64
    public let kind: Kind
    public let state: RuntimeStateSnapshot
    public let message: String
    public let progress: Double?
    public let isQuestion: Bool
    public let isErrorMessage: Bool
    public let errorDescription: String?
}

@MainActor
protocol RuntimeAPI: AnyObject {
    var state: RuntimeStateSnapshot { get }
    func observe(_ receive: @escaping @MainActor (RuntimeEventSnapshot) -> Void) -> RuntimeEventObservation
    func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool,
               completion: @escaping @MainActor (RuntimeModelError?) -> Void)
    func stop(completion: @escaping @MainActor (RuntimeModelError?) -> Void)
}

@MainActor
public final class RuntimeModel: ObservableObject {
    @Published public private(set) var state: RuntimeStateSnapshot
    @Published public private(set) var progress: Double?
    @Published public private(set) var currentStep: String?
    @Published public private(set) var lastMessage: String?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var events: [RuntimeEventSnapshot] // oldest entries trimmed above 100

    public convenience init() { self.init(api: ADCRuntimeAPI()) }
    init(api: any RuntimeAPI) // internal test seam
    public var isStarting: Bool { get }
    public var isStopping: Bool { get }
    public var canStart: Bool { get }
    public var canStop: Bool { get }
    public func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool = false)
    public func stop()
    public func cancelObservation()
}

@MainActor
public final class RuntimeTerminationCoordinator {
    public enum Disposition: Sendable, Equatable { case allowNow, later }
public init(model: RuntimeModel)
public func requestTermination(reply: @escaping @MainActor (Bool) -> Void) -> Disposition
}
```

`RuntimeStateSnapshot` mirrors Stopped/Starting/Running/Stopping/Failed without carrying `NSError`. The production adapter creates `ADCRuntime()` (which defaults delivery to main), constructs `ADCRuntimeConfiguration` only after the caller supplies all three directory URLs, copies each `ADCRuntimeEvent` synchronously into a value snapshot, and forwards completion errors as copied descriptions. Callback delivery is serial on the runtime delivery queue. The adapter must preserve that order: do not create an independent `Task { @MainActor ... }` per callback. Assert main-thread delivery and enter the main actor synchronously for the configured main queue. The subscription token has explicit idempotent cancellation; callbacks weakly capture the model, and the model cancels observation when termination completes.

The native view uses an `NSOpenPanel` directory selection for the required Core resource directory. The profile and temporary directories default to distinct paths below the example’s Application Support directory; edits/selections are explicit UI state and are shown before Start. No example path points at the user’s ordinary AirDC++ profile. Configuration construction does not create or mutate paths. Start remains disabled until the resource directory is selected and validated; the native runtime remains the authority for actual startup errors.

`RuntimeTerminationCoordinator` is a public, AppKit-free sequencer in the model module. The app-only `ExampleRuntimeTerminationDelegate` forwards AppKit termination requests and replies to the coordinator. It records one pending termination reply while startup is unresolved, stops after successful start, joins an already-running stop rather than issuing a duplicate, and replies exactly once after stop completion. A Failed state remains Failed and its error is shown; the coordinator may allow process exit because the native owner retains failed cleanup state until process exit, but must not label that state Stopped or clean. Stopped immediately permits termination. Coordinator tests inject the fake runtime API and a reply closure without launching the app.

### Concrete model and termination scenarios

- Given a stopped model and explicit isolated profile/resource/temp URLs, when Start is requested, then exactly those URLs/options are passed to the API and the model remains native-state-driven until an event or completion arrives.
- Given a selected resource path that is missing or not a directory, when Start is attempted, then the model exposes a validation error and does not call the runtime API.
- Given ordered state, step, progress, and message callbacks, when the fake API delivers them on the main actor, then the model preserves arrival order, copies their values, and trims only the oldest events after 100.
- Given a progress event marked indeterminate, when it is applied, then displayed numeric progress is absent; given a determinate fraction, then that exact fraction is retained without reinterpretation.
- Given a previous run has a current step and determinate progress, when Stop begins or a subsequent Start begins, then those live fields are cleared while prior copied event history remains available.
- Given Start completes with an error, when the completion is applied, then the error is visible and the model does not fabricate Running or successful cleanup.
- Given Running, when Stop is requested, then one stop request is issued; if it completes with error, then failure remains visible and the model does not claim Stopped.
- Given an observation is invalidated, when later fake events arrive, then no model state changes.
- Given Stopped, when app termination is requested, then termination is immediately allowed.
- Given Starting, when app termination is requested, then the delegate returns `terminateLater`; after successful start completion it issues one Stop, and only after Stop completion replies once to AppKit.
- Given Starting, when start fails, then the delegate replies once and preserves the failure without issuing Stop as if startup had succeeded.
- Given Running, when termination is requested, then one Stop is issued and one termination reply follows its completion.
- Given Stopping, when termination is requested, then the existing stop is joined and no second Stop is issued; its completion produces one reply.
- Given Failed, when termination is requested, then process exit may be allowed, while visible/native state remains Failed and no cleanup-success claim is made.
- Given duplicate termination requests while one reply is pending, when the pending lifecycle operation completes, then each AppKit request receives exactly one corresponding reply with no duplicate Stop.

### Mirrored tests and package sources

Add `Example/AirDCExample/Test/Runtime/RuntimeModelTests.swift` and `RuntimeTerminationCoordinatorTests.swift`. The model tests use a deterministic fake to assert exact configuration/options, native-driven state changes, event order and copied payloads, progress semantics, the 100-event bound, startup/stop errors, input validation, and subscription cancellation. Termination tests exercise Stopped, Starting success/failure, Running, Stopping, Failed, and duplicate requests, asserting stop-call count and exactly-once reply without timers or sleeps. The fake and test initializer remain internal to the package model module.

Add `RuntimeAPI.swift`, `RuntimeModel.swift`, and `RuntimeTerminationCoordinator.swift` under `Example/AirDCExample/Source/Runtime/` for `AirDCExampleModel`; add `RuntimeStatusView.swift`, `ExampleRuntimeTerminationDelegate.swift`, and the app entry integration to the executable source set. Integrate the status view into the existing BuildInfo view while retaining `BuildInfoSnapshot`. Root owns `Package.swift`, `config/project.yml`, generated project settings, scripts, and framework integration; mirror the model source list in workspace and package model targets, while AppKit app-entry/delegate/view sources stay in the executable target. Tests live under `Example/AirDCExample/Test/Runtime/`. No public framework symbol, export, Core algorithm, or standard user-profile path is added here.


Task 2 independent design critique I1/I2 resolved in the plan: Failed retains profile/process ownership until exit, with a natural marker-sabotage test; progress preserves raw Core fractional values while exposing exact determinate/non-progress semantics. No Core algorithm or input pin changes are authorized by these decisions.


Root source discovery on 2026-10-08: TimerManager.cpp:33–45 constructs a locked shutdown mutex, while run() at 47–78 fires Second/Minute events only when Thread.start is called. No TimerManager.start call exists in the original Core tree. The host-runtime running contract therefore includes explicit timer startup after Core startup, and its additional failure point. This preserves an original public host responsibility; it does not patch Core or invent a timer algorithm.
