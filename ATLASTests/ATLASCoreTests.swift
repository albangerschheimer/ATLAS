import XCTest
@testable import ATLAS

final class ATLASCoreTests: XCTestCase {
    func testVolumeIgnoresIncompleteAndUnloadedSets() {
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

    func testDoubleProgressionOnlyIncreasesAtTheCompleteTarget() {
        let successfulSets = (0..<3).map { _ in
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 10, rir: 2)
        }
        let increase = ProgressionEngine.doubleProgression(
            sets: successfulSets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )
        XCTAssertEqual(increase.action, .increaseLoad(toKilograms: 77.5))

        var missedSets = successfulSets
        missedSets[1].repetitions = 9
        let keep = ProgressionEngine.doubleProgression(
            sets: missedSets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )
        XCTAssertEqual(keep.action, .keepLoad)
    }
}
