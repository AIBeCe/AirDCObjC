# Lifecycle and threading

## Observed Core behavior

At the pinned revision, `airdcpp/DCPlusPlus.h` exposes `initializeUtil`, `startup`, and `shutdown`. Startup creates managers, invokes module hooks, loads configuration and stored data, configures connectivity, and executes post-load work. Shutdown stops timers and work, closes connections, saves state, unloads modules, and deletes managers.

`airdcpp/core/Speaker.h` invokes raw-pointer listeners synchronously while holding its listener critical section. TimerManager, hash workers, and BufferedSocket own threads. A serial bridge queue does not automatically synchronize these Core threads.

These observations are architectural anchors, not a complete proof of every manager's safety.

## Proposed runtime contract to validate

Model lifecycle explicitly: stopped -> starting -> running -> stopping -> stopped, with a failure path whose cleanup is proven. Reject or coalesce conflicting lifecycle requests according to a reviewed contract. Initially permit one active Core runtime per process because Core owns singleton managers; validate restart before advertising it.

Configure application storage/resource paths before Core initialization. The host chooses an explicit profile location. Do not silently reuse another application's configuration or create production state in tests.

## Event boundary

Bridge-owned listener adapters must outlive registrations. Copy payloads required by consumers before the Core callback returns; queue delivery outside Core locks. Never dispatch synchronously to the UI from a Core callback.

For each listener prove:

1. Registration and removal obey that manager's locking/lifetime rules.
2. Delayed delivery cannot access destroyed Core objects.
3. The unsubscribe guarantee states whether queued callbacks can still run.
4. Ordering, snapshot/event races, queue limits, and dropped/coalesced events have explicit semantics.
5. Shutdown stops admissions, removes listeners safely, drains or invalidates work according to contract, and completes only after required Core teardown.

Do not promise a universal event queue or backpressure strategy before inventorying event volume and ordering requirements.

## Errors and partial initialization

Core startup can fail, including AbortException paths. Determine exactly which objects were created and what cleanup is safe. Calling normal shutdown after any arbitrary partial failure is not assumed safe. Define failure and retry behavior from source and focused tests.

No C++ exception may cross public Objective-C entry points or event delivery. Protect the whole reachable operation, including conversion and snapshot construction.

## Verification gate

Tests exercise conflicting starts/stops, shutdown during active transfers/search/share refresh, delayed callbacks, unsubscribe races, failed startup, isolated storage, and any advertised restart. Use explicit barriers and event expectations rather than timing sleeps. Process-isolate real Core tests when singleton state prevents reliable in-process isolation.
