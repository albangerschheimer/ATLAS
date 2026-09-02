import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AtlasAIAvailability: Equatable, Sendable {
    case checking
    case available
    case appleIntelligenceDisabled
    case deviceNotEligible
    case modelNotReady
    case unsupportedOS
    case unknown

    var title: String {
        switch self {
        case .checking: "Vérification d’Apple Intelligence…"
        case .available: "Apple Intelligence actif"
        case .appleIntelligenceDisabled: "Apple Intelligence désactivé"
        case .deviceNotEligible: "Apple Intelligence non compatible"
        case .modelNotReady: "Modèle Apple en préparation"
        case .unsupportedOS: "Moteur ATLAS local"
        case .unknown: "Apple Intelligence indisponible"
        }
    }

    var detail: String {
        switch self {
        case .checking: "ATLAS vérifie le modèle présent sur cet iPhone."
        case .available: "Vos questions sont reformulées par le modèle Apple, directement sur l’iPhone."
        case .appleIntelligenceDisabled: "Activez Apple Intelligence dans Réglages pour les réponses génératives. Les règles ATLAS restent disponibles."
        case .deviceNotEligible: "Cet appareil ne prend pas en charge le modèle Apple. Les règles ATLAS continuent de fonctionner hors ligne."
        case .modelNotReady: "Le modèle se télécharge ou se prépare. ATLAS utilise ses règles locales en attendant."
        case .unsupportedOS: "Les conseils proviennent des règles déterministes d’ATLAS."
        case .unknown: "ATLAS utilise ses règles locales jusqu’à ce que le modèle Apple soit disponible."
        }
    }

    var usesAppleIntelligence: Bool { self == .available }
}

enum AtlasOnDeviceCoach {
    static func availability() -> AtlasAIAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.appleIntelligenceNotEnabled):
                return .appleIntelligenceDisabled
            case .unavailable(.deviceNotEligible):
                return .deviceNotEligible
            case .unavailable(.modelNotReady):
                return .modelNotReady
            case .unavailable:
                return .unknown
            }
        }
        #endif
        return .unsupportedOS
    }

    static func answer(question: String, context: AtlasCoachContext, insights: [AtlasCoachInsight]) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard availability() == .available else { return nil }
            let session = LanguageModelSession(model: model, instructions: """
                Tu es le coach ATLAS. Réponds en français, en 2 à 5 phrases claires.
                Utilise exclusivement les données fournies et les alertes déterministes.
                Ne pose jamais de diagnostic, ne prescris aucun traitement et signale l’incertitude.
                Le sommeil est optionnel : son absence ne doit jamais bloquer une réponse.
                Ne prétends jamais avoir modifié le programme ou les données.
                """)
            let alertText = insights.map { "\($0.title): \($0.message)" }.joined(separator: "\n")
            do {
                let response = try await session.respond(to: """
                    Données locales :
                    \(context.promptSummary)
                    Alertes calculées :
                    \(alertText)
                    Question : \(question)
                    """)
                return response.content
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
}
