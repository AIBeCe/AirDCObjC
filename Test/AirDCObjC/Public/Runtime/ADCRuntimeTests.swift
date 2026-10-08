import AirDCObjC
import Dispatch
import Darwin
import Foundation
import Testing

@Suite("Public Core runtime subprocess", .serialized)
struct ADCRuntimeTests {
    @Test("Starts, stops, then restarts with a different isolated profile")
    func startStopAndChangeProfile() throws {
        // Given: separate profile, resource, and temporary directories for two runtime starts.
        let first = try Layout()
        let second = try Layout()
        try Data("previous process left this marker".utf8).write(to: first.profile.appendingPathComponent("RUNNING"))
        let probe = try runtimeProbeURL()

        // When: a child starts and stops the same runtime with the first profile, then reuses it with the second.
        let result = try runProbe(probe, ["--restart"] + first.arguments + second.arguments)

        // Then: both cycles complete and each profile has a clean Core running marker.
        #expect(result.status == 0)
        #expect(result.output.contains("PROFILE_RESTART_OK"))
        #expect(result.output.contains("UNCLEAN 1,1"))
        #expect(!FileManager.default.fileExists(atPath: first.profile.appendingPathComponent("RUNNING").path))
        #expect(!FileManager.default.fileExists(atPath: second.profile.appendingPathComponent("RUNNING").path))
    }

    @Test("A second process cannot claim an active profile")
    func crossProcessProfileLock() throws {
        // Given: one child owns a started runtime and reports an explicit readiness line.
        let layout = try Layout()
        let probe = try runtimeProbeURL()
        let holder = try launchProbe(probe, ["--hold"] + layout.arguments)
        defer { holder.terminateIfRunning() }
        #expect(try holder.readUntil("READY", timeout: 45) == "READY")

        // When: another process attempts the same profile while the first remains active.
        let collision = try runProbe(probe, ["--start-stop"] + layout.arguments)

        // Then: startup reports profile ownership conflict; the original owner then stops cleanly.
        #expect(collision.status == 0)
        #expect(collision.output.contains("START_ERROR 4"))
        holder.send("STOP")
        #expect(try holder.readUntil("STOP_OK", timeout: 45) == "STOP_OK")
        holder.finish()
        #expect(!FileManager.default.fileExists(atPath: layout.profile.appendingPathComponent("RUNNING").path))
    }

