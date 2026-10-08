import SwiftUI
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

struct BuildInfoView: View {
    let snapshot: BuildInfoSnapshot
    let runtimeModel: RuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snapshot.displayTitle)
                .font(.title)
            LabeledContent("Core commit", value: snapshot.coreCommit)
            LabeledContent("Build number", value: String(snapshot.coreBuildNumber))
            Text(snapshot.scopeStatus)
                .foregroundStyle(.secondary)
            RuntimeStatusView(model: runtimeModel)
        }
        .padding(24)
        .frame(minWidth: 460, alignment: .leading)
    }
}
