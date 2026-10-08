import AirDCObjC
import Foundation
import Testing

@Suite("Runtime event snapshots")
struct ADCRuntimeEventTests {
    @Test("Preserves Core progress while classifying determinate values")
    func preservesRawProgress() {
        // Given: progress values from Core, including values that a UI cannot display as a determinate bar.
        let cases: [(Double, Bool)] = [
            (0, true), (0.5, true), (1, true),
            (-0.1, false), (1.1, false), (.infinity, false), (-.infinity, false), (.nan, false),
        ]

        // When: each value is copied into an immutable progress event.
        // Then: the raw value survives and only finite values in [0, 1] are determinate.
        for (progress, determinate) in cases {
            let event = ADCMakeRuntimeEvent(
                .progress,
                .running,
                nil,
                progress,
                false,
                false,
                nil
            )
            #expect(event.progress == progress || (event.progress.isNaN && progress.isNaN))
            #expect(event.isDeterminateProgress == determinate)
        }
    }

    @Test("Non-progress events carry no progress classification")
    func nonProgressEventsAreIndeterminate() {
        // Given: a message event with arbitrary progress input.
        // When: it is created through the private production event factory.
        let event = ADCMakeRuntimeEvent(.message, .running, "Connected", 0.75, false, false, nil)

        // Then: non-progress events expose the neutral progress value and remain indeterminate.
        #expect(event.progress == 0)
        #expect(!event.isDeterminateProgress)
        #expect(event.message == "Connected")
    }

    @Test("Copies event payloads and errors")
    func copiesPayloads() {
        // Given: mutable source strings and an NSError.
        let sourceMessage = NSMutableString(string: "startup")
        let sourceError = NSError(domain: "test", code: 7, userInfo: [NSLocalizedDescriptionKey: "failed"])

        // When: the event factory snapshots them, then the mutable string changes.
        let event = ADCMakeRuntimeEvent(.message, .failed, sourceMessage as String, 0, false, true, sourceError)
        sourceMessage.append(" changed")

        // Then: event values remain the values supplied at creation.
        #expect(event.message == "startup")
        #expect((event.error as NSError?)?.code == 7)
        #expect(event.errorMessage)
    }
}
