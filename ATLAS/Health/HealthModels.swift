import Foundation

enum HealthMetricKey: String, CaseIterable, Codable, Sendable {
    case sleep
    case restingHeartRate
    case restingHeartRateBaseline
    case latestHeartRate
    case steps
    case walkingRunningDistance
    case activeEnergy
    case bodyMass
    case bodyFatPercentage
    case leanBodyMass
    case bodyMassIndex
    case dietaryEnergy
    case dietaryProtein
    case dietaryCarbohydrates
    case dietaryFat
}

enum HealthValueAvailability: String, Codable, Sendable {
    case available
    case permissionNotRequested
    case noData
    case healthUnavailable
    case failed
}

struct HealthMetricValue: Equatable, Codable, Sendable {
    let key: HealthMetricKey
    let value: Double?
    let unit: String
    let startDate: Date?
    let endDate: Date?
    let source: String?
    let availability: HealthValueAvailability

    static func missing(
        _ key: HealthMetricKey,
        unit: String,
        availability: HealthValueAvailability
    ) -> HealthMetricValue {
        HealthMetricValue(
            key: key,
            value: nil,
            unit: unit,
            startDate: nil,
            endDate: nil,
            source: nil,
            availability: availability
        )
    }
}

enum HealthSportKind: String, Codable, CaseIterable, Sendable {
    case running
    case cycling
    case swimming
    case basketball
    case strength
    case other

    var frenchName: String {
        switch self {
        case .running: "Course"
        case .cycling: "Vélo"
        case .swimming: "Natation"
        case .basketball: "Basket"
        case .strength: "Musculation"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .running: "figure.run"
        case .cycling: "bicycle"
        case .swimming: "figure.pool.swim"
        case .basketball: "basketball.fill"
        case .strength: "dumbbell.fill"
        case .other: "figure.mixed.cardio"
        }
    }
}

struct HealthWorkoutValue: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let sport: HealthSportKind
    let startedAt: Date
    let durationSeconds: TimeInterval
    let source: String
    let sourceBundleIdentifier: String?
    let distanceMeters: Double?
    let energyKilocalories: Double?
    let contributingSources: [String]

    init(
        id: UUID,
        sport: HealthSportKind,
        startedAt: Date,
        durationSeconds: TimeInterval,
        source: String,
        sourceBundleIdentifier: String? = nil,
        distanceMeters: Double? = nil,
        energyKilocalories: Double? = nil,
        contributingSources: [String] = []
    ) {
        self.id = id
        self.sport = sport
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.source = source
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.distanceMeters = distanceMeters
        self.energyKilocalories = energyKilocalories
        self.contributingSources = contributingSources.isEmpty ? [source] : contributingSources
    }
}

struct NutritionTotals: Equatable, Codable, Sendable {
    var energyKilocalories: Double = 0
    var proteinGrams: Double = 0
    var carbohydrateGrams: Double = 0
    var fatGrams: Double = 0

    static func + (lhs: NutritionTotals, rhs: NutritionTotals) -> NutritionTotals {
        NutritionTotals(
            energyKilocalories: lhs.energyKilocalories + rhs.energyKilocalories,
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbohydrateGrams: lhs.carbohydrateGrams + rhs.carbohydrateGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams
        )
    }
}

struct HealthNutritionDayValue: Identifiable, Equatable, Codable, Sendable {
    var id: Date { day }
    let day: Date
    let totals: NutritionTotals
    let sources: [String]
    let availableMetrics: Set<HealthMetricKey>

    init(
        day: Date,
        totals: NutritionTotals,
        sources: [String],
        availableMetrics: Set<HealthMetricKey> = []
    ) {
        self.day = day
        self.totals = totals
        self.sources = sources
        self.availableMetrics = availableMetrics
    }
}

struct HealthSnapshot: Equatable, Codable, Sendable {
    let generatedAt: Date
    let metrics: [HealthMetricKey: HealthMetricValue]
    let workouts: [HealthWorkoutValue]
    let healthDataAvailable: Bool
    let nutritionDays: [HealthNutritionDayValue]

    init(
        generatedAt: Date,
        metrics: [HealthMetricKey: HealthMetricValue],
        workouts: [HealthWorkoutValue],
        healthDataAvailable: Bool,
        nutritionDays: [HealthNutritionDayValue] = []
    ) {
        self.generatedAt = generatedAt
        self.metrics = metrics
        self.workouts = workouts
        self.healthDataAvailable = healthDataAvailable
        self.nutritionDays = nutritionDays
    }

    subscript(_ key: HealthMetricKey) -> HealthMetricValue {
        metrics[key] ?? .missing(key, unit: "", availability: .noData)
    }

    static func empty(
        availability: HealthValueAvailability,
        generatedAt: Date = .now,
        healthDataAvailable: Bool = true
    ) -> HealthSnapshot {
        let units: [HealthMetricKey: String] = [
            .sleep: "h",
            .restingHeartRate: "bpm",
            .restingHeartRateBaseline: "bpm",
            .latestHeartRate: "bpm",
            .steps: "pas",
            .walkingRunningDistance: "km",
            .activeEnergy: "kcal",
            .bodyMass: "kg",
            .bodyFatPercentage: "%",
            .leanBodyMass: "kg",
            .bodyMassIndex: "IMC",
            .dietaryEnergy: "kcal",
            .dietaryProtein: "g",
            .dietaryCarbohydrates: "g",
            .dietaryFat: "g"
        ]
        return HealthSnapshot(
            generatedAt: generatedAt,
            metrics: Dictionary(uniqueKeysWithValues: HealthMetricKey.allCases.map { key in
                (key, .missing(key, unit: units[key] ?? "", availability: availability))
            }),
            workouts: [],
            healthDataAvailable: healthDataAvailable,
            nutritionDays: []
        )
    }
}
