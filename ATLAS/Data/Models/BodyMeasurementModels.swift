import Foundation
import SwiftData

enum BodyMeasurementSource: String, Codable, CaseIterable, Sendable {
    case manual
    case appleHealth
    case smartScale

    var frenchName: String {
        switch self {
        case .manual: "Saisie manuelle"
        case .appleHealth: "Apple Santé"
        case .smartScale: "Balance connectée"
        }
    }
}

enum BodyMetricKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case weight, bodyWater, muscleMass, bodyFat, bodyFatPercentage, boneMass, cellularIntegrity
    case fatFreeMass, visceralFat, basalMetabolicRate, totalDailyEnergyExpenditure
    case metabolicAge, legMuscleScore, bodyMassIndex, physiqueScore, boditraxScore
    case sarcopeniaScore, functionalMusclePercentage, proteinPercentage

    var id: String { rawValue }

    var frenchName: String {
        switch self {
        case .weight: "Poids"
        case .bodyWater: "Eau corporelle"
        case .muscleMass: "Masse musculaire"
        case .bodyFat: "Masse grasse"
        case .bodyFatPercentage: "Masse grasse (%)"
        case .boneMass: "Masse osseuse"
        case .cellularIntegrity: "Intégrité cellulaire"
        case .fatFreeMass: "Masse maigre"
        case .visceralFat: "Graisse viscérale"
        case .basalMetabolicRate: "Métabolisme basal"
        case .totalDailyEnergyExpenditure: "Dépense énergétique"
        case .metabolicAge: "Âge métabolique"
        case .legMuscleScore: "Score musculaire jambes"
        case .bodyMassIndex: "IMC"
        case .physiqueScore: "Score physique"
        case .boditraxScore: "Score Boditrax"
        case .sarcopeniaScore: "Score sarcopénie"
        case .functionalMusclePercentage: "Muscle fonctionnel"
        case .proteinPercentage: "Protéines"
        }
    }

    var unit: String {
        switch self {
        case .weight, .muscleMass, .bodyFat, .boneMass, .fatFreeMass: "kg"
        case .bodyWater, .bodyFatPercentage, .functionalMusclePercentage, .proteinPercentage: "%"
        case .basalMetabolicRate, .totalDailyEnergyExpenditure: "kcal"
        case .metabolicAge: "ans"
        case .bodyMassIndex: "IMC"
        default: "score"
        }
    }

    var symbol: String {
        switch self {
        case .weight: "scalemass.fill"
        case .bodyWater: "drop.fill"
        case .muscleMass, .legMuscleScore, .functionalMusclePercentage: "figure.strengthtraining.traditional"
        case .bodyFat, .bodyFatPercentage, .visceralFat: "circle.hexagongrid.fill"
        case .boneMass: "figure.walk"
        case .basalMetabolicRate, .totalDailyEnergyExpenditure: "flame.fill"
        case .metabolicAge: "calendar.badge.clock"
        case .bodyMassIndex: "ruler.fill"
        case .proteinPercentage: "leaf.fill"
        default: "waveform.path.ecg"
        }
    }
}

enum ATLASchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        ATLASchemaV2.models + [BodyMeasurementRecord.self]
    }

    @Model
    final class BodyMeasurementRecord {
        @Attribute(.unique) var id: UUID
        var metricRawValue: String
        var value: Double
        var measuredAt: Date
        var sourceRawValue: String
        var note: String
        var createdAt: Date

        init(
            id: UUID = UUID(),
            metric: BodyMetricKind,
            value: Double,
            measuredAt: Date = .now,
            source: BodyMeasurementSource = .manual,
            note: String = "",
            createdAt: Date = .now
        ) {
            self.id = id
            self.metricRawValue = metric.rawValue
            self.value = value
            self.measuredAt = measuredAt
            self.sourceRawValue = source.rawValue
            self.note = note
            self.createdAt = createdAt
        }

        var metric: BodyMetricKind {
            get { BodyMetricKind(rawValue: metricRawValue) ?? .weight }
            set { metricRawValue = newValue.rawValue }
        }

        var source: BodyMeasurementSource {
            get { BodyMeasurementSource(rawValue: sourceRawValue) ?? .manual }
            set { sourceRawValue = newValue.rawValue }
        }
    }
}

typealias BodyMeasurementRecord = ATLASchemaV3.BodyMeasurementRecord
