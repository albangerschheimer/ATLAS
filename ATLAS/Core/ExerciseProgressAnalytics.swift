import Foundation

enum ExerciseProgressMetric: String, CaseIterable, Identifiable {
    case weight = "Charge", e1RM = "e1RM", volume = "Volume", reps = "Reps"
    var id: String { rawValue }
}

enum ExerciseProgressPeriod: String, CaseIterable, Identifiable {
    case days30 = "30J", days90 = "90J", months6 = "6M", year1 = "1A", all = "TOUT"
    var id: String { rawValue }

    func startDate(relativeTo date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .days30: calendar.date(byAdding: .day, value: -30, to: date)
        case .days90: calendar.date(byAdding: .day, value: -90, to: date)
        case .months6: calendar.date(byAdding: .month, value: -6, to: date)
        case .year1: calendar.date(byAdding: .year, value: -1, to: date)
        case .all: nil
        }
    }
}

struct ExerciseProgressPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let weight: Double
    let e1RM: Double
    let volume: Double
    let reps: Double

    func value(for metric: ExerciseProgressMetric) -> Double {
        switch metric { case .weight: weight; case .e1RM: e1RM; case .volume: volume; case .reps: reps }
    }
}

enum ExerciseProgressAnalytics {
    static func points(from performances: [ExercisePerformance]) -> [ExerciseProgressPoint] {
        performances.compactMap { performance -> ExerciseProgressPoint? in
            let sets = performance.sets.filter { $0.isCompleted && $0.kind == .working }
            guard !sets.isEmpty else { return nil }
            let weight = sets.compactMap(\.loadKilograms).max() ?? 0
            let reps = sets.compactMap(\.repetitions).max() ?? 0
            let volume = sets.reduce(0.0) { total, set in
                total + (set.loadKilograms ?? 0) * Double(set.repetitions ?? 0)
            }
            let e1RM = sets.compactMap { set -> Double? in
                guard let load = set.loadKilograms, let reps = set.repetitions else { return nil }
                return TrainingAnalytics.estimatedOneRepMax(loadKilograms: load, repetitions: reps)
            }.max() ?? 0
            return ExerciseProgressPoint(id: UUID(), date: performance.date, weight: weight, e1RM: e1RM, volume: volume, reps: Double(reps))
        }.sorted { $0.date < $1.date }
    }

    static func filtered(_ points: [ExerciseProgressPoint], period: ExerciseProgressPeriod, now: Date = .now) -> [ExerciseProgressPoint] {
        guard let start = period.startDate(relativeTo: now) else { return points }
        return points.filter { $0.date >= start && $0.date <= now }
    }
}
