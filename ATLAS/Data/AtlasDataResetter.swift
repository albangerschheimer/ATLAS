import SwiftData

@MainActor
enum AtlasDataResetter {
    static func reset(_ context: ModelContext) throws {
        try context.transaction {
            try context.fetch(FetchDescriptor<WorkoutRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<ProgramRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<ExerciseRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<NutritionEntryRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<BodyMeasurementRecord>()).forEach(context.delete)
        }
        try SeedData.insertIfNeeded(into: context)
    }
}
