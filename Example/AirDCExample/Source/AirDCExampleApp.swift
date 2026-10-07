import SwiftUI
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

@main
struct AirDCExampleApp: App {
    private let snapshot = BuildInfoSnapshot()

    var body: some Scene {
        WindowGroup {
            BuildInfoView(snapshot: snapshot)
        }
    }
}
