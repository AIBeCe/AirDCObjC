import AirDCObjC
import Foundation
import Testing

private final class MismatchBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ value: String) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage.isEmpty
    }
}

@Suite("Original Core build identity")
struct ADCBuildInfoTests {
    @Test("Reports the pinned original Core identity")
    func reportsCoreIdentity() {
        // Given: a framework containing the accepted original Core archive.
        let expectedCommit = "55d51ceb817ec006d4ec844d9e3788e1b0ccc352"

        // When: a Swift consumer reads the public build metadata API.
        let commit = ADCBuildInfo.coreCommit
        let version = ADCBuildInfo.coreVersion
        let build = ADCBuildInfo.coreBuildNumber
        let name = ADCBuildInfo.coreName

        // Then: the values match the accepted Dist's version.inc and Core getters.
        #expect(commit == expectedCommit)
        #expect(version == "0.0.0")
        #expect(build == 0)
        #expect(name == "AirDCCore-macOS")
    }

    @Test("Repeated concurrent reads return the same metadata")
    func concurrentReadsAreStable() {
        // Given: the immutable metadata accessors are called from concurrent consumers.
        let mismatches = MismatchBox()

        // When: many threads repeatedly read all public values.
        DispatchQueue.concurrentPerform(iterations: 64) { _ in
            let values = [
                ADCBuildInfo.coreCommit,
                ADCBuildInfo.coreVersion,
                ADCBuildInfo.coreName,
            ]
            let expected = [
                "55d51ceb817ec006d4ec844d9e3788e1b0ccc352",
                "0.0.0",
                "AirDCCore-macOS",
            ]
            if values != expected || ADCBuildInfo.coreBuildNumber != 0 {
                mismatches.append(values.joined(separator: "|"))
            }
        }

        // Then: every read is deterministic and does not initialize Core runtime.
        #expect(mismatches.isEmpty)
    }
}
