import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import AirDCExampleModel
#endif

struct RuntimeStatusView: View {
    @ObservedObject var model: RuntimeModel

    @State private var profilePath: String
    @State private var resourcePath = ""
    @State private var temporaryPath: String
    @State private var resetUnavailableBindAddresses = false

    init(model: RuntimeModel) {
        self.model = model
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AirDCExample", isDirectory: true)
        _profilePath = State(initialValue: base.appendingPathComponent("Profile", isDirectory: true).path)
        _temporaryPath = State(initialValue: base.appendingPathComponent("Temporary", isDirectory: true).path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Core runtime")
                .font(.headline)

            LabeledContent("State", value: model.state.title)
            TextField("Isolated profile directory", text: $profilePath)
            HStack {
                TextField("Core resource directory (required)", text: $resourcePath)
                Button("Choose…", action: chooseResourceDirectory)
            }
            TextField("Isolated temporary directory", text: $temporaryPath)
            Toggle("Reset unavailable bind addresses on startup", isOn: $resetUnavailableBindAddresses)

            HStack {
                Button("Start") { startRuntime() }
                    .disabled(!model.canStart || resourcePath.isEmpty)
                Button("Stop") { model.stop() }
                    .disabled(!model.canStop)
                if model.isStarting || model.isStopping {
                    ProgressView().controlSize(.small)
                }
            }

            if let step = model.currentStep { LabeledContent("Current step", value: step) }
            if let progress = model.progress {
                ProgressView(value: progress)
                Text("Core progress: \(progress, format: .percent.precision(.fractionLength(0...1)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if model.isStarting || model.isStopping {
                ProgressView()
            }
            if let message = model.lastMessage { Text(message).textSelection(.enabled) }
            if let error = model.errorMessage {
                Text(error).foregroundStyle(.red).textSelection(.enabled)
            }

            if !model.events.isEmpty {
                Divider()
                Text("Recent runtime events").font(.subheadline)
                ForEach(model.events.suffix(8)) { event in
                    let prefix = event.isQuestion ? "Question: " : (event.isErrorMessage ? "Error: " : "")
                    Text(prefix + (event.message.isEmpty ? event.kind.title : event.message))
                        .font(.caption)
                        .foregroundStyle(event.isErrorMessage ? .red : .secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding(.top, 12)
    }

    private func chooseResourceDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Select the Core resource directory"
        panel.prompt = "Use Resources"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            resourcePath = url.path
        }
    }

    private func startRuntime() {
        let directories = RuntimeDirectories(
            profileDirectoryURL: URL(fileURLWithPath: profilePath, isDirectory: true),
            resourceDirectoryURL: URL(fileURLWithPath: resourcePath, isDirectory: true),
            temporaryDirectoryURL: URL(fileURLWithPath: temporaryPath, isDirectory: true)
        )
        model.start(directories: directories, resetUnavailableBindAddresses: resetUnavailableBindAddresses)
    }
}

private extension RuntimeStateSnapshot {
    var title: String {
        switch self {
        case .stopped: "Stopped"
        case .starting: "Starting"
        case .running: "Running"
        case .stopping: "Stopping"
        case .failed: "Failed"
        }
    }
}

private extension RuntimeEventSnapshot.Kind {
    var title: String {
        switch self {
        case .state: "State changed"
        case .step: "Startup/shutdown step"
        case .progress: "Progress"
        case .message: "Message"
        }
    }
}
