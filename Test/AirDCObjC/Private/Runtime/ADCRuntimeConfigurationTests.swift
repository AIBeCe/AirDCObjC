import AirDCObjC
import Foundation
import Testing

@Suite("Immutable runtime configuration")
struct ADCRuntimeConfigurationTests {
    @Test("Standardizes valid directory URLs without creating them")
    func standardizesWithoutFilesystemEffects() throws {
        // Given: three not-yet-created directory paths containing redundant components.
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ADCRuntimeConfigurationTests-\(UUID().uuidString)", isDirectory: true)
        let profile = root.appendingPathComponent("profile/../profile", isDirectory: true)
        let resources = root.appendingPathComponent("resources/.", isDirectory: true)
        let temporary = root.appendingPathComponent("temporary", isDirectory: true)

        // When: an immutable configuration and its copy are created.
        let configuration = try ADCRuntimeConfiguration(
            profileDirectoryURL: profile,
            resourceDirectoryURL: resources,
            temporaryDirectoryURL: temporary
        )
        let copied = configuration.copy() as! ADCRuntimeConfiguration

        // Then: the values are standardized, immutable, and no directory is created.
        #expect(configuration.profileDirectoryURL == profile.standardizedFileURL)
        #expect(configuration.resourceDirectoryURL == resources.standardizedFileURL)
        #expect(configuration.temporaryDirectoryURL == temporary.standardizedFileURL)
        #expect(copied === configuration)
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    @Test("Rejects URLs that are not absolute local file directory URLs")
    func rejectsInvalidURLs() {
        // Given: invalid URL forms, including remote file hosts, query/fragment, empty path, and NUL.
        let valid = URL(fileURLWithPath: "/tmp/airdcpp-profile", isDirectory: true)
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ADCRuntimeConfigurationInvalid-\(UUID().uuidString)", isDirectory: true)
        let invalidURLs = [
            URL(string: "https://example.invalid/profile")!,
            URL(string: "file://example.invalid\(root.path)")!,
            URL(string: "file:")!,
            URL(string: "file://\(root.path)?mode=1")!,
            URL(string: "file://\(root.path)#fragment")!,
            URL(string: "file://\(root.path)%00suffix")!,
        ]

        // When: each invalid value occupies one required configuration slot.
        // Then: construction returns the stable invalid-configuration error and never creates paths.
        for invalid in invalidURLs {
            do {
                _ = try ADCRuntimeConfiguration(
                    profileDirectoryURL: invalid,
                    resourceDirectoryURL: valid,
                    temporaryDirectoryURL: valid
                )
                Issue.record("Expected rejection for URL: \(invalid)")
            } catch let error as NSError {
                #expect(error.domain == ADCErrorDomain as String)
                #expect(error.code == 1)
            }
        }
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    @Test("Accepts localhost file URLs")
    func acceptsLocalhostFileURL() throws {
        // Given: a file URL using the explicitly permitted localhost host.
        let local = URL(string: "file://localhost/tmp/airdcpp-profile")!

        // When: it is used for all configuration directories.
        let configuration = try ADCRuntimeConfiguration(
            profileDirectoryURL: local,
            resourceDirectoryURL: local,
            temporaryDirectoryURL: local
        )

        // Then: its standardized local file path is retained.
        #expect(configuration.profileDirectoryURL.path == "/tmp/airdcpp-profile")
    }
}
