import Combine
import Foundation

@MainActor
final class HealthDashboardViewModel: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty(availability: .permissionNotRequested)
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let provider: any HealthDataProvider

    init(provider: (any HealthDataProvider)? = nil) {
        self.provider = provider ?? HealthDataProviderFactory.make()
    }

    var isHealthDataAvailable: Bool {
        provider.isHealthDataAvailable
    }

    var readiness: ReadinessResult? {
        ReadinessEngine.evaluate(snapshot: snapshot)
    }

    func refresh(hasRequestedAccess: Bool, now: Date = .now) async {
        guard provider.isHealthDataAvailable else {
            snapshot = .empty(
                availability: .healthUnavailable,
                generatedAt: now,
                healthDataAvailable: false
            )
            return
        }
        guard hasRequestedAccess else {
            snapshot = .empty(availability: .permissionNotRequested, generatedAt: now)
            return
        }

        isLoading = true
        errorMessage = nil
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: now)
            ?? DateInterval(start: now.addingTimeInterval(-7 * 86_400), end: now)
        snapshot = await provider.loadSnapshot(week: week, now: now)
        isLoading = false
    }

    func requestAccess(now: Date = .now) async -> Bool {
        guard provider.isHealthDataAvailable else {
            errorMessage = "Apple Santé n’est pas disponible sur cet appareil."
            return false
        }

        isLoading = true
        errorMessage = nil
        do {
            try await provider.requestAuthorization()
            isLoading = false
            await refresh(hasRequestedAccess: true, now: now)
            return true
        } catch {
            isLoading = false
            errorMessage = "L’autorisation Apple Santé n’a pas pu être terminée. Vous pouvez réessayer."
            return false
        }
    }
}
