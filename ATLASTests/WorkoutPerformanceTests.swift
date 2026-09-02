import Foundation
import SwiftData
import XCTest
@testable import ATLAS

@MainActor
final class WorkoutPerformanceTests: XCTestCase {
    func testOneThousandWorkoutStoreSupportsRecentFetchAndSetSave() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATLAS-performance-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let container = try ModelContainerFactory.make(
            storeURL: directory.appendingPathComponent("ATLAS.store")
        )
        let seedContext = ModelContext(container)
        for index in 0..<6 {
            seedContext.insert(
                ExerciseRecord(
                    nameFrench: "Exercice performance \(index)",
                    nameEnglish: "Performance exercise \(index)",
                    primaryMuscles: [.quadriceps],
                    equipment: .barbell,
                    category: .strength
                )
            )
        }
        try seedContext.save()

        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        for batchStart in stride(from: 0, to: 1_000, by: 100) {
            let context = ModelContext(container)
            let exercises = try context.fetch(
                FetchDescriptor<ExerciseRecord>(sortBy: [SortDescriptor(\.nameFrench)])
            )

            for workoutIndex in batchStart..<(batchStart + 100) {
                let date = baseDate.addingTimeInterval(TimeInterval(workoutIndex * 86_400))
                let workout = WorkoutRecord(
                    name: "Séance performance \(workoutIndex)",
                    startedAt: date,
                    endedAt: date.addingTimeInterval(3_600),
                    state: .completed
                )
                workout.exercises = exercises.enumerated().map { exerciseIndex, exercise in
                    let entry = WorkoutExerciseRecord(
                        exercise: exercise,
                        sortIndex: exerciseIndex,
                        targetRestSeconds: 120
                    )
                    entry.sets = (0..<4).map { setIndex in
                        WorkoutSetRecord(
                            sortIndex: setIndex,
                            loadKilograms: Double(60 + exerciseIndex * 10 + setIndex),
                            repetitions: 8 + setIndex,
                            rir: 2,
                            isCompleted: true,
                            completedAt: date.addingTimeInterval(TimeInterval(setIndex * 120))
                        )
                    }
                    return entry
                }
                context.insert(workout)
            }
            try context.save()
        }

        let readContext = ModelContext(container)
        var recentDescriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.stateRawValue == "completed" },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 50

        let fetchStartedAt = Date.now
        let recent = try readContext.fetch(recentDescriptor)
        let fetchDuration = Date.now.timeIntervalSince(fetchStartedAt)

        XCTAssertEqual(recent.count, 50)
        XCTAssertEqual(try readContext.fetchCount(FetchDescriptor<WorkoutRecord>()), 1_000)
        XCTAssertLessThan(fetchDuration, 2, "La lecture des 50 séances récentes a régressé")

        let set = try XCTUnwrap(recent.first?.orderedExercises.first?.orderedSets.first)
        let saveStartedAt = Date.now
        set.loadKilograms = 102.5
        try readContext.save()
        let saveDuration = Date.now.timeIntervalSince(saveStartedAt)

        XCTAssertLessThan(saveDuration, 1, "La sauvegarde d’une série a régressé")
        print(
            "ATLAS performance — recent fetch: \(fetchDuration)s; set save: \(saveDuration)s; " +
            "1,000 workouts / 6,000 exercises / 24,000 sets"
        )
    }
}
