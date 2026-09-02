import Foundation

struct ReadinessResult: Equatable, Sendable {
    enum Level: String, Sendable {
        case high
        case moderate
        case low

        var frenchName: String {
            switch self {
            case .high: "Élevée"
            case .moderate: "Modérée"
            case .low: "Basse"
            }
        }
    }

    let score: Int
    let level: Level
    let explanations: [String]
    let confidence: String
}

enum ReadinessEngine {
    static func evaluate(snapshot: HealthSnapshot) -> ReadinessResult? {
        guard
            let restingHeartRate = snapshot[.restingHeartRate].value,
            let baseline = snapshot[.restingHeartRateBaseline].value,
            baseline > 0
        else { return nil }

        let sleepHours = snapshot[.sleep].value
        let sleepPenalty: Double
        if let sleepHours {
            if sleepHours >= 8 {
                sleepPenalty = 0
            } else if sleepHours >= 7 {
                sleepPenalty = (8 - sleepHours) * 5
            } else {
                sleepPenalty = min(35, 5 + (7 - sleepHours) * 10)
            }
        } else {
            sleepPenalty = 0
        }

        let heartRateDelta = restingHeartRate - baseline
        let heartRatePenalty: Double
        if heartRateDelta <= 0 {
            heartRatePenalty = 0
        } else if heartRateDelta <= 3 {
            heartRatePenalty = heartRateDelta * 2
        } else {
            heartRatePenalty = min(30, 6 + (heartRateDelta - 3) * 4)
        }

        let score = max(0, min(100, Int((100 - sleepPenalty - heartRatePenalty).rounded())))
        let level: ReadinessResult.Level = if score >= 80 {
            .high
        } else if score >= 60 {
            .moderate
        } else {
            .low
        }

        var explanations = [String]()
        if let sleepHours {
            explanations.append(
                sleepHours >= 7
                    ? "Sommeil : \(sleepHours.formatted(.number.precision(.fractionLength(1)))) h."
                    : "Sommeil court : \(sleepHours.formatted(.number.precision(.fractionLength(1)))) h."
            )
        } else {
            explanations.append("Sommeil non disponible · non inclus dans le score.")
        }
        if heartRateDelta > 2 {
            explanations.append(
                "Fréquence au repos à +\(heartRateDelta.formatted(.number.precision(.fractionLength(0...1)))) bpm de la moyenne sur 7 jours."
            )
        } else {
            explanations.append("Fréquence au repos proche de la moyenne sur 7 jours.")
        }

        return ReadinessResult(
            score: score,
            level: level,
            explanations: explanations,
            confidence: sleepHours == nil
                ? "Limitée · fréquence cardiaque au repos uniquement"
                : "Modérée · sommeil et fréquence cardiaque au repos"
        )
    }
}
