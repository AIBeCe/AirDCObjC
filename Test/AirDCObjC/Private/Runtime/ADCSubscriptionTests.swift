import AirDCObjC
import Dispatch
import Foundation
import Testing

@Suite("Runtime event subscriptions", .serialized)
struct ADCSubscriptionTests {
    @Test("Invalidation skips an event that is still queued")
    func queuedDeliveryCanBeCancelled() throws {
        // Given: a suspended target queue and an observer that records deliveries.
        let target = DispatchQueue(label: "ADCSubscriptionTests.queued-cancel")
        target.suspend()
        let delivered = DispatchSemaphore(value: 0)
        let subscription = ADCMakeRuntimeTestSubscription(target) { _ in delivered.signal() }
        let event = ADCMakeRuntimeEvent(.message, .running, "queued", 0, false, false, nil)

        // When: delivery is queued, then the subscription is invalidated before the target resumes.
        ADCEnqueueRuntimeTestEvent(subscription, event, 0)
        subscription.invalidate()
        target.resume()

        // Then: queued work is skipped and the subscription is invalid immediately.
        #expect(!subscription.isValid)
        #expect(delivered.wait(timeout: .now() + 0.15) == .timedOut)
    }

    @Test("Invalidation completion waits for an active callback")
    func invalidationIsACompletionBarrier() throws {
        // Given: an observer callback held open by a semaphore.
        let target = DispatchQueue(label: "ADCSubscriptionTests.barrier")
        let entered = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        let completed = DispatchSemaphore(value: 0)
        let subscription = ADCMakeRuntimeTestSubscription(target) { _ in
            entered.signal()
            _ = release.wait(timeout: .now() + 2)
        }
        let event = ADCMakeRuntimeEvent(.message, .running, "active", 0, false, false, nil)

        // When: the callback is active and invalidation requests its serial completion barrier.
        ADCEnqueueRuntimeTestEvent(subscription, event, 0)
        #expect(entered.wait(timeout: .now() + 1) == .success)
        subscription.invalidate(completion: { completed.signal() })

        // Then: completion waits until the active callback returns.
        #expect(completed.wait(timeout: .now() + 0.05) == .timedOut)
        release.signal()
        #expect(completed.wait(timeout: .now() + 1) == .success)
    }

    @Test("Self-invalidation completion does not deadlock")
    func selfInvalidationCompletesAfterCallback() throws {
        // Given: an observer that invalidates itself from inside its callback.
        let target = DispatchQueue(label: "ADCSubscriptionTests.self-invalidation")
        let completed = DispatchSemaphore(value: 0)
        var subscription: ADCSubscription!
        subscription = ADCMakeRuntimeTestSubscription(target) { _ in
            subscription.invalidate(completion: { completed.signal() })
        }
        let event = ADCMakeRuntimeEvent(.message, .running, "self", 0, false, false, nil)

        // When: the callback is delivered and queues its own completion barrier.
        ADCEnqueueRuntimeTestEvent(subscription, event, 0)

        // Then: invalidation completes after the callback without blocking that callback.
        #expect(completed.wait(timeout: .now() + 1) == .success)
        #expect(!subscription.isValid)
    }

    @Test("Coalesces progress without moving it ahead of the next step")
    func progressCoalescesWithinGeneration() throws {
        // Given: a suspended target so several events accumulate before delivery.
        let target = DispatchQueue(label: "ADCSubscriptionTests.coalescing")
        target.suspend()
        let lock = NSLock()
        var received: [(ADCRuntimeEventKind, String, Double)] = []
        let drained = DispatchSemaphore(value: 0)
        let subscription = ADCMakeRuntimeTestSubscription(target) { event in
            lock.lock()
            received.append((event.kind, event.message, event.progress))
            let finished = received.count == 3
            lock.unlock()
            if finished { drained.signal() }
        }

        // When: progress is replaced within stage one, then stage two is queued with two updates.
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.step, .starting, "one", 0, false, false, nil), 1)
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.progress, .starting, "one", 0.1, false, false, nil), 1)
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.progress, .starting, "one", 0.4, false, false, nil), 1)
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.step, .starting, "two", 0, false, false, nil), 2)
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.progress, .starting, "two", 0.2, false, false, nil), 2)
        ADCEnqueueRuntimeTestEvent(subscription,
            ADCMakeRuntimeEvent(.progress, .starting, "two", 0.8, false, false, nil), 2)
        target.resume()

        // Then: the obsolete stage-one progress is skipped; stage two keeps its step before its latest progress.
        #expect(drained.wait(timeout: .now() + 1) == .success)
        lock.lock()
        let snapshot = received
        lock.unlock()
        #expect(snapshot.map(\.1) == ["one", "two", "two"])
        #expect(snapshot.map(\.0) == [.step, .step, .progress])
        #expect(snapshot.map(\.2) == [0, 0, 0.8])
        subscription.invalidate()
    }
}
