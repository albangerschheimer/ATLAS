import Foundation
import SwiftData

enum NutritionEntrySource: String, Codable, CaseIterable {
    case manual
    case barcode

    var frenchName: String {
        switch self {
        case .manual: "Saisie manuelle"
        case .barcode: "Open Food Facts"
        }
    }
}

enum ATLASchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        ATLASchemaV1.models + [NutritionEntryRecord.self]
    }

    @Model
    final class NutritionEntryRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var consumedAt: Date
        var energyKilocalories: Double
        var proteinGrams: Double
        var carbohydrateGrams: Double
        var fatGrams: Double
        var servingGrams: Double?
        var barcode: String?
        var sourceRawValue: String
        var createdAt: Date

        init(
            id: UUID = UUID(),
            name: String,
            consumedAt: Date = .now,
            energyKilocalories: Double,
            proteinGrams: Double = 0,
            carbohydrateGrams: Double = 0,
            fatGrams: Double = 0,
            servingGrams: Double? = nil,
            barcode: String? = nil,
            source: NutritionEntrySource = .manual,
            createdAt: Date = .now
        ) {
            self.id = id
            self.name = name
            self.consumedAt = consumedAt
            self.energyKilocalories = energyKilocalories
            self.proteinGrams = proteinGrams
            self.carbohydrateGrams = carbohydrateGrams
            self.fatGrams = fatGrams
            self.servingGrams = servingGrams
            self.barcode = barcode
            self.sourceRawValue = source.rawValue
            self.createdAt = createdAt
        }

        var source: NutritionEntrySource {
            get { NutritionEntrySource(rawValue: sourceRawValue) ?? .manual }
            set { sourceRawValue = newValue.rawValue }
        }
    }
}

typealias NutritionEntryRecord = ATLASchemaV2.NutritionEntryRecord
