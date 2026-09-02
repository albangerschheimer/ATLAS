import OSLog
import SwiftData
import SwiftUI

struct AppFailure: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let canRetry: Bool
}

@MainActor
final class AppFeedback: ObservableObject {
    @Published var failure: AppFailure?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ATLAS",
        category: "Data"
    )
    private var retryAction: (() -> Void)?

    @discardableResult
    func save(
        _ context: ModelContext,
        action: String,
        onSuccess: @escaping () -> Void = {}
    ) -> Bool {
        run(action: action, operation: {
            try context.save()
        }, onSuccess: onSuccess)
    }

    @discardableResult
    func run(
        action: String,
        operation: @escaping () throws -> Void,
        onSuccess: @escaping () -> Void = {}
    ) -> Bool {
        do {
            try operation()
            retryAction = nil
            onSuccess()
            return true
        } catch {
            logger.error("\(action, privacy: .public) failed: \(String(describing: error), privacy: .private)")
            retryAction = { [weak self] in
                _ = self?.run(action: action, operation: operation, onSuccess: onSuccess)
            }
            failure = AppFailure(
                title: "Impossible d’enregistrer",
                message: "\(action) n’a pas pu être effectué. Vos modifications restent affichées : réessayez sans fermer l’app.",
                canRetry: true
            )
            return false
        }
    }

    func report(_ error: Error, action: String) {
        logger.error("\(action, privacy: .public) failed: \(String(describing: error), privacy: .private)")
        retryAction = nil
        failure = AppFailure(
            title: "Action impossible",
            message: "\(action) n’a pas pu être effectué. Réessayez dans quelques instants.",
            canRetry: false
        )
    }

    func retry() {
        let action = retryAction
        retryAction = nil
        failure = nil
        action?()
    }

    func dismissFailure() {
        retryAction = nil
        failure = nil
    }
}
