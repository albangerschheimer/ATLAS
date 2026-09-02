import XCTest
@testable import ATLASCore

final class ProgressionEngineTests: XCTestCase {
    func testDoubleProgressionIncreasesLoadAtTopOfRange() {
        let sets = (0..<3).map { _ in
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 10, rir: 2)
        }

        let recommendation = ProgressionEngine.doubleProgression(
            sets: sets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )

        XCTAssertEqual(recommendation.action, .increaseLoad(toKilograms: 77.5))
    }

    func testDoubleProgressionKeepsLoadWhenOneSetMissesTarget() {
        let sets = [
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 10, rir: 2),
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 9, rir: 2),
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 10, rir: 2)
        ]

        let recommendation = ProgressionEngine.doubleProgression(
            sets: sets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )

        XCTAssertEqual(recommendation.action, .keepLoad)
    }

    func testDoubleProgressionRequiresRIRData() {
        let sets = (0..<3).map { _ in
            TrainingSetSnapshot(loadKilograms: 75, repetitions: 10, rir: nil)
        }

        let recommendation = ProgressionEngine.doubleProgression(
            sets: sets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )

        XCTAssertEqual(recommendation.action, .insufficientData)
    }
}
