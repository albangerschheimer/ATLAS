import Foundation
import SwiftData
import XCTest
@testable import ATLAS

@MainActor
final class SwiftDataStoreTests: XCTestCase {
    func testVersionOneStoreReopensWithoutLosingRelationships() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATLAS-store-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("ATLAS.store")
        let workoutID = UUID()
        let setID = UUID()

        do {
            let container = try ModelContainerFactory.make(storeURL: storeURL)
            let context = container.mainContext
            let exercise = ExerciseRecord(
                nameFrench: "Squat barre",
                nameEnglish: "Back Squat",
                primaryMuscles: [.quadriceps],
                equipment: .barbell,
                category: .strength
            )
            let workout = WorkoutRecord(
                id: workoutID,
                name: "Lower",
                state: .completed
            )
            let entry = WorkoutExerciseRecord(exercise: exercise, sortIndex: 0)
            entry.sets = [
                WorkoutSetRecord(
                    id: setID,
                    sortIndex: 0,
                    loadKilograms: 120,
                    repetitions: 5,
                    rir: 1,
                    rpe: 9,
                    notes: "Test disque",
                    isCompleted: true,
                    completedAt: .now
                )
            ]
            workout.exercises = [entry]
            context.insert(exercise)
            context.insert(workout)
            try context.save()
        }

        do {
            let reopened = try ModelContainerFactory.make(storeURL: storeURL)
            let context = reopened.mainContext
            let descriptor = FetchDescriptor<WorkoutRecord>(
                predicate: #Predicate { $0.id == workoutID }
            )
            let workout = try XCTUnwrap(context.fetch(descriptor).first)
            let set = try XCTUnwrap(workout.orderedExercises.first?.orderedSets.first)

            XCTAssertEqual(workout.id, workoutID)
            XCTAssertEqual(workout.orderedExercises.first?.exerciseNameSnapshot, "Squat barre")
            XCTAssertEqual(set.id, setID)
            XCTAssertEqual(set.loadKilograms, 120)
            XCTAssertEqual(set.rpe, 9)
            XCTAssertEqual(set.notes, "Test disque")
        }
    }

    func testVersionOneStoreMigratesToNutritionSchemaWithoutLosingWorkout() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ATLAS-migration-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("ATLAS.store")
        let workoutID = UUID()

        do {
            let versionOneSchema = Schema(versionedSchema: ATLASchemaV1.self)
            let configuration = ModelConfiguration(
                "ATLAS",
                schema: versionOneSchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let versionOneContainer = try ModelContainer(
                for: versionOneSchema,
                configurations: [configuration]
            )
            let workout = WorkoutRecord(id: workoutID, name: "Avant nutrition", state: .completed)
            versionOneContainer.mainContext.insert(workout)
            try versionOneContainer.mainContext.save()
        }

        do {
            let migrated = try ModelContainerFactory.make(storeURL: storeURL)
            let context = migrated.mainContext
            let descriptor = FetchDescriptor<WorkoutRecord>(
                predicate: #Predicate { $0.id == workoutID }
            )
            XCTAssertEqual(try context.fetch(descriptor).first?.name, "Avant nutrition")

            context.insert(
                NutritionEntryRecord(
                    name: "Premier repas V2",
                    energyKilocalories: 650,
                    proteinGrams: 35
                )
            )
            try context.save()
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<NutritionEntryRecord>()), 1)
        }
    }
}
