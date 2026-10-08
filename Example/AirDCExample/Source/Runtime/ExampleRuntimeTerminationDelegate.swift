import AppKit
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

@MainActor
final class ExampleRuntimeTerminationDelegate: NSObject, NSApplicationDelegate {
    let runtimeModel = RuntimeModel()
    private lazy var terminationCoordinator = RuntimeTerminationCoordinator(model: runtimeModel)

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let disposition = terminationCoordinator.requestTermination { shouldTerminate in
            sender.reply(toApplicationShouldTerminate: shouldTerminate)
        }
        return disposition == .allowNow ? .terminateNow : .terminateLater
    }
}
