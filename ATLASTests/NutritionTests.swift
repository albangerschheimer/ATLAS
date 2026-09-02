import Foundation
import XCTest
@testable import ATLAS

final class NutritionTests: XCTestCase {
    @MainActor
    func testLocalEntriesAreAddedToHealthTotalsWithoutReplacingThem() {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let health = HealthNutritionDayValue(
            day: calendar.startOfDay(for: day),
            totals: NutritionTotals(
                energyKilocalories: 1_200,
                proteinGrams: 80,
                carbohydrateGrams: 130,
                fatGrams: 40
            ),
            sources: ["Foodvisor"],
            availableMetrics: [.dietaryEnergy, .dietaryProtein, .dietaryCarbohydrates, .dietaryFat]
        )
        let local = NutritionEntryRecord(
            name: "Collation",
            consumedAt: day,
            energyKilocalories: 300,
            proteinGrams: 25,
            carbohydrateGrams: 35,
            fatGrams: 8
        )

        let totals = NutritionSummaryCalculator.totals(
            for: day,
            healthDays: [health],
            localEntries: [local],
            calendar: calendar
        )

        XCTAssertEqual(totals.energyKilocalories, 1_500)
        XCTAssertEqual(totals.proteinGrams, 105)
        XCTAssertEqual(totals.carbohydrateGrams, 165)
        XCTAssertEqual(totals.fatGrams, 48)
        XCTAssertEqual(
            NutritionSummaryCalculator.availableMetrics(
                for: day,
                healthDays: [health],
                localEntries: [local],
                calendar: calendar
            ),
            [.dietaryEnergy, .dietaryProtein, .dietaryCarbohydrates, .dietaryFat]
        )
    }

    @MainActor
    func testMissingHealthNutrientIsNotPresentedAsARealZero() {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let health = HealthNutritionDayValue(
            day: calendar.startOfDay(for: day),
            totals: NutritionTotals(energyKilocalories: 900),
            sources: ["Foodvisor"],
            availableMetrics: [.dietaryEnergy]
        )

        let available = NutritionSummaryCalculator.availableMetrics(
            for: day,
            healthDays: [health],
            localEntries: [],
            calendar: calendar
        )

        XCTAssertTrue(available.contains(.dietaryEnergy))
        XCTAssertFalse(available.contains(.dietaryProtein))
    }

    func testOpenFoodFactsResponseUsesNormalizedPerHundredGramValues() throws {
        let json = Data(#"""
        {
          "code":"3017620422003",
          "product":{
            "product_name":"Produit test",
            "brands":"Marque",
            "serving_quantity":30,
            "nutriments":{
              "energy-kcal_100g":539,
              "proteins_100g":6.3,
              "carbohydrates_100g":57.5,
              "fat_100g":30.9
            }
          }
        }
        """#.utf8)

        let product = try OpenFoodFactsClient.decodeProduct(json, fallbackBarcode: "fallback")

        XCTAssertEqual(product.barcode, "3017620422003")
        XCTAssertEqual(product.displayName, "Produit test · Marque")
        XCTAssertEqual(product.servingQuantityGrams, 30)
        XCTAssertEqual(product.perHundredGrams.energyKilocalories, 539)
        XCTAssertEqual(product.perHundredGrams.proteinGrams, 6.3)
    }

    func testOpenFoodFactsCachePersistsPreviouslyLoadedProduct() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("atlas-food-cache-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("products.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let product = OpenFoodProduct(
            barcode: "3017620422003",
            name: "Produit hors ligne",
            brand: nil,
            servingQuantityGrams: 100,
            perHundredGrams: NutritionTotals(energyKilocalories: 250)
        )

        let firstCache = OpenFoodFactsProductCache(fileURL: fileURL)
        await firstCache.store(product)
        let reopenedCache = OpenFoodFactsProductCache(fileURL: fileURL)

        let restored = await reopenedCache.product(for: product.barcode)
        XCTAssertEqual(restored, product)
    }
}