    @Test("The host choice for an unavailable bind address is reported and applied")
    func unavailableBindAddressUsesExplicitChoice() throws {
        let preserve = try Layout()
        let reset = try Layout()
        for layout in [preserve, reset] {
            let settings = layout.profile.appendingPathComponent("DCPlusPlus.xml")
            try Data("<DCPlusPlus><Settings><BindAddress>192.0.2.123</BindAddress></Settings></DCPlusPlus>".utf8)
                .write(to: settings)
        }
        let probe = try runtimeProbeURL()

        // When: false preserves the configured invalid address, while true accepts Core's reset question.
        let keepResult = try runProbe(probe, ["--start-stop"] + preserve.arguments)
        let resetResult = try runProbe(probe, ["--start-stop"] + reset.arguments + ["--reset-bind"])

        // Then: both decisions are surfaced as questions and the true choice clears the unavailable setting.
        #expect(keepResult.output.contains("QUESTION reset-choice="))
        #expect(resetResult.output.contains("QUESTION reset-choice="))
        #expect(try String(contentsOf: preserve.profile.appendingPathComponent("DCPlusPlus.xml"), encoding: .utf8)
            .contains("192.0.2.123"))
        #expect(!(try String(contentsOf: reset.profile.appendingPathComponent("DCPlusPlus.xml"), encoding: .utf8)
            .contains("192.0.2.123")))
    }

    @Test("Failed cleanup retains the profile lock until the owning process exits")
    func failedCleanupRetainsOwnerAndProfileLock() throws {
        let layout = try Layout()
        let probe = try runtimeProbeURL()
        let holder = try launchProbe(probe, ["--cleanup-failure-hold"] + layout.arguments)
        defer { holder.terminateIfRunning() }
        #expect(try holder.readUntil("CLEANUP_FAILED_READY", timeout: 60) == "CLEANUP_FAILED_READY")

        // When: another child starts against the profile after the Core owner reports unsafe cleanup.
        let collision = try runProbe(probe, ["--start-stop"] + layout.arguments)

        // Then: the profile stays locked until the failed owner exits, after which the same profile can recover.
        #expect(collision.output.contains("START_ERROR 4"))
        holder.send("EXIT")
        holder.finish()
        try FileManager.default.removeItem(at: layout.profile.appendingPathComponent("RUNNING"))
        let retry = try runProbe(probe, ["--start-stop"] + layout.arguments)
        #expect(retry.output.contains("START_OK"))
        #expect(retry.output.contains("STOP_OK"))
    }

    @Test("Preflight errors leave the runtime reusable")
    func preflightFailureCanRetry() throws {
        // Given: valid resources/temp roots and a regular file where the profile directory should be.
        let layout = try Layout()
        let marker = layout.root.appendingPathComponent("retry-marker")
        let probe = try runtimeProbeURL()

        // When: the child observes the invalid profile and then replaces it with a directory.
        let result = try runProbe(probe, ["--repair-preflight", layout.profile.path, layout.resources.path,
                                          layout.temporary.path, marker.path])

        // Then: validation fails before Core starts and the same object succeeds on the corrected path.
        #expect(result.status == 0)
        #expect(result.output.contains("RETRY_OK"))
        #expect(!FileManager.default.fileExists(atPath: layout.profile.appendingPathComponent("RUNNING").path))
    }

    @Test("Rejects a bootstrap override without consuming it and allows retry after removal")
    func bootstrapOverrideIsPreservedAndRetryable() throws {
        let layout = try Layout()
        let bootstrap = layout.profile.appendingPathComponent(".airdcpp-runtime", isDirectory: true)
        try FileManager.default.createDirectory(at: bootstrap, withIntermediateDirectories: true)
        let override = bootstrap.appendingPathComponent("dcppboot.xml.user")
        let bytes = Data("<Boot><ConfigPath>/outside/profile</ConfigPath></Boot>".utf8)
        try bytes.write(to: override)
        let probe = try runtimeProbeURL()

        // When: Core startup encounters the framework bootstrap override path.
        let failed = try runProbe(probe, ["--start-stop"] + layout.arguments)

        // Then: preflight rejects before Core starts and leaves the override and profile untouched.
        #expect(failed.status == 0)
        #expect(failed.output.contains("START_ERROR 1"))
        #expect(try Data(contentsOf: override) == bytes)
        #expect(!FileManager.default.fileExists(atPath: layout.profile.appendingPathComponent("RUNNING").path))
        #expect(!FileManager.default.fileExists(atPath: layout.profile.appendingPathComponent("DCPlusPlus.xml").path))

        // When: the host removes its own override and retries with the same isolated profile.
        try FileManager.default.removeItem(at: override)
        let retry = try runProbe(probe, ["--start-stop"] + layout.arguments)

        // Then: the repaired profile starts and stops cleanly.
        #expect(retry.output.contains("START_OK"))
        #expect(retry.output.contains("STOP_OK"))
    }

    @Test("A failed HashData open cleans up without overwriting existing profile sentinels")
    func failedHashOpenPreservesDataAndReleasesProfile() throws {
        // Given: valid sentinel XML plus a regular file blocking the HashData directory.
        let layout = try Layout()
        let settings = layout.profile.appendingPathComponent("DCPlusPlus.xml")
        let favorites = layout.profile.appendingPathComponent("Favorites.xml")
        let queue = layout.profile.appendingPathComponent("Queue.xml")
        let settingsBytes = Data("<DCPlusPlus><Settings><Nick>sentinel</Nick></Settings></DCPlusPlus>".utf8)
        let favoritesBytes = Data("<Favorites><FavoriteHub Name=\"sentinel\"/></Favorites>".utf8)
        let queueBytes = Data("<Downloads><Download Target=\"sentinel\"/></Downloads>".utf8)
        try settingsBytes.write(to: settings)
        try favoritesBytes.write(to: favorites)
        try queueBytes.write(to: queue)
        try Data("not a directory".utf8).write(to: layout.profile.appendingPathComponent("HashData"))
        try Data("prior interrupted run".utf8).write(to: layout.profile.appendingPathComponent("RUNNING"))
        let probe = try runtimeProbeURL()

        // When: Core startup observes the prior marker, then HashData open fails and guarded cleanup runs.
        let child = try launchProbe(probe, ["--hash-failure-retry"] + layout.arguments)
        defer { child.terminateIfRunning() }
        #expect(try child.readUntil("HASH_FAILURE_UNCLEAN 1", timeout: 60) == "HASH_FAILURE_UNCLEAN 1")

        // Then: failure cleanup reports sticky unclean state and preserves all sentinels before retry.
        #expect(try Data(contentsOf: settings) == settingsBytes)
        #expect(try Data(contentsOf: favorites) == favoritesBytes)
        #expect(try Data(contentsOf: queue) == queueBytes)
        #expect(!FileManager.default.fileExists(atPath: layout.profile.appendingPathComponent("RUNNING").path))

        // When: the host repairs HashData and the same runtime retries in the same process.
        try FileManager.default.removeItem(at: layout.profile.appendingPathComponent("HashData"))
        child.send("RETRY")

        // Then: the clean retry succeeds while Core's process-global unclean flag remains true.
        #expect(try child.readUntil("HASH_RETRY_UNCLEAN 1", timeout: 60) == "HASH_RETRY_UNCLEAN 1")
        #expect(child.finish() == 0)
    }

    @Test("A process-wide runtime owner rejects a second in-process object")
    func oneRuntimeOwnsCorePerProcess() throws {
        // Given: two public runtime objects in one child process.
        let layout = try Layout()
        let probe = try runtimeProbeURL()

        // When: the first starts and the second requests the same configuration before the first stops.
        let result = try runProbe(probe, ["--two-runtimes"] + layout.arguments)

        // Then: the second receives the stable busy error and the first remains able to stop.
        #expect(result.status == 0)
        #expect(result.output.contains("SECOND_BUSY_FIRST_OK"))
    }

    @Test("Probe pipe readers return partial lines and enforce silence deadlines")
    func probePipeReaderIsBounded() throws {
        let executable = URL(fileURLWithPath: "/bin/sleep")
        let child = try launchProbe(executable, ["5"])
        defer { child.terminateIfRunning() }
        let started = ProcessInfo.processInfo.systemUptime
        #expect(try child.readUntil("READY", timeout: 0.1) == nil)
        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
    }
}

