import Foundation
@preconcurrency import HealthKit

@MainActor
final class HealthKitDataProvider: HealthDataProvider {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        calendar: Calendar = .current
    ) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else { throw HealthKitProviderError.unavailable }
        let readTypes = healthTypes

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitProviderError.authorizationNotCompleted)
                }
            }
        }
    }

    func loadSnapshot(week: DateInterval, now: Date = .now) async -> HealthSnapshot {
        guard isHealthDataAvailable else {
            return .empty(
                availability: .healthUnavailable,
                generatedAt: now,
                healthDataAvailable: false
            )
        }

        let today = DateInterval(start: calendar.startOfDay(for: now), end: now)
        let lastDay = DateInterval(start: now.addingTimeInterval(-86_400), end: now)
        let lastWeek = DateInterval(start: now.addingTimeInterval(-7 * 86_400), end: now)
        let lastYear = DateInterval(start: now.addingTimeInterval(-365 * 86_400), end: now)

        var metrics = [HealthMetricKey: HealthMetricValue]()
        metrics[.sleep] = await recover(.sleep, unit: "h") {
            try await self.sleepMetric(in: lastDay)
        }
        metrics[.restingHeartRate] = await recover(.restingHeartRate, unit: "bpm") {
            try await self.latestQuantityMetric(
                key: .restingHeartRate,
                identifier: .restingHeartRate,
                unit: .count().unitDivided(by: .minute()),
                unitLabel: "bpm",
                interval: lastWeek
            )
        }
        metrics[.restingHeartRateBaseline] = await recover(.restingHeartRateBaseline, unit: "bpm") {
            try await self.averageQuantityMetric(
                key: .restingHeartRateBaseline,
                identifier: .restingHeartRate,
                unit: .count().unitDivided(by: .minute()),
                unitLabel: "bpm",
                interval: lastWeek
            )
        }
        metrics[.latestHeartRate] = await recover(.latestHeartRate, unit: "bpm") {
            try await self.latestQuantityMetric(
                key: .latestHeartRate,
                identifier: .heartRate,
                unit: .count().unitDivided(by: .minute()),
                unitLabel: "bpm",
                interval: lastDay
            )
        }
        metrics[.steps] = await recover(.steps, unit: "pas") {
            try await self.cumulativeQuantityMetric(
                key: .steps,
                identifier: .stepCount,
                unit: .count(),
                unitLabel: "pas",
                interval: today
            )
        }
        metrics[.walkingRunningDistance] = await recover(.walkingRunningDistance, unit: "km") {
            try await self.cumulativeQuantityMetric(
                key: .walkingRunningDistance,
                identifier: .distanceWalkingRunning,
                unit: .meterUnit(with: .kilo),
                unitLabel: "km",
                interval: today
            )
        }
        metrics[.activeEnergy] = await recover(.activeEnergy, unit: "kcal") {
            try await self.cumulativeQuantityMetric(
                key: .activeEnergy,
                identifier: .activeEnergyBurned,
                unit: .kilocalorie(),
                unitLabel: "kcal",
                interval: today
            )
        }
        metrics[.bodyMass] = await recover(.bodyMass, unit: "kg") {
            try await self.latestQuantityMetric(
                key: .bodyMass,
                identifier: .bodyMass,
                unit: .gramUnit(with: .kilo),
                unitLabel: "kg",
                interval: lastYear
            )
        }
        metrics[.bodyFatPercentage] = await recover(.bodyFatPercentage, unit: "%") {
            try await self.latestQuantityMetric(
                key: .bodyFatPercentage,
                identifier: .bodyFatPercentage,
                unit: .percent(),
                unitLabel: "%",
                interval: lastYear,
                multiplier: 100
            )
        }
        metrics[.leanBodyMass] = await recover(.leanBodyMass, unit: "kg") {
            try await self.latestQuantityMetric(
                key: .leanBodyMass,
                identifier: .leanBodyMass,
                unit: .gramUnit(with: .kilo),
                unitLabel: "kg",
                interval: lastYear
            )
        }
        metrics[.bodyMassIndex] = await recover(.bodyMassIndex, unit: "IMC") {
            try await self.latestQuantityMetric(
                key: .bodyMassIndex,
                identifier: .bodyMassIndex,
                unit: .count(),
                unitLabel: "IMC",
                interval: lastYear
            )
        }

        let workouts = HealthActivityCanonicalizer.canonicalize(
            (try? await workoutValues(in: week)) ?? []
        )
        let nutritionDays = (try? await nutritionValues(in: lastWeek)) ?? []
        return HealthSnapshot(
            generatedAt: now,
            metrics: metrics,
            workouts: workouts,
            healthDataAvailable: true,
            nutritionDays: nutritionDays
        )
    }

    private var healthTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        [
            HKQuantityTypeIdentifier.heartRate,
            .restingHeartRate,
            .stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .bodyMass,
            .bodyFatPercentage,
            .leanBodyMass,
            .bodyMassIndex,
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal
        ]
        .compactMap { HKObjectType.quantityType(forIdentifier: $0) }
        .forEach { types.insert($0) }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        return types
    }

    private func recover(
        _ key: HealthMetricKey,
        unit: String,
        operation: () async throws -> HealthMetricValue
    ) async -> HealthMetricValue {
        do {
            return try await operation()
        } catch {
            return .missing(key, unit: unit, availability: .failed)
        }
    }

    private func latestQuantityMetric(
        key: HealthMetricKey,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        unitLabel: String,
        interval: DateInterval,
        multiplier: Double = 1
    ) async throws -> HealthMetricValue {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return .missing(key, unit: unitLabel, availability: .healthUnavailable)
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: [.strictStartDate]
        )
        guard let sample = try await latestQuantitySample(type: type, predicate: predicate) else {
            return .missing(key, unit: unitLabel, availability: .noData)
        }
        return HealthMetricValue(
            key: key,
            value: sample.quantity.doubleValue(for: unit) * multiplier,
            unit: unitLabel,
            startDate: sample.startDate,
            endDate: sample.endDate,
            source: sample.sourceRevision.source.name,
            availability: .available
        )
    }

    func loadBodyMeasurements(since: Date, now: Date) async -> [HealthBodyMeasurementSample] {
        guard isHealthDataAvailable else { return [] }
        let interval = DateInterval(start: since, end: now)
        let definitions: [(HKQuantityTypeIdentifier, BodyMetricKind, HKUnit, Double)] = [
            (.bodyMass, .weight, .gramUnit(with: .kilo), 1),
            (.bodyFatPercentage, .bodyFatPercentage, .percent(), 100),
            (.leanBodyMass, .fatFreeMass, .gramUnit(with: .kilo), 1),
            (.bodyMassIndex, .bodyMassIndex, .count(), 1)
        ]

        var result = [HealthBodyMeasurementSample]()
        for (identifier, metric, unit, multiplier) in definitions {
            guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { continue }
            let predicate = HKQuery.predicateForSamples(
                withStart: interval.start,
                end: interval.end,
                options: [.strictStartDate]
            )
            let samples = (try? await sampleValues(
                type: type,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            )) ?? []
            for sample in samples.compactMap({ $0 as? HKQuantitySample }) {
                let value = sample.quantity.doubleValue(for: unit) * multiplier
                guard value.isFinite, value > 0 else { continue }
                result.append(HealthBodyMeasurementSample(
                    id: sample.uuid,
                    metric: metric,
                    value: value,
                    measuredAt: sample.endDate,
                    source: sample.sourceRevision.source.name
                ))
            }
        }
        return result.sorted { $0.measuredAt < $1.measuredAt }
    }

    private func cumulativeQuantityMetric(
        key: HealthMetricKey,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        unitLabel: String,
        interval: DateInterval
    ) async throws -> HealthMetricValue {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return .missing(key, unit: unitLabel, availability: .healthUnavailable)
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: [.strictStartDate]
        )
        let statistics = try await statistics(type: type, predicate: predicate, options: .cumulativeSum)
        guard let quantity = statistics?.sumQuantity() else {
            return .missing(key, unit: unitLabel, availability: .noData)
        }
        let latestSample = try await latestQuantitySample(type: type, predicate: predicate)
        let source = latestSample?.sourceRevision.source.name ?? "Apple Santé"
        return HealthMetricValue(
            key: key,
            value: quantity.doubleValue(for: unit),
            unit: unitLabel,
            startDate: interval.start,
            endDate: interval.end,
            source: source,
            availability: .available
        )
    }

    private func averageQuantityMetric(
        key: HealthMetricKey,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        unitLabel: String,
        interval: DateInterval
    ) async throws -> HealthMetricValue {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return .missing(key, unit: unitLabel, availability: .healthUnavailable)
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: [.strictStartDate]
        )
        let statistics = try await statistics(type: type, predicate: predicate, options: .discreteAverage)
        guard let quantity = statistics?.averageQuantity() else {
            return .missing(key, unit: unitLabel, availability: .noData)
        }
        return HealthMetricValue(
            key: key,
            value: quantity.doubleValue(for: unit),
            unit: unitLabel,
            startDate: interval.start,
            endDate: interval.end,
            source: "Apple Santé · moyenne 7 jours",
            availability: .available
        )
    }

    private func sleepMetric(in interval: DateInterval) async throws -> HealthMetricValue {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return .missing(.sleep, unit: "h", availability: .healthUnavailable)
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: []
        )
        let samples = try await sampleValues(type: type, predicate: predicate)
            .compactMap { $0 as? HKCategorySample }
            .filter { [1, 3, 4, 5].contains($0.value) }
        guard !samples.isEmpty else {
            return .missing(.sleep, unit: "h", availability: .noData)
        }

        let groups = Dictionary(grouping: samples) {
            $0.sourceRevision.source.bundleIdentifier
        }
        guard let bestGroup = groups.values.max(by: { sleepDuration($0, in: interval) < sleepDuration($1, in: interval) }) else {
            return .missing(.sleep, unit: "h", availability: .noData)
        }
        let duration = sleepDuration(bestGroup, in: interval)
        return HealthMetricValue(
            key: .sleep,
            value: duration / 3_600,
            unit: "h",
            startDate: bestGroup.map(\.startDate).min(),
            endDate: bestGroup.map(\.endDate).max(),
            source: bestGroup.first?.sourceRevision.source.name,
            availability: .available
        )
    }

    private func sleepDuration(_ samples: [HKCategorySample], in interval: DateInterval) -> TimeInterval {
        samples.reduce(0) { total, sample in
            let start = max(sample.startDate, interval.start)
            let end = min(sample.endDate, interval.end)
            return total + max(0, end.timeIntervalSince(start))
        }
    }

    private func workoutValues(in interval: DateInterval) async throws -> [HealthWorkoutValue] {
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: [.strictStartDate]
        )
        return try await sampleValues(type: HKObjectType.workoutType(), predicate: predicate)
            .compactMap { $0 as? HKWorkout }
            .map { workout in
                HealthWorkoutValue(
                    id: workout.uuid,
                    sport: sportKind(for: workout.workoutActivityType),
                    startedAt: workout.startDate,
                    durationSeconds: workout.duration,
                    source: workout.sourceRevision.source.name,
                    sourceBundleIdentifier: workout.sourceRevision.source.bundleIdentifier,
                    distanceMeters: workout.totalDistance?.doubleValue(for: .meter()),
                    energyKilocalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                )
            }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private func nutritionValues(in interval: DateInterval) async throws -> [HealthNutritionDayValue] {
        var days = [Date: NutritionAccumulator]()
        try await absorbNutritionSamples(
            identifier: .dietaryEnergyConsumed,
            metric: .dietaryEnergy,
            unit: .kilocalorie(),
            interval: interval,
            keyPath: \NutritionAccumulator.totals.energyKilocalories,
            into: &days
        )
        try await absorbNutritionSamples(
            identifier: .dietaryProtein,
            metric: .dietaryProtein,
            unit: .gram(),
            interval: interval,
            keyPath: \NutritionAccumulator.totals.proteinGrams,
            into: &days
        )
        try await absorbNutritionSamples(
            identifier: .dietaryCarbohydrates,
            metric: .dietaryCarbohydrates,
            unit: .gram(),
            interval: interval,
            keyPath: \NutritionAccumulator.totals.carbohydrateGrams,
            into: &days
        )
        try await absorbNutritionSamples(
            identifier: .dietaryFatTotal,
            metric: .dietaryFat,
            unit: .gram(),
            interval: interval,
            keyPath: \NutritionAccumulator.totals.fatGrams,
            into: &days
        )

        return days.values
            .map { accumulator in
                HealthNutritionDayValue(
                    day: accumulator.day,
                    totals: accumulator.totals,
                    sources: accumulator.sources.sorted(),
                    availableMetrics: accumulator.availableMetrics
                )
            }
            .sorted { $0.day < $1.day }
    }

    private func absorbNutritionSamples(
        identifier: HKQuantityTypeIdentifier,
        metric: HealthMetricKey,
        unit: HKUnit,
        interval: DateInterval,
        keyPath: WritableKeyPath<NutritionAccumulator, Double>,
        into days: inout [Date: NutritionAccumulator]
    ) async throws {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: [.strictStartDate]
        )
        let samples = try await sampleValues(type: type, predicate: predicate)
            .compactMap { $0 as? HKQuantitySample }

        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            var accumulator = days[day] ?? NutritionAccumulator(day: day)
            accumulator[keyPath: keyPath] += sample.quantity.doubleValue(for: unit)
            accumulator.sources.insert(sample.sourceRevision.source.name)
            accumulator.availableMetrics.insert(metric)
            days[day] = accumulator
        }
    }

    private func sportKind(for activity: HKWorkoutActivityType) -> HealthSportKind {
        switch activity {
        case .running: .running
        case .cycling: .cycling
        case .swimming: .swimming
        case .basketball: .basketball
        case .traditionalStrengthTraining, .functionalStrengthTraining, .crossTraining: .strength
        default: .other
        }
    }

    private func latestQuantitySample(
        type: HKQuantityType,
        predicate: NSPredicate?
    ) async throws -> HKQuantitySample? {
        let samples = try await sampleValues(
            type: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        )
        return samples.first as? HKQuantitySample
    }

    private func sampleValues(
        type: HKSampleType,
        predicate: NSPredicate?,
        limit: Int = HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func statistics(
        type: HKQuantityType,
        predicate: NSPredicate?,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
            healthStore.execute(query)
        }
    }
}

private struct NutritionAccumulator {
    let day: Date
    var totals = NutritionTotals()
    var sources = Set<String>()
    var availableMetrics = Set<HealthMetricKey>()
}

enum HealthKitProviderError: Error {
    case unavailable
    case authorizationNotCompleted
}
