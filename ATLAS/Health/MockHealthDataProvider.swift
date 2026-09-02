import Foundation

@MainActor
final class MockHealthDataProvider: HealthDataProvider {
    var snapshot: HealthSnapshot
    var authorizationError: Error?
    var bodyMeasurements: [HealthBodyMeasurementSample] = []
    private(set) var authorizationRequestCount = 0

    init(snapshot: HealthSnapshot) {
        self.snapshot = snapshot
    }

    var isHealthDataAvailable: Bool {
        snapshot.healthDataAvailable
    }

    func requestAuthorization() async throws {
        authorizationRequestCount += 1
        if let authorizationError {
            throw authorizationError
        }
    }

    func loadSnapshot(week: DateInterval, now: Date) async -> HealthSnapshot {
        snapshot
    }

    func loadBodyMeasurements(since: Date, now: Date) async -> [HealthBodyMeasurementSample] {
        bodyMeasurements.filter { $0.measuredAt >= since && $0.measuredAt <= now }
    }
}
