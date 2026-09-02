import Foundation
import SwiftData

enum WorkoutState: String, Codable {
    case draft
    case completed
}

enum ATLASchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ExerciseRecord.self,
            ProgramRecord.self,
            ProgramDayRecord.self,
            ProgramExerciseRecord.self,
            WorkoutRecord.self,
            WorkoutExerciseRecord.self,
            WorkoutSetRecord.self
        ]
    }

@Model
final class ExerciseRecord {
    @Attribute(.unique) var id: UUID
    var nameFrench: String
    var nameEnglish: String
    var aliases: [String]
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var equipmentRawValue: String
    var categoryRawValue: String
    var instructions: String
    var isFavorite: Bool
    var isCustom: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        nameFrench: String,
        nameEnglish: String,
        aliases: [String] = [],
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentKind,
        category: ExerciseCategory,
        instructions: String = "",
        isFavorite: Bool = false,
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.nameFrench = nameFrench
        self.nameEnglish = nameEnglish
        self.aliases = aliases
        self.primaryMuscles = primaryMuscles.map(\.rawValue)
        self.secondaryMuscles = secondaryMuscles.map(\.rawValue)
        self.equipmentRawValue = equipment.rawValue
        self.categoryRawValue = category.rawValue
        self.instructions = instructions
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    var displayName: String {
        nameFrench.isEmpty ? nameEnglish : nameFrench
    }

    var equipment: EquipmentKind {
        get { EquipmentKind(rawValue: equipmentRawValue) ?? .other }
        set { equipmentRawValue = newValue.rawValue }
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRawValue) ?? .strength }
        set { categoryRawValue = newValue.rawValue }
    }

    var muscleSummary: String {
        primaryMuscles
            .compactMap(MuscleGroup.init(rawValue:))
            .map(\.frenchName)
            .joined(separator: ", ")
    }
}

@Model
final class ProgramRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var details: String
    var isActive: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ProgramDayRecord.program)
    var days: [ProgramDayRecord]

    init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        isActive: Bool = true,
        createdAt: Date = .now,
        days: [ProgramDayRecord] = []
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.isActive = isActive
        self.createdAt = createdAt
        self.days = days
    }

    var orderedDays: [ProgramDayRecord] {
        days.sorted { $0.sortIndex < $1.sortIndex }
    }

    func duplicated() -> ProgramRecord {
        let copy = ProgramRecord(
            name: "\(name) — copie",
            details: details,
            isActive: isActive
        )

        copy.days = orderedDays.enumerated().map { dayIndex, sourceDay in
            let dayCopy = ProgramDayRecord(
                name: sourceDay.name,
                sortIndex: dayIndex
            )
            dayCopy.exercises = sourceDay.orderedExercises.enumerated().compactMap { exerciseIndex, source in
                guard let exercise = source.exercise else { return nil }
                return ProgramExerciseRecord(
                    exercise: exercise,
                    sortIndex: exerciseIndex,
                    setCount: source.setCount,
                    minimumRepetitions: source.minimumRepetitions,
                    maximumRepetitions: source.maximumRepetitions,
                    targetRIR: source.targetRIR,
                    restSeconds: source.restSeconds
                )
            }
            return dayCopy
        }

        return copy
    }
}

@Model
final class ProgramDayRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortIndex: Int
    var program: ProgramRecord?
    @Relationship(deleteRule: .cascade, inverse: \ProgramExerciseRecord.day)
    var exercises: [ProgramExerciseRecord]

    init(
        id: UUID = UUID(),
        name: String,
        sortIndex: Int,
        exercises: [ProgramExerciseRecord] = []
    ) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.exercises = exercises
    }

    var orderedExercises: [ProgramExerciseRecord] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }
}

@Model
final class ProgramExerciseRecord {
    @Attribute(.unique) var id: UUID
    var day: ProgramDayRecord?
    var exercise: ExerciseRecord?
    var exerciseNameSnapshot: String
    var sortIndex: Int
    var setCount: Int
    var minimumRepetitions: Int
    var maximumRepetitions: Int
    var targetRIR: Double
    var restSeconds: Int

    init(
        id: UUID = UUID(),
        exercise: ExerciseRecord,
        sortIndex: Int,
        setCount: Int = 3,
        minimumRepetitions: Int = 8,
        maximumRepetitions: Int = 10,
        targetRIR: Double = 2,
        restSeconds: Int = 120
    ) {
        self.id = id
        self.exercise = exercise
        self.exerciseNameSnapshot = exercise.displayName
        self.sortIndex = sortIndex
        self.setCount = setCount
        self.minimumRepetitions = minimumRepetitions
        self.maximumRepetitions = maximumRepetitions
        self.targetRIR = targetRIR
        self.restSeconds = restSeconds
    }

