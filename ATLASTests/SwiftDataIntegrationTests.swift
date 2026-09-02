import SwiftData
import XCTest
@testable import ATLAS

@MainActor
final class SwiftDataIntegrationTests: XCTestCase {
    func testSeedDataIsIdempotent() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext

        try SeedData.insertIfNeeded(into: context)
        try SeedData.insertIfNeeded(into: context)

        let exercises = try context.fetch(FetchDescriptor<ExerciseRecord>())
        XCTAssertEqual(exercises.count, SeedData.bundledExerciseCount)
        XCTAssertGreaterThanOrEqual(exercises.count, 190)
        XCTAssertEqual(Set(exercises.map(\.id)).count, exercises.count)
    }

    func testSeedDataAddsNewBundledExercisesWithoutRemovingCustomOnes() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let custom = ExerciseRecord(
            nameFrench: "Mon mouvement perso",
            nameEnglish: "My custom move",
            primaryMuscles: [.fullBody],
            equipment: .other,
            category: .strength,
            isCustom: true
        )
        context.insert(custom)
        try context.save()

        try SeedData.insertIfNeeded(into: context)
        let exercises = try context.fetch(FetchDescriptor<ExerciseRecord>())

        XCTAssertEqual(exercises.count, SeedData.bundledExerciseCount + 1)
        XCTAssertTrue(exercises.contains { $0.id == custom.id && $0.isCustom })
    }

    func testSeedDataRefreshesBundledMuscleClassificationAndPreservesFavorite() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let existingPullUp = ExerciseRecord(
            nameFrench: "Tractions pronation",
            nameEnglish: "Pull-Up",
            primaryMuscles: [.back],
            equipment: .bodyweight,
            category: .strength,
            isFavorite: true
        )
        context.insert(existingPullUp)
        try context.save()

        try SeedData.insertIfNeeded(into: context)

        let exercises = try context.fetch(FetchDescriptor<ExerciseRecord>())
        let refreshed = try XCTUnwrap(exercises.first { $0.id == existingPullUp.id })
        XCTAssertTrue(refreshed.primaryMuscles.contains(MuscleGroup.lats.rawValue))
        XCTAssertFalse(refreshed.primaryMuscles.contains(MuscleGroup.back.rawValue))
        XCTAssertTrue(refreshed.isFavorite)
        XCTAssertEqual(exercises.count, SeedData.bundledExerciseCount)
    }

    func testEveryVisibleMuscleSubcategoryHasBundledExercises() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        try SeedData.insertIfNeeded(into: context)
        let exercises = try context.fetch(FetchDescriptor<ExerciseRecord>())

        for region in MuscleRegion.allCases {
            for muscle in region.subcategories {
                let count = exercises.count { exercise in
                    exercise.primaryMuscles.contains(muscle.rawValue)
                        || exercise.secondaryMuscles.contains(muscle.rawValue)
                }
                XCTAssertGreaterThan(
                    count,
                    0,
                    "La sous-catégorie \(muscle.frenchName) ne doit pas être vide."
                )
            }
        }
    }

    func testDeletingProgramCascadesToOwnedDaysAndPrescriptions() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let exercise = makeExercise()
        let program = makeProgram(exercise: exercise)
        context.insert(exercise)
        context.insert(program)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ProgramDayRecord>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ProgramExerciseRecord>()), 1)

        context.delete(program)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ProgramDayRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ProgramExerciseRecord>()), 0)
    }

    func testProgramDuplicationCopiesStructureWithFreshIdentifiers() throws {
        let exercise = makeExercise()
        let original = makeProgram(exercise: exercise)

        let copy = original.duplicated()
        let originalDay = try XCTUnwrap(original.orderedDays.first)
        let copiedDay = try XCTUnwrap(copy.orderedDays.first)
        let copiedPrescription = try XCTUnwrap(copiedDay.orderedExercises.first)

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertNotEqual(copiedDay.id, originalDay.id)
        XCTAssertEqual(copy.name, "Upper / Lower — copie")
        XCTAssertEqual(copiedPrescription.exercise?.id, exercise.id)
        XCTAssertEqual(copiedPrescription.setCount, 4)
        XCTAssertEqual(copiedPrescription.minimumRepetitions, 6)
        XCTAssertEqual(copiedPrescription.maximumRepetitions, 8)
    }

    func testWorkoutBuiltFromProgramPreservesTargets() throws {
        let exercise = makeExercise()
        let program = makeProgram(exercise: exercise)
        let day = try XCTUnwrap(program.orderedDays.first)

        let workout = WorkoutRecord.from(program: program, day: day)
        let entry = try XCTUnwrap(workout.orderedExercises.first)

        XCTAssertEqual(workout.sourceProgramName, program.name)
        XCTAssertEqual(entry.targetSetCount, 4)
        XCTAssertEqual(entry.targetMinimumRepetitions, 6)
        XCTAssertEqual(entry.targetMaximumRepetitions, 8)
        XCTAssertEqual(entry.targetRIR, 2)
        XCTAssertEqual(entry.targetRestSeconds, 150)
        XCTAssertEqual(entry.orderedSets.count, 4)
    }

    func testRepeatedWorkoutKeepsValuesAndResetsCompletion() throws {
        let exercise = makeExercise()
        let workout = WorkoutRecord(name: "Upper", state: .completed)
        let entry = WorkoutExerciseRecord(exercise: exercise, sortIndex: 0)
        entry.sets = [
            WorkoutSetRecord(
                sortIndex: 0,
                loadKilograms: 75,
                repetitions: 8,
                rir: 2,
                notes: "Solide",
                isCompleted: true,
                completedAt: .now
            )
        ]
        workout.exercises = [entry]

        let repeated = workout.repeatedDraft()
        let repeatedSet = try XCTUnwrap(repeated.orderedExercises.first?.orderedSets.first)

        XCTAssertEqual(repeated.state, .draft)
        XCTAssertNil(repeated.endedAt)
        XCTAssertEqual(repeatedSet.loadKilograms, 75)
        XCTAssertEqual(repeatedSet.repetitions, 8)
        XCTAssertEqual(repeatedSet.notes, "Solide")
        XCTAssertFalse(repeatedSet.isCompleted)
        XCTAssertNil(repeatedSet.completedAt)
    }

    func testRemovingAWorkoutSetReindexesRemainingRows() throws {
        let exercise = makeExercise()
        let entry = WorkoutExerciseRecord(exercise: exercise, sortIndex: 0)
        entry.sets = (0..<3).map { WorkoutSetRecord(sortIndex: $0) }
        let middleID = entry.orderedSets[1].id

        let removed = entry.removeSet(withID: middleID)

        XCTAssertEqual(removed?.id, middleID)
        XCTAssertEqual(entry.orderedSets.count, 2)
        XCTAssertEqual(entry.orderedSets.map(\.sortIndex), [0, 1])
        XCTAssertFalse(entry.sets.contains { $0.id == middleID })
    }

    private func makeExercise() -> ExerciseRecord {
        ExerciseRecord(
            nameFrench: "Développé couché",
            nameEnglish: "Bench Press",
            primaryMuscles: [.chest],
            equipment: .barbell,
            category: .strength
        )
    }

    private func makeProgram(exercise: ExerciseRecord) -> ProgramRecord {
        let program = ProgramRecord(name: "Upper / Lower", details: "Deux jours")
        let day = ProgramDayRecord(name: "Upper", sortIndex: 0)
        day.exercises = [
            ProgramExerciseRecord(
                exercise: exercise,
                sortIndex: 0,
                setCount: 4,
                minimumRepetitions: 6,
                maximumRepetitions: 8,
                targetRIR: 2,
                restSeconds: 150
            )
        ]
        program.days = [day]
        return program
    }
}
