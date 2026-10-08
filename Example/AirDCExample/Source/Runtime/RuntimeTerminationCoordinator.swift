import Foundation

@MainActor
public final class RuntimeTerminationCoordinator {
    public enum Disposition: Sendable, Equatable { case allowNow, later }

    private let model: RuntimeModel
    private var isHandlingTermination = false
    private var replies: [@MainActor (Bool) -> Void] = []

    public init(model: RuntimeModel) { self.model = model }

    public func requestTermination(reply: @escaping @MainActor (Bool) -> Void) -> Disposition {
        guard model.isStarting || model.isStopping || model.state == .running else {
            model.cancelObservation()
            return .allowNow
        }

        replies.append(reply)
        guard !isHandlingTermination else { return .later }
        isHandlingTermination = true

        if model.isStarting {
            model.afterCurrentOperation { [weak self] error in
                guard let self else { return }
                if error != nil {
                    self.finish()
                } else {
                    self.stopIfRunningOrFinish()
                }
            }
        } else if model.isStopping {
            model.afterCurrentOperation { [weak self] _ in self?.finish() }
        } else {
            stopIfRunningOrFinish()
        }

        return .later
    }

    private func stopIfRunningOrFinish() {
        if model.state == .running {
            model.stop()
            model.afterCurrentOperation { [weak self] _ in self?.finish() }
        } else {
            finish()
        }
    }

    private func finish() {
        model.cancelObservation()
        let pending = replies
        replies.removeAll(keepingCapacity: true)
        isHandlingTermination = false
        for reply in pending { reply(true) }
    }
}
