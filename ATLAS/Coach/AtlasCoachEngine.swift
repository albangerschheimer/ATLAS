import Foundation

enum AtlasCoachPriority: Int, Comparable, Sendable {
    case information, attention, important
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct AtlasCoachInsight: Identifiable, Equatable, Sendable {
    let id: String
    let priority: AtlasCoachPriority
    let title: String
    let message: String
    let action: String?
}

struct AtlasCoachContext: Sendable {
    let readinessScore: Int?
    let restingHeartRate: Double?
    let restingBaseline: Double?
    let sleepHours: Double?
    let strengthSessionsThisWeek: Int
    let enduranceSessionsThisWeek: Int
    let trainingDays: [Date]
    let proteinToday: Double?
    let proteinGoal: Double
    let currentHour: Int

    var promptSummary: String {
        """
        readiness=\(readinessScore.map(String.init) ?? "indisponible")/100
        restingHeartRate=\(restingHeartRate.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "indisponible")
        restingBaseline=\(restingBaseline.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "indisponible")
        sleepHours=\(sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "optionnel/indisponible")
        strengthSessionsThisWeek=\(strengthSessionsThisWeek)
        otherSportsThisWeek=\(enduranceSessionsThisWeek)
        proteinToday=\(proteinToday.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "indisponible") goal=\(proteinGoal.formatted(.number.precision(.fractionLength(0))))
        """
    }
}

enum AtlasCoachEngine {
    static func insights(for context: AtlasCoachContext, calendar: Calendar = .current) -> [AtlasCoachInsight] {
        var result: [AtlasCoachInsight] = []

        if let score = context.readinessScore, score < 45 {
            result.append(.init(id: "readiness-low", priority: .important, title: "Récupération basse", message: "Les signaux disponibles suggèrent de réduire l’intensité aujourd’hui. Une séance technique ou plus courte est plus prudente.", action: "Réduire les séries proches de l’échec"))
        } else if let score = context.readinessScore, score >= 75 {
            result.append(.init(id: "readiness-high", priority: .information, title: "Bonne disponibilité", message: "Les signaux de récupération disponibles sont favorables. Vous pouvez suivre la progression prévue si vos sensations le confirment.", action: nil))
        }

        if let current = context.restingHeartRate, let baseline = context.restingBaseline, baseline > 0, current >= baseline * 1.10 {
            result.append(.init(id: "resting-hr-high", priority: .important, title: "Fréquence au repos élevée", message: "Votre fréquence au repos est environ \(((current / baseline - 1) * 100).formatted(.number.precision(.fractionLength(0)))) % au-dessus de sa référence. Surveillez surtout vos sensations et la tendance sur plusieurs jours.", action: "Éviter un test maximal aujourd’hui"))
        }

        if let sleep = context.sleepHours, sleep < 6 {
            result.append(.init(id: "short-sleep", priority: .attention, title: "Nuit courte", message: "Le sommeil disponible indique \(sleep.formatted(.number.precision(.fractionLength(1)))) h. Cette donnée reste optionnelle, mais elle invite à garder davantage de répétitions en réserve.", action: "Conserver 2–3 RIR"))
        }

        let recentDays = Set(context.trainingDays.map { calendar.startOfDay(for: $0) })
        let consecutive = (0..<4).allSatisfy { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { return false }
            return recentDays.contains(calendar.startOfDay(for: day))
        }
        if consecutive {
            result.append(.init(id: "four-days", priority: .attention, title: "Quatre jours actifs d’affilée", message: "La charge s’accumule même quand les sports sont différents. Une journée légère peut améliorer la qualité de la prochaine séance.", action: "Planifier récupération ou mobilité"))
        }

        let total = context.strengthSessionsThisWeek + context.enduranceSessionsThisWeek
        if total >= 6 {
            result.append(.init(id: "dense-week", priority: .attention, title: "Semaine dense", message: "ATLAS compte \(total) activités cette semaine. Gardez au moins une vraie fenêtre de récupération si la fatigue ou les performances se dégradent.", action: nil))
        }

        if context.currentHour >= 18, let protein = context.proteinToday, context.proteinGoal > 0, protein < context.proteinGoal * 0.65 {
            result.append(.init(id: "protein-low", priority: .information, title: "Protéines sous l’objectif", message: "À cette heure, \(protein.formatted(.number.precision(.fractionLength(0)))) g sont enregistrés sur \(context.proteinGoal.formatted(.number.precision(.fractionLength(0)))) g. Vérifiez surtout que Foodvisor a fini de synchroniser Apple Santé.", action: "Actualiser les données nutrition"))
        }

        if result.isEmpty {
            result.append(.init(id: "steady", priority: .information, title: "Aucun signal de vigilance", message: "Le moteur local ATLAS n’a relevé ni récupération basse, ni hausse inhabituelle du rythme au repos, ni semaine trop chargée. Suivez la séance prévue si l’échauffement et vos sensations sont normaux.", action: nil))
        }
        return result.sorted { $0.priority > $1.priority }
    }

    static func fallbackAnswer(to question: String, insights: [AtlasCoachInsight]) -> String {
        let normalized = question.lowercased()
        if normalized.contains("repos") || normalized.contains("récup") || normalized.contains("fatigue") {
            return insights.first(where: { $0.id == "readiness-low" || $0.id == "four-days" || $0.id == "dense-week" })?.message
                ?? "Aucune alerte de récupération n’est déclenchée. Regardez tout de même vos sensations, votre envie de vous entraîner et la qualité de l’échauffement."
        }
        if normalized.contains("séance") || normalized.contains("entraîner") || normalized.contains("entrainer") {
            return insights.first?.message ?? "Suivez la séance prévue, puis réduisez le volume si l’échauffement semble inhabituellement difficile."
        }
        if normalized.contains("proté") || normalized.contains("nutrition") {
            return insights.first(where: { $0.id == "protein-low" })?.message
                ?? "ATLAS ne voit pas d’alerte nutritionnelle actuellement. Les données Foodvisor peuvent arriver avec un léger délai via Apple Santé."
        }
        return "D’après les règles ATLAS, le point principal est : \(insights.first?.message ?? "aucune alerte particulière"). Je ne pose pas de diagnostic médical."
    }
}
