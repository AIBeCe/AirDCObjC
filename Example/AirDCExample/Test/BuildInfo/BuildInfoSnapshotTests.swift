import Testing
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

@Suite("Example build information snapshot")
struct BuildInfoSnapshotTests {
    @Test("Displays the immutable original Core values")
    func displaysCoreIdentity() {
        // Given: the native example creates its public-framework value snapshot.
        let snapshot = BuildInfoSnapshot()

        // When: the app derives its display title from that snapshot.
        let title = snapshot.displayTitle

        // Then: both stored values and presentation match the real Core metadata.
        #expect(snapshot.coreCommit == "55d51ceb817ec006d4ec844d9e3788e1b0ccc352")
        #expect(snapshot.coreVersion == "0.0.0")
        #expect(snapshot.coreBuildNumber == 0)
        #expect(snapshot.coreName == "AirDCCore-macOS")
        #expect(title == "AirDCCore-macOS 0.0.0")
    }

    @Test("Labels the UI as an integration proof")
    func labelsScope() {
        // Given: the minimal Phase 1 example snapshot.
        let snapshot = BuildInfoSnapshot()

        // When: the UI asks for its scope label.
        // Then: the app does not imply that runtime lifecycle is implemented.
        #expect(snapshot.scopeStatus.contains("Phase 1"))
        #expect(snapshot.scopeStatus.contains("proof"))
    }
}
