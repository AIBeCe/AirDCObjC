import Foundation
import Testing

@Suite("Core runtime operation admission", .serialized)
struct ADCRuntimeTests {
    @Test("Drains admitted work, rejects after stop, and recovers from an operation exception")
    func admittedOperationsDrainBeforeStop() throws {
        // Given: a disposable Core profile and the test-only probe that can submit private Core work.
        guard let executablePath = ProcessInfo.processInfo.environment["AIRDC_PRIVATE_RUNTIME_PROBE_PATH"],
              FileManager.default.isExecutableFile(atPath: executablePath) else {
            Issue.record("AIRDC_PRIVATE_RUNTIME_PROBE_PATH must name the built private runtime probe")
            return
        }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ADCRuntimeOperationTests-\(UUID().uuidString)", isDirectory: true)
        let profile = root.appendingPathComponent("profile", isDirectory: true)
        let resources = root.appendingPathComponent("resources", isDirectory: true)
        let temporary = root.appendingPathComponent("temporary", isDirectory: true)
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = [profile.path, resources.path, temporary.path]
        process.standardOutput = output
        process.standardError = output
        let terminated = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in terminated.signal() }

        // When: accepted Core work throws and recovers, then stop queues behind a blocked operation.
        try process.run()
        let didExit = terminated.wait(timeout: .now() + 120) == .success
        if !didExit, process.isRunning { process.terminate() }
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        // Then: copied operation completion precedes stop completion, later work is rejected, and no task is lost.
        #expect(didExit)
        #expect(process.terminationStatus == 0)
        #expect(text.contains("OPERATION_CONTRACT_OK"))
        #expect(text.contains("throw-caught"))
        #expect(text.contains("next-next-operation-ok"))
    }
}
