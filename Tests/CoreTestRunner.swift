import Foundation

@main
enum CoreTestRunner {
    static func main() {
        testVolume()
        testRecords()
        testProgression()
        print("ATLAS core checks passed (8 assertions).")
    }

    private static func testVolume() {
        let sets = [
            TrainingSetSnapshot(loadKilograms: 100, repetitions: 5),
            TrainingSetSnapshot(loadKilograms: 80, repetitions: 10),
            TrainingSetSnapshot(loadKilograms: 60, repetitions: 12, isCompleted: false),
            TrainingSetSnapshot(loadKilograms: nil, repetitions: 15)
        ]
        expect(TrainingAnalytics.volume(of: sets) == 1_300, "completed-set volume")
    }

    private static func testRecords() {
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

        expect(records.heaviestLoadKilograms == 110, "weight PR")
        expect(records.bestRepetitions == 10, "repetition PR")
        expect(abs((records.estimatedOneRepMaxKilograms ?? 0) - 120) < 0.001, "estimated 1RM")
        expect(records.totalVolumeKilograms == 1_510, "total volume")
    }

    private static func testProgression() {
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
        expect(increase.action == .increaseLoad(toKilograms: 77.5), "double progression increase")

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
        expect(keep.action == .keepLoad, "double progression keep")

        var incompleteSets = successfulSets
        incompleteSets[0].rir = nil
        let incomplete = ProgressionEngine.doubleProgression(
            sets: incompleteSets,
            prescribedSetCount: 3,
            topOfRepRange: 10,
            targetRIR: 2,
            currentLoadKilograms: 75,
            loadIncrementKilograms: 2.5
        )
        expect(incomplete.action == .insufficientData, "double progression missing data")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else {
            fatalError("Core check failed: \(name)")
        }
    }
}
