import Foundation
import SwiftData

struct AtlasExportArchive: Codable, Equatable {
    let formatVersion: Int
    let exportedAt: Date
    let exercises: [Exercise]
    let programs: [Program]
    let workouts: [Workout]
    let nutritionEntries: [NutritionEntry]

    struct Exercise: Codable, Equatable {
        let id: UUID
        let nameFrench: String
        let nameEnglish: String
        let aliases: [String]
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let equipment: String
        let category: String
        let instructions: String
        let isFavorite: Bool
        let isCustom: Bool
        let createdAt: Date
    }

    struct Program: Codable, Equatable {
        let id: UUID
        let name: String
        let details: String
        let isActive: Bool
        let createdAt: Date
        let days: [ProgramDay]
    }

    struct ProgramDay: Codable, Equatable {
        let id: UUID
        let name: String
        let sortIndex: Int
        let exercises: [ProgramExercise]
    }

    struct ProgramExercise: Codable, Equatable {
        let id: UUID
        let exerciseID: UUID?
        let exerciseNameSnapshot: String
        let sortIndex: Int
        let setCount: Int
        let minimumRepetitions: Int
        let maximumRepetitions: Int
        let targetRIR: Double
        let restSeconds: Int
    }

    struct Workout: Codable, Equatable {
        let id: UUID
        let name: String
        let startedAt: Date
        let endedAt: Date?
        let state: String
        let notes: String
        let sourceProgramName: String?
        let sourceDayName: String?
        let exercises: [WorkoutExercise]
    }

    struct WorkoutExercise: Codable, Equatable {
        let id: UUID
        let exerciseIDSnapshot: UUID
        let exerciseNameSnapshot: String
        let sortIndex: Int
        let targetRestSeconds: Int
        let targetSetCount: Int?
        let targetMinimumRepetitions: Int?
        let targetMaximumRepetitions: Int?
        let targetRIR: Double?
        let notes: String
        let sets: [WorkoutSet]
    }

    struct WorkoutSet: Codable, Equatable {
        let id: UUID
        let sortIndex: Int
        let loadKilograms: Double?
        let repetitions: Int?
        let rir: Double?
        let rpe: Double?
        let durationSeconds: Double?
        let distanceMeters: Double?
        let notes: String
        let kind: String
        let isCompleted: Bool
        let completedAt: Date?
    }

    struct NutritionEntry: Codable, Equatable {
        let id: UUID
        let name: String
        let consumedAt: Date
        let energyKilocalories: Double
        let proteinGrams: Double
        let carbohydrateGrams: Double
        let fatGrams: Double
        let servingGrams: Double?
        let barcode: String?
        let source: String
        let createdAt: Date
    }
}

@MainActor
struct AtlasDataExporter {
    static let formatVersion = 2

