import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import AirDCExampleModel
#endif

@Suite("Example runtime termination coordinator")
@MainActor
struct RuntimeTerminationCoordinatorTests {
    @Test("Allows termination immediately when stopped")
    func stoppedAllowsImmediately() {
        let model = RuntimeModel(api: FakeRuntimeAPI())
        let coordinator = RuntimeTerminationCoordinator(model: model)

        let disposition = coordinator.requestTermination { _ in Issue.record("unexpected deferred reply") }

        #expect(disposition == .allowNow)
    }

    @Test("Waits for startup then stops before replying")
    func waitsForStartingRuntime() throws {
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        let fixture = try DirectoryFixture()
        model.start(directories: fixture.directories)
        let coordinator = RuntimeTerminationCoordinator(model: model)
        var replies: [Bool] = []

        #expect(coordinator.requestTermination { replies.append($0) } == .later)
        #expect(api.stopCount == 0)

        api.send(.state(id: 1, .running, message: "running"))
        api.finishStart(nil)
        #expect(api.stopCount == 1)
        #expect(replies.isEmpty)

        api.send(.state(id: 2, .stopping, message: "stopping"))
        api.send(.state(id: 3, .stopped, message: "stopped"))
        api.finishStop(nil)

        #expect(replies == [true])
    }

    @Test("Allows process exit after startup failure without issuing stop")
    func startupFailureAllowsTermination() throws {
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        let fixture = try DirectoryFixture()
        model.start(directories: fixture.directories)
        let coordinator = RuntimeTerminationCoordinator(model: model)
        var replies: [Bool] = []

        #expect(coordinator.requestTermination { replies.append($0) } == .later)
        api.send(.state(id: 1, .failed, message: "startup failed"))
        api.finishStart(RuntimeModelError("startup failed"))

        #expect(api.stopCount == 0)
        #expect(replies == [true])
        #expect(model.state == .failed)
    }

    @Test("Joins an existing stop and replies once for duplicate requests")
    func joinsExistingStopOnce() {
        let api = FakeRuntimeAPI(state: .running)
        let model = RuntimeModel(api: api)
        let coordinator = RuntimeTerminationCoordinator(model: model)
        model.stop()
        api.send(.state(id: 1, .stopping, message: "stopping"))
        var replies: [Bool] = []

        #expect(coordinator.requestTermination { replies.append($0) } == .later)
        #expect(coordinator.requestTermination { replies.append($0) } == .later)
        #expect(api.stopCount == 1)

        api.send(.state(id: 2, .stopped, message: "stopped"))
        api.finishStop(nil)

        #expect(replies == [true, true])
    }

    @Test("Failed remains failed while process exit is permitted")
    func failedStateAllowsExitWithoutChangingState() {
        let model = RuntimeModel(api: FakeRuntimeAPI(state: .failed))
        let coordinator = RuntimeTerminationCoordinator(model: model)

        #expect(coordinator.requestTermination { _ in Issue.record("failed state should not defer") } == .allowNow)
        #expect(model.state == .failed)
    }
}

@MainActor
private final class FakeRuntimeAPI: RuntimeAPI {
    private(set) var state: RuntimeStateSnapshot
    private(set) var stopCount = 0
    private var observers: [UUID: @MainActor (RuntimeEventSnapshot) -> Void] = [:]
    private var startCompletion: (@MainActor (RuntimeModelError?) -> Void)?
    private var stopCompletion: (@MainActor (RuntimeModelError?) -> Void)?

    init(state: RuntimeStateSnapshot = .stopped) { self.state = state }
    func observe(_ receive: @escaping @MainActor (RuntimeEventSnapshot) -> Void) -> RuntimeEventObservation {
        let id = UUID(); observers[id] = receive
        return RuntimeEventObservation { [weak self] in self?.observers[id] = nil }
    }
    func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool,
               completion: @escaping @MainActor (RuntimeModelError?) -> Void) { startCompletion = completion }
    func stop(completion: @escaping @MainActor (RuntimeModelError?) -> Void) { stopCount += 1; stopCompletion = completion }
    func send(_ event: RuntimeEventSnapshot) {
        if event.kind == .state { state = event.state }
        for observer in observers.values { observer(event) }
    }
    func finishStart(_ error: RuntimeModelError?) { startCompletion?(error); startCompletion = nil }
    func finishStop(_ error: RuntimeModelError?) { stopCompletion?(error); stopCompletion = nil }
}