    var displayName: String {
        exercise?.displayName ?? exerciseNameSnapshot
    }
}

@Model
final class WorkoutRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var stateRawValue: String
    var notes: String
    var sourceProgramName: String?
    var sourceDayName: String?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExerciseRecord.workout)
    var exercises: [WorkoutExerciseRecord]

    init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        state: WorkoutState = .draft,
        notes: String = "",
        sourceProgramName: String? = nil,
        sourceDayName: String? = nil,
        exercises: [WorkoutExerciseRecord] = []
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.stateRawValue = state.rawValue
        self.notes = notes
        self.sourceProgramName = sourceProgramName
        self.sourceDayName = sourceDayName
        self.exercises = exercises
    }

    var state: WorkoutState {
        get { WorkoutState(rawValue: stateRawValue) ?? .draft }
        set { stateRawValue = newValue.rawValue }
    }

    var orderedExercises: [WorkoutExerciseRecord] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }

    var duration: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var completedSetCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    /// Accords singulier/pluriel partagés par les écrans qui comptent des séries.
    var completedSetCountLabel: String {
        completedSetCount > 1 ? "\(completedSetCount) séries" : "\(completedSetCount) série"
    }

    var completedSetSummary: String {
        completedSetCount > 1
            ? "\(completedSetCount) séries enregistrées"
            : "\(completedSetCount) série enregistrée"
    }

    var totalVolume: Double {
        TrainingAnalytics.volume(of: exercises.flatMap { entry in
            entry.sets.map(\.snapshot)
        })
    }

    static func from(program: ProgramRecord, day: ProgramDayRecord) -> WorkoutRecord {
        let workout = WorkoutRecord(
            name: day.name,
            sourceProgramName: program.name,
            sourceDayName: day.name
        )

        workout.exercises = day.orderedExercises.enumerated().map { index, prescription in
            let entry = WorkoutExerciseRecord(
                exercise: prescription.exercise,
                exerciseNameSnapshot: prescription.displayName,
                sortIndex: index,
                targetRestSeconds: prescription.restSeconds,
                targetSetCount: prescription.setCount,
                targetMinimumRepetitions: prescription.minimumRepetitions,
                targetMaximumRepetitions: prescription.maximumRepetitions,
                targetRIR: prescription.targetRIR
            )
            entry.sets = (0..<prescription.setCount).map { setIndex in
                WorkoutSetRecord(
                    sortIndex: setIndex,
                    repetitions: prescription.minimumRepetitions,
                    rir: prescription.targetRIR
                )
            }
            return entry
        }
        return workout
    }

    func repeatedDraft() -> WorkoutRecord {
        let draft = WorkoutRecord(
            name: name,
            sourceProgramName: sourceProgramName,
            sourceDayName: sourceDayName
        )

        draft.exercises = orderedExercises.enumerated().map { exerciseIndex, sourceEntry in
            let entry = WorkoutExerciseRecord(
                exercise: sourceEntry.exercise,
                exerciseNameSnapshot: sourceEntry.exerciseNameSnapshot,
                sortIndex: exerciseIndex,
                targetRestSeconds: sourceEntry.targetRestSeconds,
                targetSetCount: sourceEntry.targetSetCount,
                targetMinimumRepetitions: sourceEntry.targetMinimumRepetitions,
                targetMaximumRepetitions: sourceEntry.targetMaximumRepetitions,
                targetRIR: sourceEntry.targetRIR,
                notes: sourceEntry.notes
            )
            entry.exerciseIDSnapshot = sourceEntry.exerciseIDSnapshot
            entry.sets = sourceEntry.orderedSets.enumerated().map { setIndex, sourceSet in
                WorkoutSetRecord(
                    sortIndex: setIndex,
                    loadKilograms: sourceSet.loadKilograms,
                    repetitions: sourceSet.repetitions,
                    rir: sourceSet.rir,
                    rpe: sourceSet.rpe,
                    durationSeconds: sourceSet.durationSeconds,
                    distanceMeters: sourceSet.distanceMeters,
                    notes: sourceSet.notes,
                    kind: sourceSet.kind
                )
            }
            return entry
        }

        return draft
    }
}

