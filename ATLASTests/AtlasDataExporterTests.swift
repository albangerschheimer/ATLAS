import SwiftData
import XCTest
@testable import ATLAS

@MainActor
final class AtlasDataExporterTests: XCTestCase {
    func testEmptyStoreProducesVersionedJSONAndCSVHeader() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let exporter = AtlasDataExporter()
        let exportedAt = Date(timeIntervalSince1970: 1_700_000_000)

        let json = try exporter.makeJSON(from: container.mainContext, exportedAt: exportedAt)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(AtlasExportArchive.self, from: json)

        XCTAssertEqual(archive.formatVersion, 2)
        XCTAssertEqual(archive.exportedAt, exportedAt)
        XCTAssertTrue(archive.exercises.isEmpty)
        XCTAssertTrue(archive.programs.isEmpty)
        XCTAssertTrue(archive.workouts.isEmpty)
        XCTAssertTrue(archive.nutritionEntries.isEmpty)

        let csv = try XCTUnwrap(String(data: exporter.makeCSV(from: container.mainContext), encoding: .utf8))
        XCTAssertTrue(csv.hasPrefix("workout_id,workout_name,started_at"))
        XCTAssertEqual(csv.split(separator: "\n").count, 1)
    }

    func testJSONPreservesNestedProgramAndWorkoutData() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let graph = insertCompleteGraph(into: context)
        let nutrition = NutritionEntryRecord(
            name: "Yaourt",
            consumedAt: Date(timeIntervalSince1970: 1_700_000_050),
            energyKilocalories: 150,
            proteinGrams: 18,
            carbohydrateGrams: 12,
            fatGrams: 3,
            source: .manual
        )
        context.insert(nutrition)
        try context.save()

        let archive = try AtlasDataExporter().makeArchive(
            from: context,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        XCTAssertEqual(archive.exercises.map(\.id), [graph.exercise.id])
        XCTAssertEqual(archive.programs.first?.days.first?.exercises.first?.exerciseID, graph.exercise.id)
        XCTAssertEqual(archive.programs.first?.days.first?.exercises.first?.maximumRepetitions, 10)
        XCTAssertEqual(archive.workouts.first?.sourceProgramName, "Upper / Lower")
        XCTAssertEqual(archive.workouts.first?.exercises.first?.targetRIR, 2)
        XCTAssertEqual(archive.workouts.first?.exercises.first?.sets.first?.loadKilograms, 82.5)
        XCTAssertEqual(archive.workouts.first?.exercises.first?.sets.first?.notes, "Propre")
        XCTAssertEqual(archive.workouts.first?.exercises.first?.sets.first?.rpe, 8)
        XCTAssertEqual(archive.nutritionEntries.first?.name, "Yaourt")
        XCTAssertEqual(archive.nutritionEntries.first?.proteinGrams, 18)
    }

    func testCSVIncludesOnlyCompletedSetsAndEscapesSpecialCharacters() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let graph = insertCompleteGraph(into: context)
        graph.workout.name = "Upper, \"A\""
        graph.completedSet.notes = "ligne 1\nligne 2"
        graph.workout.exercises[0].sets.append(
            WorkoutSetRecord(sortIndex: 1, loadKilograms: 90, repetitions: 3)
        )

        let draft = WorkoutRecord(name: "Brouillon exclu")
        let draftEntry = WorkoutExerciseRecord(exercise: graph.exercise, sortIndex: 0)
        draftEntry.sets = [
            WorkoutSetRecord(sortIndex: 0, loadKilograms: 200, repetitions: 1, isCompleted: true)
        ]
        draft.exercises = [draftEntry]
        context.insert(draft)
        try context.save()

        let csv = try XCTUnwrap(
            String(data: AtlasDataExporter().makeCSV(from: context), encoding: .utf8)
        )

        XCTAssertTrue(csv.contains("\"Upper, \"\"A\"\"\""))
        XCTAssertTrue(csv.contains("\"ligne 1\nligne 2\""))
        XCTAssertTrue(csv.contains(",82.5,8,2.0,8.0,"))
        XCTAssertFalse(csv.contains("Brouillon exclu"))
        XCTAssertFalse(csv.contains(",90.0,3,"))
        XCTAssertFalse(csv.contains(",200.0,1,"))
    }

    private func insertCompleteGraph(
        into context: ModelContext
    ) -> (exercise: ExerciseRecord, workout: WorkoutRecord, completedSet: WorkoutSetRecord) {
        let exercise = ExerciseRecord(
            nameFrench: "Développé couché",
            nameEnglish: "Bench Press",
            aliases: ["Bench"],
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipment: .barbell,
            category: .strength,
            instructions: "Contrôler la descente",
            isFavorite: true,
            isCustom: true,
            createdAt: Date(timeIntervalSince1970: 1_699_900_000)
        )
        let program = ProgramRecord(
            name: "Upper / Lower",
            details: "Deux jours",
            createdAt: Date(timeIntervalSince1970: 1_699_910_000)
        )
        let day = ProgramDayRecord(name: "Upper", sortIndex: 0)
        day.exercises = [
            ProgramExerciseRecord(
                exercise: exercise,
                sortIndex: 0,
                setCount: 3,
                minimumRepetitions: 8,
                maximumRepetitions: 10,
                targetRIR: 2,
                restSeconds: 150
            )
        ]
        program.days = [day]

        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let completedSet = WorkoutSetRecord(
            sortIndex: 0,
            loadKilograms: 82.5,
            repetitions: 8,
            rir: 2,
            rpe: 8,
            durationSeconds: 45,
            distanceMeters: 0,
            notes: "Propre",
            isCompleted: true,
            completedAt: startedAt.addingTimeInterval(120)
        )
        let entry = WorkoutExerciseRecord(
            exercise: exercise,
            sortIndex: 0,
            targetRestSeconds: 150,
            targetSetCount: 3,
            targetMinimumRepetitions: 8,
            targetMaximumRepetitions: 10,
            targetRIR: 2,
            notes: "Tempo contrôlé"
        )
        entry.sets = [completedSet]
        let workout = WorkoutRecord(
            name: "Upper",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(3_600),
            state: .completed,
            notes: "Bonne séance",
            sourceProgramName: program.name,
            sourceDayName: day.name,
            exercises: [entry]
        )

        context.insert(exercise)
        context.insert(program)
        context.insert(workout)
        return (exercise, workout, completedSet)
    }
}
