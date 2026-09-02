import XCTest
@testable import ATLAS

final class HealthBodyMeasurementSyncTests: XCTestCase {
    func testSupportedHealthMetricsMapToBodyMeasurementsWithoutLosingDateOrSource() {
        let measuredAt = Date(timeIntervalSince1970: 1_777_777_777)
        let values: [HealthMetricKey: HealthMetricValue] = [
            .bodyMass: value(.bodyMass, 65.7, "kg", measuredAt),
            .bodyFatPercentage: value(.bodyFatPercentage, 14.8, "%", measuredAt),
            .leanBodyMass: value(.leanBodyMass, 55.2, "kg", measuredAt),
            .bodyMassIndex: value(.bodyMassIndex, 21.4, "IMC", measuredAt)
        ]

        let samples = HealthBodyMeasurementSync.samples(from: values)

        XCTAssertEqual(samples.map(\.metric), [.weight, .bodyFatPercentage, .fatFreeMass, .bodyMassIndex])
        XCTAssertTrue(samples.allSatisfy { $0.measuredAt == measuredAt })
        XCTAssertTrue(samples.allSatisfy { $0.source == "Ma balance" })
    }

    func testDuplicateImportedHealthMeasurementIsRejected() {
        let measuredAt = Date(timeIntervalSince1970: 1_777_777_777)
        let sample = HealthBodyMeasurementSample(
            id: UUID(),
            metric: .weight,
            value: 65.7,
            measuredAt: measuredAt,
            source: "Ma balance"
        )
        let existing = BodyMeasurementRecord(
            metric: .weight,
            value: 65.7,
            measuredAt: measuredAt,
            source: .appleHealth,
            note: "Importé depuis Ma balance"
        )

        XCTAssertFalse(HealthBodyMeasurementSync.shouldImport(sample, existing: [existing]))
    }

    private func value(
        _ key: HealthMetricKey,
        _ value: Double,
        _ unit: String,
        _ date: Date
    ) -> HealthMetricValue {
        HealthMetricValue(
            key: key,
            value: value,
            unit: unit,
            startDate: date,
            endDate: date,
            source: "Ma balance",
            availability: .available
        )
    }
}
