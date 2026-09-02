import XCTest
@testable import ATLASCore

final class TrainingAnalyticsTests: XCTestCase {
    func testVolumeUsesOnlyCompletedLoadedSets() {
        let sets = [
            TrainingSetSnapshot(loadKilograms: 100, repetitions: 5),
            TrainingSetSnapshot(loadKilograms: 80, repetitions: 10),
            TrainingSetSnapshot(loadKilograms: 60, repetitions: 12, isCompleted: false),
            TrainingSetSnapshot(loadKilograms: nil, repetitions: 15)
        ]

        XCTAssertEqual(TrainingAnalytics.volume(of: sets), 1_300, accuracy: 0.001)
    }

    func testRecordsFindWeightRepetitionsAndEstimatedOneRepMax() {
        let performance = ExercisePerformance(
            exerciseID: UUID(),
            exerciseName: "Squat",
            date: .now,
            sets: [
                TrainingSetSnapshot(loadKilograms: 100, repetitions: 5),
                TrainingSetSnapshot(loadKilograms: 90, repetitions: 10),
                TrainingSetSnapshot(loadKilograms: 110, repetitions: 1)
            ]
        )

        let records = TrainingAnalytics.records(from: [performance])

        XCTAssertEqual(records.heaviestLoadKilograms, 110)
        XCTAssertEqual(records.bestRepetitions, 10)
        XCTAssertEqual(records.estimatedOneRepMaxKilograms ?? 0, 120, accuracy: 0.001)
        XCTAssertEqual(records.totalVolumeKilograms, 1_510, accuracy: 0.001)
    }

    func testEstimatedOneRepMaxRejectsUnsupportedRepRanges() {
        XCTAssertNil(TrainingAnalytics.estimatedOneRepMax(loadKilograms: 100, repetitions: 0))
        XCTAssertNil(TrainingAnalytics.estimatedOneRepMax(loadKilograms: 100, repetitions: 13))
        XCTAssertNil(TrainingAnalytics.estimatedOneRepMax(loadKilograms: 0, repetitions: 5))
    }
}
