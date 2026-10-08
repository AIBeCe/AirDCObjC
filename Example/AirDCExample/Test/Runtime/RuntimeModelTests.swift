import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import AirDCExampleModel
#endif

@Suite("Example runtime model")
@MainActor
struct RuntimeModelTests {
    @Test("Passes explicit isolated directories without changing state before native events")
    func startUsesExplicitDirectories() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        let directories = fixture.directories

        model.start(directories: directories, resetUnavailableBindAddresses: true)

        #expect(api.startCount == 1)
        #expect(api.lastDirectories == directories)
        #expect(api.lastResetUnavailableBindAddresses == true)
        #expect(model.state == .stopped)
        #expect(model.isStarting)
    }

    @Test("Rejects a missing resource directory before calling the runtime")
    func rejectsMissingResources() {
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("AirDCExample-\(UUID().uuidString)", isDirectory: true)
        let directories = RuntimeDirectories(
            profileDirectoryURL: URL(fileURLWithPath: "/tmp/example-profile"),
            resourceDirectoryURL: missing,
            temporaryDirectoryURL: URL(fileURLWithPath: "/tmp/example-temp")
        )

        model.start(directories: directories)

        #expect(api.startCount == 0)
        #expect(model.errorMessage?.contains("resource") == true)
        #expect(model.state == .stopped)
    }

    @Test("Preserves event order and bounds copied event history")
    func preservesOrderedBoundedEvents() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        model.start(directories: fixture.directories)

        for value in 0..<105 {
            api.send(.init(id: UInt64(value), kind: .step, state: .starting,
                           message: "step-\(value)", progress: nil,
                           isQuestion: false, isErrorMessage: false, errorDescription: nil))
        }

        #expect(model.events.count == 100)
        #expect(model.events.first?.id == 5)
        #expect(model.events.last?.id == 104)
        #expect(model.currentStep == "step-104")
    }

    @Test("Distinguishes indeterminate and exact determinate progress")
    func progressSemantics() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        model.start(directories: fixture.directories)

        api.send(.init(id: 1, kind: .progress, state: .starting, message: "", progress: nil,
                       isQuestion: false, isErrorMessage: false, errorDescription: nil))
        #expect(model.progress == nil)

        api.send(.init(id: 2, kind: .progress, state: .starting, message: "", progress: 0.375,
                       isQuestion: false, isErrorMessage: false, errorDescription: nil))
        #expect(model.progress == 0.375)
    }

    @Test("Surfaces start failure without inventing a successful state")
    func startFailureRemainsNativeDriven() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        model.start(directories: fixture.directories)
        api.send(.state(id: 1, .failed, message: "startup failed"))

        api.finishStart(RuntimeModelError("startup failed"))

        #expect(model.state == .failed)
        #expect(model.errorMessage == "startup failed")
        #expect(!model.isStarting)
    }

    @Test("Does not claim clean stop after a native stop error")
    func stopFailureRemainsVisible() {
        let api = FakeRuntimeAPI(state: .running)
        let model = RuntimeModel(api: api)
        model.stop()
        api.send(.state(id: 1, .failed, message: "cleanup failed"))

        api.finishStop(RuntimeModelError("cleanup failed"))

        #expect(model.state == .failed)
        #expect(model.errorMessage == "cleanup failed")
        #expect(!model.isStopping)
    }

    @Test("Clears live step and progress when stopping and starting another run")
    func clearsLiveStatusBetweenRuns() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        model.start(directories: fixture.directories)
        api.send(.state(id: 1, .running, message: "running"))
        api.send(.init(id: 2, kind: .step, state: .running, message: "old step", progress: nil,
                       isQuestion: false, isErrorMessage: false, errorDescription: nil))
        api.send(.init(id: 3, kind: .progress, state: .running, message: "", progress: 0.625,
                       isQuestion: false, isErrorMessage: false, errorDescription: nil))
        api.finishStart(nil)

        #expect(model.currentStep == "old step")
        #expect(model.progress == 0.625)
        model.stop()
        #expect(model.currentStep == nil)
        #expect(model.progress == nil)
        api.send(.state(id: 4, .stopped, message: "stopped"))
        api.finishStop(nil)

        model.start(directories: fixture.directories)
        #expect(model.currentStep == nil)
        #expect(model.progress == nil)
    }

    @Test("Invalidating observation prevents later model mutation")
    func invalidatedObservationIsIgnored() throws {
        let fixture = try DirectoryFixture()
        let api = FakeRuntimeAPI()
        let model = RuntimeModel(api: api)
        model.start(directories: fixture.directories)
        model.cancelObservation()

        api.send(.state(id: 1, .running, message: "running"))

        #expect(model.state == .stopped)
    }
}

@MainActor
private final class FakeRuntimeAPI: RuntimeAPI {
    private(set) var state: RuntimeStateSnapshot
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var lastDirectories: RuntimeDirectories?
    private(set) var lastResetUnavailableBindAddresses: Bool?
    private var observers: [UUID: @MainActor (RuntimeEventSnapshot) -> Void] = [:]
    private var startCompletion: (@MainActor (RuntimeModelError?) -> Void)?
    private var stopCompletion: (@MainActor (RuntimeModelError?) -> Void)?

    init(state: RuntimeStateSnapshot = .stopped) { self.state = state }

    func observe(_ receive: @escaping @MainActor (RuntimeEventSnapshot) -> Void) -> RuntimeEventObservation {
        let id = UUID()
        observers[id] = receive
        return RuntimeEventObservation { [weak self] in self?.observers[id] = nil }
    }

    func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool,
               completion: @escaping @MainActor (RuntimeModelError?) -> Void) {
        startCount += 1
        lastDirectories = directories
        lastResetUnavailableBindAddresses = resetUnavailableBindAddresses
        startCompletion = completion
    }

    func stop(completion: @escaping @MainActor (RuntimeModelError?) -> Void) {
        stopCount += 1
        stopCompletion = completion
    }

    func send(_ event: RuntimeEventSnapshot) {
        if event.kind == .state { state = event.state }
        for observer in observers.values { observer(event) }
    }

    func finishStart(_ error: RuntimeModelError?) { startCompletion?(error); startCompletion = nil }
    func finishStop(_ error: RuntimeModelError?) { stopCompletion?(error); stopCompletion = nil }
}

final class DirectoryFixture {
    let root: URL
    let directories: RuntimeDirectories

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let resources = root.appendingPathComponent("resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        directories = RuntimeDirectories(
            profileDirectoryURL: root.appendingPathComponent("profile", isDirectory: true),
            resourceDirectoryURL: resources,
            temporaryDirectoryURL: root.appendingPathComponent("temporary", isDirectory: true)
        )
    }

    deinit { try? FileManager.default.removeItem(at: root) }
}

extension RuntimeEventSnapshot {
    static func state(id: UInt64, _ state: RuntimeStateSnapshot, message: String) -> Self {
        .init(id: id, kind: .state, state: state, message: message, progress: nil,
              isQuestion: false, isErrorMessage: false, errorDescription: nil)
    }
}
