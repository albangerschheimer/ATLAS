import Foundation

enum HealthActivityCanonicalizer {
    static func canonicalize(_ sourceActivities: [HealthWorkoutValue]) -> [HealthWorkoutValue] {
        var canonical = [HealthWorkoutValue]()

        for candidate in sourceActivities.sorted(by: { $0.startedAt < $1.startedAt }) {
            guard let duplicateIndex = canonical.firstIndex(where: { isDuplicate($0, candidate) }) else {
                canonical.append(candidate)
                continue
            }

            canonical[duplicateIndex] = merge(canonical[duplicateIndex], candidate)
        }

        return canonical.sorted { $0.startedAt > $1.startedAt }
    }

    static func isDuplicate(_ lhs: HealthWorkoutValue, _ rhs: HealthWorkoutValue) -> Bool {
        guard lhs.sport == rhs.sport else { return false }

        let startDifference = abs(lhs.startedAt.timeIntervalSince(rhs.startedAt))
        guard startDifference <= 180 else { return false }

        let durationDifference = abs(lhs.durationSeconds - rhs.durationSeconds)
        let durationTolerance = max(120, max(lhs.durationSeconds, rhs.durationSeconds) * 0.10)
        guard durationDifference <= durationTolerance else { return false }

        if let lhsDistance = lhs.distanceMeters, let rhsDistance = rhs.distanceMeters {
            let distanceTolerance = max(300, max(lhsDistance, rhsDistance) * 0.07)
            return abs(lhsDistance - rhsDistance) <= distanceTolerance
        }

        return true
    }

    private static func merge(
        _ lhs: HealthWorkoutValue,
        _ rhs: HealthWorkoutValue
    ) -> HealthWorkoutValue {
        let preferred = preferenceScore(rhs) > preferenceScore(lhs) ? rhs : lhs
        let other = preferred.id == lhs.id ? rhs : lhs
        let sources = Array(
            Set(lhs.contributingSources + rhs.contributingSources + [lhs.source, rhs.source])
        ).sorted()

        return HealthWorkoutValue(
            id: preferred.id,
            sport: preferred.sport,
            startedAt: preferred.startedAt,
            durationSeconds: preferred.durationSeconds,
            source: preferred.source,
            sourceBundleIdentifier: preferred.sourceBundleIdentifier,
            distanceMeters: preferred.distanceMeters ?? other.distanceMeters,
            energyKilocalories: preferred.energyKilocalories ?? other.energyKilocalories,
            contributingSources: sources
        )
    }

    private static func preferenceScore(_ activity: HealthWorkoutValue) -> Int {
        let source = "\(activity.source) \(activity.sourceBundleIdentifier ?? "")".lowercased()
        var score = 0
        if source.contains("strava"), activity.sport == .running || activity.sport == .cycling {
            score += 100
        }
        if activity.distanceMeters != nil { score += 10 }
        if activity.energyKilocalories != nil { score += 5 }
        return score
    }
}
