import SwiftUI
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

@main
struct AirDCExampleApp: App {
    @NSApplicationDelegateAdaptor(ExampleRuntimeTerminationDelegate.self)
    private var runtimeDelegate

    private let snapshot = BuildInfoSnapshot()

    var body: some Scene {
        WindowGroup {
            BuildInfoView(snapshot: snapshot, runtimeModel: runtimeDelegate.runtimeModel)
        }
    }
}
