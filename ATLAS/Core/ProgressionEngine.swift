import Foundation

enum ProgressionAction: Equatable, Sendable {
    case increaseLoad(toKilograms: Double)
    case keepLoad
    case insufficientData
}

struct ProgressionRecommendation: Equatable, Sendable {
    var action: ProgressionAction
    var explanation: String
}

enum ProgressionEngine {
    static func doubleProgression(
        sets: [TrainingSetSnapshot],
        prescribedSetCount: Int,
        topOfRepRange: Int,
        targetRIR: Double,
        currentLoadKilograms: Double,
        loadIncrementKilograms: Double
    ) -> ProgressionRecommendation {
        let workingSets = sets.filter { $0.kind == .working && $0.isCompleted }

        guard
            prescribedSetCount > 0,
            workingSets.count >= prescribedSetCount,
            topOfRepRange > 0,
            currentLoadKilograms > 0,
            loadIncrementKilograms > 0,
            workingSets.allSatisfy({ $0.repetitions != nil && $0.rir != nil })
        else {
            return ProgressionRecommendation(
                action: .insufficientData,
                explanation: "Il manque des séries complètes, des répétitions ou le RIR cible."
            )
        }

        let relevantSets = Array(workingSets.prefix(prescribedSetCount))
        let targetReached = relevantSets.allSatisfy { set in
            (set.repetitions ?? 0) >= topOfRepRange && (set.rir ?? -.infinity) >= targetRIR
        }

        if targetReached {
            return ProgressionRecommendation(
                action: .increaseLoad(toKilograms: currentLoadKilograms + loadIncrementKilograms),
                explanation: "Toutes les séries ont atteint le haut de la plage avec le RIR prévu."
            )
        }

        return ProgressionRecommendation(
            action: .keepLoad,
            explanation: "La plage haute ou le RIR cible n’est pas encore atteint sur chaque série."
        )
    }
}