    func makeArchive(
        from context: ModelContext,
        exportedAt: Date = .now
    ) throws -> AtlasExportArchive {
        let exerciseDescriptor = FetchDescriptor<ExerciseRecord>(
            sortBy: [SortDescriptor(\.nameFrench), SortDescriptor(\.createdAt)]
        )
        let programDescriptor = FetchDescriptor<ProgramRecord>(
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.name)]
        )
        let workoutDescriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.startedAt)]
        )
        let nutritionDescriptor = FetchDescriptor<NutritionEntryRecord>(
            sortBy: [SortDescriptor(\.consumedAt)]
        )

        let exercises = try context.fetch(exerciseDescriptor).map { exercise in
            AtlasExportArchive.Exercise(
                id: exercise.id,
                nameFrench: exercise.nameFrench,
                nameEnglish: exercise.nameEnglish,
                aliases: exercise.aliases,
                primaryMuscles: exercise.primaryMuscles,
                secondaryMuscles: exercise.secondaryMuscles,
                equipment: exercise.equipmentRawValue,
                category: exercise.categoryRawValue,
                instructions: exercise.instructions,
                isFavorite: exercise.isFavorite,
                isCustom: exercise.isCustom,
                createdAt: exercise.createdAt
            )
        }

        let programs = try context.fetch(programDescriptor).map { program in
            AtlasExportArchive.Program(
                id: program.id,
                name: program.name,
                details: program.details,
                isActive: program.isActive,
                createdAt: program.createdAt,
                days: program.orderedDays.map { day in
                    AtlasExportArchive.ProgramDay(
                        id: day.id,
                        name: day.name,
                        sortIndex: day.sortIndex,
                        exercises: day.orderedExercises.map { prescription in
                            AtlasExportArchive.ProgramExercise(
                                id: prescription.id,
                                exerciseID: prescription.exercise?.id,
                                exerciseNameSnapshot: prescription.exerciseNameSnapshot,
                                sortIndex: prescription.sortIndex,
                                setCount: prescription.setCount,
                                minimumRepetitions: prescription.minimumRepetitions,
                                maximumRepetitions: prescription.maximumRepetitions,
                                targetRIR: prescription.targetRIR,
                                restSeconds: prescription.restSeconds
                            )
                        }
                    )
                }
            )
        }

        let workouts = try context.fetch(workoutDescriptor).map { workout in
            AtlasExportArchive.Workout(
                id: workout.id,
                name: workout.name,
                startedAt: workout.startedAt,
                endedAt: workout.endedAt,
                state: workout.stateRawValue,
                notes: workout.notes,
                sourceProgramName: workout.sourceProgramName,
                sourceDayName: workout.sourceDayName,
                exercises: workout.orderedExercises.map { entry in
                    AtlasExportArchive.WorkoutExercise(
                        id: entry.id,
                        exerciseIDSnapshot: entry.exerciseIDSnapshot,
                        exerciseNameSnapshot: entry.exerciseNameSnapshot,
                        sortIndex: entry.sortIndex,
                        targetRestSeconds: entry.targetRestSeconds,
                        targetSetCount: entry.targetSetCount,
                        targetMinimumRepetitions: entry.targetMinimumRepetitions,
                        targetMaximumRepetitions: entry.targetMaximumRepetitions,
                        targetRIR: entry.targetRIR,
                        notes: entry.notes,
                        sets: entry.orderedSets.map { set in
                            AtlasExportArchive.WorkoutSet(
                                id: set.id,
                                sortIndex: set.sortIndex,
                                loadKilograms: set.loadKilograms,
                                repetitions: set.repetitions,
                                rir: set.rir,
                                rpe: set.rpe,
                                durationSeconds: set.durationSeconds,
                                distanceMeters: set.distanceMeters,
                                notes: set.notes,
                                kind: set.kindRawValue,
                                isCompleted: set.isCompleted,
                                completedAt: set.completedAt
                            )
                        }
                    )
                }
            )
        }

        let nutritionEntries = try context.fetch(nutritionDescriptor).map { entry in
            AtlasExportArchive.NutritionEntry(
                id: entry.id,
                name: entry.name,
                consumedAt: entry.consumedAt,
                energyKilocalories: entry.energyKilocalories,
                proteinGrams: entry.proteinGrams,
                carbohydrateGrams: entry.carbohydrateGrams,
                fatGrams: entry.fatGrams,
                servingGrams: entry.servingGrams,
                barcode: entry.barcode,
                source: entry.sourceRawValue,
                createdAt: entry.createdAt
            )
        }

        return AtlasExportArchive(
            formatVersion: Self.formatVersion,
            exportedAt: exportedAt,
            exercises: exercises,
            programs: programs,
            workouts: workouts,
            nutritionEntries: nutritionEntries
        )
    }

    func makeJSON(
        from context: ModelContext,
        exportedAt: Date = .now
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(makeArchive(from: context, exportedAt: exportedAt))
    }

    func makeCSV(from context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.stateRawValue == "completed" },
            sortBy: [SortDescriptor(\.startedAt)]
        )
        let workouts = try context.fetch(descriptor)
        var rows = [csvHeader]

        for workout in workouts {
            for entry in workout.orderedExercises {
                for set in entry.orderedSets where set.isCompleted {
                    rows.append(csvRow([
                        workout.id.uuidString,
                        workout.name,
                        isoDate(workout.startedAt),
                        workout.endedAt.map(isoDate) ?? "",
                        workout.sourceProgramName ?? "",
                        workout.sourceDayName ?? "",
                        workout.notes,
                        String(entry.sortIndex + 1),
                        entry.exerciseIDSnapshot.uuidString,
                        entry.exerciseNameSnapshot,
                        entry.notes,
                        String(set.sortIndex + 1),
                        set.kindRawValue,
                        set.completedAt.map(isoDate) ?? "",
                        optionalString(set.loadKilograms),
                        set.repetitions.map(String.init) ?? "",
                        optionalString(set.rir),
                        optionalString(set.rpe),
                        optionalString(set.durationSeconds),
                        optionalString(set.distanceMeters),
                        set.notes
                    ]))
                }
            }
        }

        return Data((rows.joined(separator: "\r\n") + "\r\n").utf8)
    }

    private var csvHeader: String {
        csvRow([
            "workout_id", "workout_name", "started_at", "ended_at",
            "source_program", "source_day", "workout_notes", "exercise_order",
            "exercise_id", "exercise_name", "exercise_notes", "set_order",
            "set_kind", "completed_at", "load_kg", "repetitions", "rir", "rpe",
            "duration_seconds", "distance_meters", "set_notes"
        ])
    }

    private func isoDate(_ date: Date) -> String {
        date.ISO8601Format()
    }

    private func optionalString(_ value: Double?) -> String {
        value.map { String($0) } ?? ""
    }

    private func csvRow(_ values: [String]) -> String {
        values.map(csvEscape).joined(separator: ",")
    }

    private func csvEscape(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