private struct Layout {
    let root: URL
    let profile: URL
    let resources: URL
    let temporary: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("ADCRuntimePublicTests-\(UUID().uuidString)", isDirectory: true)
        profile = root.appendingPathComponent("profile", isDirectory: true)
        resources = root.appendingPathComponent("resources", isDirectory: true)
        temporary = root.appendingPathComponent("temporary", isDirectory: true)
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
    }

    var arguments: [String] { [profile.path, resources.path, temporary.path] }
}

private struct ProbeResult {
    let status: Int32
    let output: String
}

private func runtimeProbeURL() throws -> URL {
    guard let path = ProcessInfo.processInfo.environment["AIRDC_RUNTIME_PROBE_PATH"],
          FileManager.default.isExecutableFile(atPath: path) else {
        throw NSError(domain: "ADCRuntimeTests", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "AIRDC_RUNTIME_PROBE_PATH must name the built runtime probe"])
    }
    return URL(fileURLWithPath: path)
}

private func runProbe(_ executable: URL, _ arguments: [String]) throws -> ProbeResult {
    let child = try launchProbe(executable, arguments)
    let status = child.waitForExit(timeout: 90)
    let output = child.collectOutput()
    return ProbeResult(status: status, output: output)
}

private final class ProbeChild {
    private let process: Process
    private let outputPipe: Pipe
    private let inputPipe: Pipe
    private let exited: DispatchSemaphore
    private var outputBuffer = Data()
    private let lock = NSLock()

