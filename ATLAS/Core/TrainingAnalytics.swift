import Foundation

enum TrainingAnalytics {
    static func volume(of sets: [TrainingSetSnapshot]) -> Double {
        sets.reduce(into: 0) { result, set in
            guard
                set.isCompleted,
                set.kind == .working,
                let load = set.loadKilograms,
                let repetitions = set.repetitions,
                load > 0,
                repetitions > 0
            else { return }

            result += load * Double(repetitions)
        }
    }

    static func estimatedOneRepMax(loadKilograms: Double, repetitions: Int) -> Double? {
        guard loadKilograms > 0, (1...12).contains(repetitions) else { return nil }
        return loadKilograms * (1 + Double(repetitions) / 30)
    }

    static func records(from performances: [ExercisePerformance]) -> ExerciseRecords {
        let completedSets = performances
            .flatMap(\.sets)
            .filter { $0.isCompleted && $0.kind == .working }

        let loads = completedSets.compactMap { set -> Double? in
            guard let load = set.loadKilograms, load > 0 else { return nil }
            return load
        }
        let repetitions = completedSets.compactMap { set -> Int? in
            guard let repetitions = set.repetitions, repetitions > 0 else { return nil }
            return repetitions
        }
        let estimates = completedSets.compactMap { set -> Double? in
            guard
                let load = set.loadKilograms,
                let repetitions = set.repetitions
            else { return nil }
            return estimatedOneRepMax(loadKilograms: load, repetitions: repetitions)
        }

        return ExerciseRecords(
            heaviestLoadKilograms: loads.max(),
            bestRepetitions: repetitions.max(),
            estimatedOneRepMaxKilograms: estimates.max(),
            totalVolumeKilograms: performances.reduce(0) { partial, performance in
                partial + volume(of: performance.sets)
            }
        )
    }
}
