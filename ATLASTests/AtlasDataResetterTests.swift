import SwiftData
import XCTest
@testable import ATLAS

@MainActor
final class AtlasDataResetterTests: XCTestCase {
    func testResetDeletesPersonalDataAndRestoresBundledCatalog() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        try SeedData.insertIfNeeded(into: context)

        let customExercise = ExerciseRecord(
            nameFrench: "Exercice personnel",
            nameEnglish: "Custom exercise",
            primaryMuscles: [.core],
            equipment: .other,
            category: .strength,
            isCustom: true
        )
        context.insert(customExercise)
        context.insert(ProgramRecord(name: "Programme personnel"))
        context.insert(WorkoutRecord(name: "Séance personnelle"))
        context.insert(NutritionEntryRecord(name: "Repas", energyKilocalories: 700))
        try context.save()

        try AtlasDataResetter.reset(context)

        let exercises = try context.fetch(FetchDescriptor<ExerciseRecord>())
        XCTAssertEqual(exercises.count, SeedData.bundledExerciseCount)
        XCTAssertFalse(exercises.contains(where: \.isCustom))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ProgramRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<NutritionEntryRecord>()), 0)
    }

    func testResetCanRunTwice() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        try SeedData.insertIfNeeded(into: context)

        try AtlasDataResetter.reset(context)
        try AtlasDataResetter.reset(context)

        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<ExerciseRecord>()),
            SeedData.bundledExerciseCount
        )
    }
}
