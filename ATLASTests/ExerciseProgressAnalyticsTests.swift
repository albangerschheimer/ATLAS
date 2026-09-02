import XCTest
@testable import ATLAS

final class ExerciseProgressAnalyticsTests: XCTestCase {
    func testProgressMetricsIgnoreWarmups() {
        let performance = ExercisePerformance(
            exerciseID: UUID(), exerciseName: "Press", date: .now,
            sets: [
                .init(loadKilograms: 100, repetitions: 20, kind: .warmup),
                .init(loadKilograms: 80, repetitions: 8, kind: .working),
                .init(loadKilograms: 75, repetitions: 10, kind: .working)
            ]
        )
        let point = ExerciseProgressAnalytics.points(from: [performance]).first
        XCTAssertEqual(point?.weight, 80)
        XCTAssertEqual(point?.reps, 10)
        XCTAssertEqual(point?.volume, 1_390)
        XCTAssertEqual(point?.e1RM ?? 0, 101.33, accuracy: 0.02)
    }

    func testPeriodsFilterOldPoints() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let recent = ExerciseProgressPoint(id: UUID(), date: now.addingTimeInterval(-10 * 86_400), weight: 1, e1RM: 1, volume: 1, reps: 1)
        let old = ExerciseProgressPoint(id: UUID(), date: now.addingTimeInterval(-40 * 86_400), weight: 1, e1RM: 1, volume: 1, reps: 1)
        XCTAssertEqual(ExerciseProgressAnalytics.filtered([old, recent], period: .days30, now: now), [recent])
        XCTAssertEqual(ExerciseProgressAnalytics.filtered([old, recent], period: .all, now: now).count, 2)
    }
}
