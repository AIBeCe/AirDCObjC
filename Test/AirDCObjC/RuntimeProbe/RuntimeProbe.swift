import AirDCObjC
import Dispatch
import Foundation

private final class ErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Error?

    var value: Error? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

private func writeLine(_ value: String) {
    FileHandle.standardOutput.write(Data((value + "\n").utf8))
}

private func writeRuntimeEvent(_ event: ADCRuntimeEvent) {
    if event.question {
        writeLine("QUESTION reset-choice=\(event.message)")
    }
    if event.kind == .stateChanged {
        writeLine("STATE \(event.state.rawValue)")
    }
}

private func makeConfiguration(_ paths: ArraySlice<String>) throws -> ADCRuntimeConfiguration {
    guard paths.count == 3 else { throw NSError(domain: "RuntimeProbe", code: 2) }
    let values = Array(paths)
    return try ADCRuntimeConfiguration(
        profileDirectoryURL: URL(fileURLWithPath: values[0], isDirectory: true),
        resourceDirectoryURL: URL(fileURLWithPath: values[1], isDirectory: true),
        temporaryDirectoryURL: URL(fileURLWithPath: values[2], isDirectory: true)
    )
}

private func waitFor<T>(_ start: (@escaping @Sendable (T) -> Void) -> Void) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ValueBox<T>()
    start { value in
        box.value = value
        semaphore.signal()
    }
    guard semaphore.wait(timeout: .now() + 45) == .success, let value = box.value else {
        writeLine("TIMEOUT")
        exit(10)
    }
    return value
}

private final class ValueBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T?

    var value: T? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

private func start(_ runtime: ADCRuntime, _ configuration: ADCRuntimeConfiguration, reset: Bool) -> Error? {
    waitFor { completion in
        runtime.start(with: configuration, resetUnavailableBindAddresses: reset, completion: completion)
    }
}

private func stop(_ runtime: ADCRuntime) -> Error? {
    waitFor { completion in runtime.stop(completion: completion) }
}