@Model
final class WorkoutExerciseRecord {
    @Attribute(.unique) var id: UUID
    var workout: WorkoutRecord?
    var exercise: ExerciseRecord?
    var exerciseIDSnapshot: UUID
    var exerciseNameSnapshot: String
    var sortIndex: Int
    var targetRestSeconds: Int
    var targetSetCount: Int?
    var targetMinimumRepetitions: Int?
    var targetMaximumRepetitions: Int?
    var targetRIR: Double?
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSetRecord.workoutExercise)
    var sets: [WorkoutSetRecord]

    init(
        id: UUID = UUID(),
        exercise: ExerciseRecord?,
        exerciseNameSnapshot: String? = nil,
        sortIndex: Int,
        targetRestSeconds: Int = 120,
        targetSetCount: Int? = nil,
        targetMinimumRepetitions: Int? = nil,
        targetMaximumRepetitions: Int? = nil,
        targetRIR: Double? = nil,
        notes: String = "",
        sets: [WorkoutSetRecord] = []
    ) {
        self.id = id
        self.exercise = exercise
        self.exerciseIDSnapshot = exercise?.id ?? UUID()
        self.exerciseNameSnapshot = exerciseNameSnapshot ?? exercise?.displayName ?? "Exercice"
        self.sortIndex = sortIndex
        self.targetRestSeconds = targetRestSeconds
        self.targetSetCount = targetSetCount
        self.targetMinimumRepetitions = targetMinimumRepetitions
        self.targetMaximumRepetitions = targetMaximumRepetitions
        self.targetRIR = targetRIR
        self.notes = notes
        self.sets = sets
    }

    var displayName: String {
        exercise?.displayName ?? exerciseNameSnapshot
    }

    var orderedSets: [WorkoutSetRecord] {
        sets.sorted { $0.sortIndex < $1.sortIndex }
    }

    var targetSummary: String? {
        guard
            let setCount = targetSetCount,
            let minimum = targetMinimumRepetitions,
            let maximum = targetMaximumRepetitions
        else { return nil }

        let rirSummary = targetRIR.map { " · RIR \($0.formatted(.number.precision(.fractionLength(0...1))))" } ?? ""
        return "Objectif : \(setCount) × \(minimum)–\(maximum)\(rirSummary)"
    }

    func replaceExercise(with replacement: ExerciseRecord) {
        exercise = replacement
        exerciseIDSnapshot = replacement.id
        exerciseNameSnapshot = replacement.displayName
    }

    @discardableResult
    func removeSet(withID setID: UUID) -> WorkoutSetRecord? {
        guard let removed = sets.first(where: { $0.id == setID }) else { return nil }
        removed.workoutExercise = nil
        sets = sets.filter { $0.id != setID }
        for (index, remaining) in orderedSets.enumerated() {
            remaining.sortIndex = index
        }
        return removed
    }
}

@Model
final class WorkoutSetRecord {
    @Attribute(.unique) var id: UUID
    var workoutExercise: WorkoutExerciseRecord?
    var sortIndex: Int
    var loadKilograms: Double?
    var repetitions: Int?
    var rir: Double?
    var rpe: Double?
    var durationSeconds: Double?
    var distanceMeters: Double?
    var notes: String
    var kindRawValue: String
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        sortIndex: Int,
        loadKilograms: Double? = nil,
        repetitions: Int? = nil,
        rir: Double? = nil,
        rpe: Double? = nil,
        durationSeconds: Double? = nil,
        distanceMeters: Double? = nil,
        notes: String = "",
        kind: TrainingSetKind = .working,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.loadKilograms = loadKilograms
        self.repetitions = repetitions
        self.rir = rir
        self.rpe = rpe
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.notes = notes
        self.kindRawValue = kind.rawValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    var kind: TrainingSetKind {
        get { TrainingSetKind(rawValue: kindRawValue) ?? .working }
        set { kindRawValue = newValue.rawValue }
    }

    var snapshot: TrainingSetSnapshot {
        TrainingSetSnapshot(
            loadKilograms: loadKilograms,
            repetitions: repetitions,
            rir: rir,
            kind: kind,
            isCompleted: isCompleted
        )
    }
}

}

typealias CurrentSchema = ATLASchemaV3
typealias ExerciseRecord = ATLASchemaV1.ExerciseRecord
typealias ProgramRecord = ATLASchemaV1.ProgramRecord
typealias ProgramDayRecord = ATLASchemaV1.ProgramDayRecord
typealias ProgramExerciseRecord = ATLASchemaV1.ProgramExerciseRecord
typealias WorkoutRecord = ATLASchemaV1.WorkoutRecord
typealias WorkoutExerciseRecord = ATLASchemaV1.WorkoutExerciseRecord
typealias WorkoutSetRecord = ATLASchemaV1.WorkoutSetRecord
