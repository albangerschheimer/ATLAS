import Foundation

@MainActor
protocol HealthDataProvider {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func loadSnapshot(week: DateInterval, now: Date) async -> HealthSnapshot
    func loadBodyMeasurements(since: Date, now: Date) async -> [HealthBodyMeasurementSample]
}

extension HealthDataProvider {
    func loadBodyMeasurements(since: Date, now: Date) async -> [HealthBodyMeasurementSample] { [] }
}

@MainActor
enum HealthDataProviderFactory {
    static func make() -> any HealthDataProvider {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return MockHealthDataProvider(snapshot: .empty(availability: .noData))
        }
        return HealthKitDataProvider()
    }
}