@main
private struct RuntimeProbe {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            writeLine("MISSING_MODE")
            exit(2)
        }

        if mode == "--repair-preflight" {
            runPreflightRetry(arguments.dropFirst())
            return
        }
        if mode == "--hash-failure-retry" {
            runHashFailureRetry(arguments.dropFirst())
            return
        }
        if mode == "--restart" {
            runProfileRestart(arguments.dropFirst())
            return
        }
        if mode == "--cleanup-failure-hold" {
            runCleanupFailureHold(arguments.dropFirst())
            return
        }
        if mode == "--two-runtimes" {
            runTwoRuntimes(arguments.dropFirst())
            return
        }

        let isHold = mode == "--hold"
        let pathArguments = isHold ? arguments.dropFirst().prefix(3) : arguments.dropFirst().prefix(3)
        do {
            let configuration = try makeConfiguration(pathArguments)
            let runtime = ADCRuntime(deliveryQueue: DispatchQueue(label: "org.airdcpp.RuntimeProbe.delivery"))
            let subscription = runtime.observeEvents(writeRuntimeEvent)
            let reset = arguments.last == "--reset-bind"
            if let error = start(runtime, configuration, reset: reset) {
                let nsError = error as NSError
                writeLine("START_ERROR \(nsError.code) \(nsError.localizedDescription)")
                exit(0)
            }
            writeLine("START_OK unclean=\(runtime.uncleanShutdownDetected ? 1 : 0)")

            if isHold {
                writeLine("READY")
                if readLine() == "STOP" {
                    if let error = stop(runtime) {
                        let nsError = error as NSError
                        writeLine("STOP_ERROR \(nsError.code) \(nsError.localizedDescription)")
                        if readLine() == "EXIT" { exit(0) }
                    } else {
                        writeLine("STOP_OK")
                    }
                }
            } else if let error = stop(runtime) {
                let nsError = error as NSError
                writeLine("STOP_ERROR \(nsError.code) \(nsError.localizedDescription)")
                exit(0)
            } else {
                writeLine("STOP_OK")
            }
            subscription.invalidate()
        } catch {
            writeLine("CONFIG_ERROR \((error as NSError).code) \(error.localizedDescription)")
            exit(0)
        }
    }

    private static func runPreflightRetry(_ arguments: ArraySlice<String>) {
        guard arguments.count == 4 else { writeLine("ARGUMENT_ERROR"); exit(2) }
        let values = Array(arguments)
        let blocked = URL(fileURLWithPath: values[0], isDirectory: true)
        let resources = URL(fileURLWithPath: values[1], isDirectory: true)
        let temporary = URL(fileURLWithPath: values[2], isDirectory: true)
        let repairMarker = URL(fileURLWithPath: values[3])
        do {
            if FileManager.default.fileExists(atPath: blocked.path) {
                try FileManager.default.removeItem(at: blocked)
            }
            try Data("blocked".utf8).write(to: blocked)
            let runtime = ADCRuntime(deliveryQueue: DispatchQueue(label: "org.airdcpp.RuntimeProbe.delivery"))
            let bad = try ADCRuntimeConfiguration(profileDirectoryURL: blocked, resourceDirectoryURL: resources, temporaryDirectoryURL: temporary)
            guard let error = start(runtime, bad, reset: false), (error as NSError).code == 1 else {
                writeLine("EXPECTED_PREFLIGHT_ERROR")
                exit(1)
            }
            guard runtime.state == .stopped else { writeLine("PREFLIGHT_STATE_ERROR"); exit(1) }
            try FileManager.default.removeItem(at: blocked)
            try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
            try Data("retry".utf8).write(to: repairMarker)
            let good = try ADCRuntimeConfiguration(profileDirectoryURL: blocked, resourceDirectoryURL: resources, temporaryDirectoryURL: temporary)
            guard start(runtime, good, reset: false) == nil, stop(runtime) == nil else {
                writeLine("RETRY_FAILED")
                exit(1)
            }
            writeLine("RETRY_OK")
        } catch {
            writeLine("PREFLIGHT_FIXTURE_ERROR \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func runHashFailureRetry(_ arguments: ArraySlice<String>) {
        do {
            let configuration = try makeConfiguration(arguments.prefix(3))
            let runtime = ADCRuntime(deliveryQueue: DispatchQueue(label: "org.airdcpp.RuntimeProbe.hash-retry"))
            guard let error = start(runtime, configuration, reset: false),
                  (error as NSError).code == 5,
                  runtime.state == .stopped,
                  runtime.uncleanShutdownDetected else {
                writeLine("HASH_FAILURE_STATE_ERROR \(runtime.uncleanShutdownDetected ? 1 : 0)")
                exit(1)
            }
            writeLine("HASH_FAILURE_UNCLEAN 1")
            guard readLine() == "RETRY" else { writeLine("HASH_RETRY_SIGNAL_ERROR"); exit(1) }
            guard start(runtime, configuration, reset: false) == nil,
                  runtime.uncleanShutdownDetected,
                  stop(runtime) == nil else {
                writeLine("HASH_RETRY_FAILED \(runtime.uncleanShutdownDetected ? 1 : 0)")
                exit(1)
            }
            writeLine("HASH_RETRY_UNCLEAN 1")
        } catch {
            writeLine("HASH_RETRY_FIXTURE_ERROR \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func runProfileRestart(_ arguments: ArraySlice<String>) {
        guard arguments.count == 6 else { writeLine("ARGUMENT_ERROR"); exit(2) }
        let values = Array(arguments)
        do {
            let first = try makeConfiguration(values[0...2])
            let second = try makeConfiguration(values[3...5])
            let runtime = ADCRuntime(deliveryQueue: DispatchQueue(label: "org.airdcpp.RuntimeProbe.delivery"))
            guard stop(runtime) == nil, start(runtime, first, reset: false) == nil else {
                writeLine("PROFILE_RESTART_FAILED")
                exit(1)
            }
            let firstUnclean = runtime.uncleanShutdownDetected
            guard stop(runtime) == nil, start(runtime, second, reset: false) == nil else {
                writeLine("PROFILE_RESTART_FAILED")
                exit(1)
            }
            let secondUnclean = runtime.uncleanShutdownDetected
            guard stop(runtime) == nil else { writeLine("PROFILE_RESTART_FAILED"); exit(1) }
            writeLine("UNCLEAN \(firstUnclean ? 1 : 0),\(secondUnclean ? 1 : 0)")
            writeLine("PROFILE_RESTART_OK")
        } catch {
            writeLine("PROFILE_CONFIG_ERROR \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func runTwoRuntimes(_ arguments: ArraySlice<String>) {
        do {
            let configuration = try makeConfiguration(arguments.prefix(3))
            let delivery1 = DispatchQueue(label: "org.airdcpp.RuntimeProbe.first")
            let delivery2 = DispatchQueue(label: "org.airdcpp.RuntimeProbe.second")
            let first = ADCRuntime(deliveryQueue: delivery1)
            let second = ADCRuntime(deliveryQueue: delivery2)
            let firstDone = DispatchSemaphore(value: 0)
            let firstError = ErrorBox()
            first.start(with: configuration, resetUnavailableBindAddresses: false) { error in
                firstError.value = error
                firstDone.signal()
            }
            let sameRuntimeError = start(first, configuration, reset: false)
            let secondError = start(second, configuration, reset: false)
            guard (sameRuntimeError as NSError?)?.code == 2,
                  (secondError as NSError?)?.code == 2 else { writeLine("EXPECTED_BUSY"); exit(1) }
            guard firstDone.wait(timeout: .now() + 45) == .success, firstError.value == nil,
                  stop(first) == nil else { writeLine("TWO_RUNTIME_CLEANUP_FAILED"); exit(1) }
            writeLine("SECOND_BUSY_FIRST_OK")
        } catch {
            writeLine("TWO_RUNTIME_CONFIG_ERROR \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func runCleanupFailureHold(_ arguments: ArraySlice<String>) {
        do {
            let configuration = try makeConfiguration(arguments.prefix(3))
            let runtime = ADCRuntime(deliveryQueue: DispatchQueue(label: "org.airdcpp.RuntimeProbe.cleanup"))
            guard start(runtime, configuration, reset: false) == nil else {
                writeLine("CLEANUP_SETUP_FAILED")
                exit(1)
            }
            let marker = configuration.profileDirectoryURL.appendingPathComponent("RUNNING")
            try FileManager.default.removeItem(at: marker)
            try FileManager.default.createDirectory(at: marker, withIntermediateDirectories: false)
            try Data("preserve".utf8).write(to: marker.appendingPathComponent("sentinel"))
            guard let error = stop(runtime), (error as NSError).code == 7,
                  runtime.state == .failed else {
                writeLine("EXPECTED_CLEANUP_FAILURE")
                exit(1)
            }
            writeLine("CLEANUP_FAILED_READY")
            if readLine() == "EXIT" { writeLine("CLEANUP_OWNER_EXITING"); exit(0) }
            writeLine("CLEANUP_EXIT_TIMEOUT")
            exit(1)
        } catch {
            writeLine("CLEANUP_CONFIG_ERROR \(error.localizedDescription)")
            exit(1)
        }
    }

}
