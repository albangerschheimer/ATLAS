import Foundation

enum ExerciseMovementPattern: String, Sendable {
    case horizontalPush, verticalPush, horizontalPull, verticalPull, squat, hinge, isolation, carry, locomotion
}

struct ExerciseSimilarity: Identifiable {
    let exercise: ExerciseRecord
    let percentage: Int
    var id: UUID { exercise.id }
}

enum ExerciseSimilarityEngine {
    static func pattern(name: String, muscles: [MuscleGroup]) -> ExerciseMovementPattern {
        let value = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if value.contains("pulldown") || value.contains("pull-up") || value.contains("traction") { return .verticalPull }
        if value.contains("row") || value.contains("tirage horizontal") { return .horizontalPull }
        if value.contains("overhead") || value.contains("shoulder press") || value.contains("militaire") { return .verticalPush }
        if value.contains("press") || value.contains("développé") || value.contains("pompe") { return .horizontalPush }
        if value.contains("squat") || value.contains("leg press") || value.contains("presse") { return .squat }
        if value.contains("deadlift") || value.contains("soulevé") || value.contains("hip thrust") { return .hinge }
        return .isolation
    }

    static func recommendations(for source: ExerciseRecord, among exercises: [ExerciseRecord]) -> [ExerciseSimilarity] {
        let sourcePrimary = Set(source.primaryMuscles)
        let sourceSecondary = Set(source.secondaryMuscles)
        let sourcePattern = pattern(name: source.nameEnglish + " " + source.nameFrench, muscles: source.primaryMuscles.compactMap(MuscleGroup.init))
        return exercises.filter { $0.id != source.id }.compactMap { candidate in
            let primary = Set(candidate.primaryMuscles)
            let secondary = Set(candidate.secondaryMuscles)
            let primaryScore = sourcePrimary.isEmpty ? 0 : Double(sourcePrimary.intersection(primary).count) / Double(sourcePrimary.count) * 55
            let secondaryScore = sourceSecondary.isEmpty ? 10 : Double(sourceSecondary.intersection(secondary).count) / Double(sourceSecondary.count) * 15
            let candidatePattern = pattern(name: candidate.nameEnglish + " " + candidate.nameFrench, muscles: candidate.primaryMuscles.compactMap(MuscleGroup.init))
            let patternScore = candidatePattern == sourcePattern ? 20.0 : 0
            let equipmentScore = candidate.equipment == source.equipment ? 10.0 : 4.0
            let total = Int((primaryScore + secondaryScore + patternScore + equipmentScore).rounded())
            return total >= 45 ? ExerciseSimilarity(exercise: candidate, percentage: min(total, 99)) : nil
        }.sorted { $0.percentage > $1.percentage }
    }
}
