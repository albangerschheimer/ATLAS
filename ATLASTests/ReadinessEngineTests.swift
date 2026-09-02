import Foundation
import XCTest
@testable import ATLAS

final class ReadinessEngineTests: XCTestCase {
    func testReadinessIsHighWithEnoughSleepAndStableHeartRate() throws {
        let snapshot = makeSnapshot(sleep: 8, restingHeartRate: 54, baseline: 55)

        let result = try XCTUnwrap(ReadinessEngine.evaluate(snapshot: snapshot))

        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.level, .high)
        XCTAssertEqual(result.explanations.count, 2)
    }

    func testShortSleepAndElevatedHeartRateReduceReadinessDeterministically() throws {
        let snapshot = makeSnapshot(sleep: 5.5, restingHeartRate: 64, baseline: 55)

        let result = try XCTUnwrap(ReadinessEngine.evaluate(snapshot: snapshot))

        XCTAssertEqual(result.score, 50)
        XCTAssertEqual(result.level, .low)
    }

    func testReadinessStillAppearsWhenOptionalSleepIsMissing() throws {
        let snapshot = makeSnapshot(sleep: nil, restingHeartRate: 54, baseline: 55)

        let result = try XCTUnwrap(ReadinessEngine.evaluate(snapshot: snapshot))
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.level, .high)
        XCTAssertEqual(result.explanations.first, "Sommeil non disponible · non inclus dans le score.")
        XCTAssertTrue(result.confidence.contains("Limitée"))
    }

    func testReadinessIsUnavailableWhenHeartRateReferenceIsMissing() {
        let snapshot = makeSnapshot(sleep: 8, restingHeartRate: 54, baseline: nil)

        XCTAssertNil(ReadinessEngine.evaluate(snapshot: snapshot))
    }

    private func makeSnapshot(
        sleep: Double?,
        restingHeartRate: Double?,
        baseline: Double?
    ) -> HealthSnapshot {
        var metrics = HealthSnapshot.empty(availability: .noData).metrics
        metrics[.sleep] = metric(.sleep, value: sleep, unit: "h")
        metrics[.restingHeartRate] = metric(.restingHeartRate, value: restingHeartRate, unit: "bpm")
        metrics[.restingHeartRateBaseline] = metric(
            .restingHeartRateBaseline,
            value: baseline,
            unit: "bpm"
        )
        return HealthSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_000),
            metrics: metrics,
            workouts: [],
            healthDataAvailable: true
        )
    }

    private func metric(_ key: HealthMetricKey, value: Double?, unit: String) -> HealthMetricValue {
        HealthMetricValue(
            key: key,
            value: value,
            unit: unit,
            startDate: nil,
            endDate: nil,
            source: value == nil ? nil : "Test",
            availability: value == nil ? .noData : .available
        )
    }
}
