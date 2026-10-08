import Foundation
import AirDCObjC

public enum RuntimeStateSnapshot: Int, Sendable, Equatable {
    case stopped
    case starting
    case running
    case stopping
    case failed

    init(_ state: ADCRuntimeState) {
        switch state {
        case .stopped: self = .stopped
        case .starting: self = .starting
        case .running: self = .running
        case .stopping: self = .stopping
        case .failed: self = .failed
        @unknown default: self = .failed
        }
    }
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

public struct RuntimeEventSnapshot: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable {
        case state
        case step
        case progress
        case message
    }

    public let id: UInt64
    public let kind: Kind
    public let state: RuntimeStateSnapshot
    public let message: String
    public let progress: Double?
    public let isQuestion: Bool
    public let isErrorMessage: Bool
    public let errorDescription: String?
}

public struct RuntimeModelError: Error, LocalizedError, Sendable, Equatable {
    public let message: String

    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
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
final class RuntimeEventObservation {
    private var cancellation: (@MainActor () -> Void)?

    init(cancellation: @escaping @MainActor () -> Void) { self.cancellation = cancellation }

    func cancel() {
        let action = cancellation
        cancellation = nil
        action?()
    }
}

@MainActor
final class ADCRuntimeAPI: RuntimeAPI {
    private let runtime = ADCRuntime()
    private var nextEventID: UInt64 = 0

    var state: RuntimeStateSnapshot { RuntimeStateSnapshot(runtime.state) }

    func observe(_ receive: @escaping @MainActor (RuntimeEventSnapshot) -> Void) -> RuntimeEventObservation {
        let subscription = runtime.observeEvents { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                receive(self.copy(event))
            }
        }
        return RuntimeEventObservation { subscription.invalidate() }
    }

    func start(directories: RuntimeDirectories, resetUnavailableBindAddresses: Bool,
               completion: @escaping @MainActor (RuntimeModelError?) -> Void) {
        let configuration: ADCRuntimeConfiguration
        do {
            configuration = try ADCRuntimeConfiguration(
                profileDirectoryURL: directories.profileDirectoryURL,
                resourceDirectoryURL: directories.resourceDirectoryURL,
                temporaryDirectoryURL: directories.temporaryDirectoryURL
            )
        } catch {
            completion(RuntimeModelError(error.localizedDescription))
            return
        }

        runtime.start(with: configuration, resetUnavailableBindAddresses: resetUnavailableBindAddresses) { error in
            MainActor.assumeIsolated {
                completion(error.map { RuntimeModelError($0.localizedDescription) })
            }
        }
    }

    func stop(completion: @escaping @MainActor (RuntimeModelError?) -> Void) {
        runtime.stop { error in
            MainActor.assumeIsolated {
                completion(error.map { RuntimeModelError($0.localizedDescription) })
            }
        }
    }

    private func copy(_ event: ADCRuntimeEvent) -> RuntimeEventSnapshot {
        nextEventID &+= 1
        let kind: RuntimeEventSnapshot.Kind
        switch event.kind {
        case .stateChanged: kind = .state
        case .step: kind = .step
        case .progress: kind = .progress
        case .message: kind = .message
        @unknown default: kind = .message
        }

        return RuntimeEventSnapshot(
            id: nextEventID,
            kind: kind,
            state: RuntimeStateSnapshot(event.state),
            message: event.message,
            progress: event.isDeterminateProgress ? event.progress : nil,
            isQuestion: event.question,
            isErrorMessage: event.errorMessage,
            errorDescription: event.error?.localizedDescription
        )
    }
}
