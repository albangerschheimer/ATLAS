import Foundation

enum NutritionGoalKeys {
    static let energy = "nutrition.goal.energy"
    static let protein = "nutrition.goal.protein"
    static let carbohydrates = "nutrition.goal.carbohydrates"
    static let fat = "nutrition.goal.fat"
}

struct NutritionGoals: Equatable, Sendable {
    var energyKilocalories: Double
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double

    static let defaults = NutritionGoals(
        energyKilocalories: 2_700,
        proteinGrams: 160,
        carbohydrateGrams: 320,
        fatGrams: 80
    )
}

enum NutritionSummaryCalculator {
    static func totals(
        for day: Date,
        healthDays: [HealthNutritionDayValue],
        localEntries: [NutritionEntryRecord],
        calendar: Calendar = .current
    ) -> NutritionTotals {
        let health = healthDays
            .first(where: { calendar.isDate($0.day, inSameDayAs: day) })?
            .totals ?? NutritionTotals()
        let local = localEntries
            .filter { calendar.isDate($0.consumedAt, inSameDayAs: day) }
            .reduce(into: NutritionTotals()) { result, entry in
                result.energyKilocalories += entry.energyKilocalories
                result.proteinGrams += entry.proteinGrams
                result.carbohydrateGrams += entry.carbohydrateGrams
                result.fatGrams += entry.fatGrams
            }
        return health + local
    }

    static func availableMetrics(
        for day: Date,
        healthDays: [HealthNutritionDayValue],
        localEntries: [NutritionEntryRecord],
        calendar: Calendar = .current
    ) -> Set<HealthMetricKey> {
        let healthMetrics = healthDays
            .first(where: { calendar.isDate($0.day, inSameDayAs: day) })?
            .availableMetrics ?? []
        let hasLocalEntry = localEntries.contains {
            calendar.isDate($0.consumedAt, inSameDayAs: day)
        }
        guard hasLocalEntry else { return healthMetrics }
        return healthMetrics.union([
            .dietaryEnergy,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFat
        ])
    }
}
