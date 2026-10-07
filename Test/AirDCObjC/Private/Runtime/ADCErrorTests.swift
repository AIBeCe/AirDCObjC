import AirDCObjC
import Foundation
import Testing

@Suite("Objective-C bridge errors")
struct ADCErrorTests {
    @Test("Publishes the stable error domain")
    func stableErrorDomain() {
        // Given: the Objective-C bridge error domain imported into Swift.
        // When: the domain is inspected.
        // Then: it has the stable framework identifier.
        #expect(ADCErrorDomain as String == "org.airdcpp.AirDCObjC")
    }
}
