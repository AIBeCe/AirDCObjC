import Foundation
import Combine

@MainActor
public final class RuntimeModel: ObservableObject {
    @Published public private(set) var state: RuntimeStateSnapshot
    @Published public private(set) var progress: Double?
    @Published public private(set) var currentStep: String?
    @Published public private(set) var lastMessage: String?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var events: [RuntimeEventSnapshot] = []

    private enum Operation: Equatable { case starting, stopping }
    private var operation: Operation?
    private var operationWaiters: [@MainActor (RuntimeModelError?) -> Void] = []
    private let api: any RuntimeAPI
    private var observation: RuntimeEventObservation?

    public convenience init() { self.init(api: ADCRuntimeAPI()) }

    init(api: any RuntimeAPI) {
        self.api = api
        state = api.state
        observation = api.observe { [weak self] event in self?.receive(event) }
    }

    public var isStarting: Bool { operation == .starting }
    public var isStopping: Bool { operation == .stopping }
    public var canStart: Bool { operation == nil && state == .stopped }
    public var canStop: Bool { operation == nil && state == .running }

    public func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool = false) {
        guard canStart else { return }
        guard validate(directories) else { return }

        errorMessage = nil
        progress = nil
        currentStep = nil
        lastMessage = nil
        operation = .starting
        api.start(directories: directories, resetUnavailableBindAddresses: resetUnavailableBindAddresses) { [weak self] error in
            self?.complete(.starting, error: error)
        }
    }

    public func stop() {
        guard canStop else { return }

        errorMessage = nil
        progress = nil
        currentStep = nil
        lastMessage = nil
        operation = .stopping
        api.stop { [weak self] error in self?.complete(.stopping, error: error) }
    }

    public func cancelObservation() {
        observation?.cancel()
        observation = nil
    }

    func afterCurrentOperation(_ completion: @escaping @MainActor (RuntimeModelError?) -> Void) {
        guard operation != nil else {
            completion(nil)
            return
        }
        operationWaiters.append(completion)
    }

    private func validate(_ directories: RuntimeDirectories) -> Bool {
        let values = [directories.profileDirectoryURL, directories.resourceDirectoryURL, directories.temporaryDirectoryURL]
        guard values.allSatisfy({ $0.isFileURL && $0.path.hasPrefix("/") }) else {
            errorMessage = "Runtime directories must be absolute local file URLs."
            return false
        }

        var isDirectory = ObjCBool(false)
        let path = directories.resourceDirectoryURL.path
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              FileManager.default.isReadableFile(atPath: path) else {
            errorMessage = "The selected Core resource path must be an existing readable directory."
            return false
        }
        return true
    }

    private func receive(_ event: RuntimeEventSnapshot) {
        switch event.kind {
        case .state:
            state = event.state
            if event.state != .running {
                progress = nil
                currentStep = nil
            }
        case .step:
            currentStep = event.message
        case .progress:
            progress = event.progress
        case .message:
            lastMessage = event.message
            if event.isErrorMessage { errorMessage = event.errorDescription ?? event.message }
        }

        events.append(event)
        if events.count > 100 { events.removeFirst(events.count - 100) }
    }

    private func complete(_ expected: Operation, error: RuntimeModelError?) {
        guard operation == expected else { return }
        operation = nil
        if let error { errorMessage = error.message }
        let waiters = operationWaiters
        operationWaiters.removeAll(keepingCapacity: true)
        for waiter in waiters { waiter(error) }
    }
}