    init(process: Process, outputPipe: Pipe, inputPipe: Pipe, exited: DispatchSemaphore) {
        self.process = process
        self.outputPipe = outputPipe
        self.inputPipe = inputPipe
        self.exited = exited
    }

    func readLine(timeout: TimeInterval) throws -> String? {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while ProcessInfo.processInfo.systemUptime < deadline {
            if let line = takeLine() { return line }
            if !process.isRunning { return takeLine() }
            let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime)
            var readiness = pollfd(fd: outputPipe.fileHandleForReading.fileDescriptor,
                                   events: Int16(POLLIN | POLLHUP), revents: 0)
            let milliseconds = Int32(min(Double(Int32.max), ceil(remaining * 1000)))
            let ready = Darwin.poll(&readiness, 1, milliseconds)
            if ready == 0 { return nil }
            if ready < 0 {
                if errno == EINTR { continue }
                return nil
            }
            var bytes = [UInt8](repeating: 0, count: 4096)
            let count = bytes.withUnsafeMutableBytes { buffer in
                Darwin.read(outputPipe.fileHandleForReading.fileDescriptor, buffer.baseAddress, buffer.count)
            }
            if count > 0 {
                lock.withLock { outputBuffer.append(contentsOf: bytes.prefix(count)) }
            } else if count == 0 {
                return takeLine()
            } else if errno != EINTR {
                return nil
            }
        }
        return nil
    }

    func readUntil(_ expected: String, timeout: TimeInterval) throws -> String? {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while ProcessInfo.processInfo.systemUptime < deadline {
            let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime)
            if let line = try readLine(timeout: remaining), line == expected {
                return line
            }
        }
        return nil
    }

    func send(_ line: String) {
        inputPipe.fileHandleForWriting.write(Data((line + "\n").utf8))
    }

    func finish() -> Int32 { waitForExit(timeout: 45) }

    func terminateIfRunning() {
        guard process.isRunning else { return }
        process.terminate()
        if exited.wait(timeout: .now() + 2) != .success {
            _ = Darwin.kill(process.processIdentifier, SIGKILL)
            _ = exited.wait(timeout: .now() + 2)
        }
    }

    func collectOutput() -> String {
        let remainder = outputPipe.fileHandleForReading.readDataToEndOfFile()
        lock.withLock { outputBuffer.append(remainder) }
        return String(decoding: outputBuffer, as: UTF8.self)
    }

    func waitForExit(timeout: TimeInterval) -> Int32 {
        if !process.isRunning { return process.terminationStatus }
        guard exited.wait(timeout: .now() + timeout) == .success else {
            process.terminate()
            if exited.wait(timeout: .now() + 2) != .success {
                _ = Darwin.kill(process.processIdentifier, SIGKILL)
                _ = exited.wait(timeout: .now() + 2)
            }
            return -1
        }
        return process.terminationStatus
    }

    private func takeLine() -> String? {
        lock.withLock {
            guard let newline = outputBuffer.firstIndex(of: 10) else { return nil }
            let line = outputBuffer[..<newline]
            outputBuffer.removeSubrange(...newline)
            return String(decoding: line, as: UTF8.self)
        }
    }
}

private func launchProbe(_ executable: URL, _ arguments: [String]) throws -> ProbeChild {
    let process = Process()
    let output = Pipe()
    let input = Pipe()
    process.executableURL = executable
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = output
    process.standardInput = input
    let exited = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in exited.signal() }
    try process.run()
    return ProbeChild(process: process, outputPipe: output, inputPipe: input, exited: exited)
}
