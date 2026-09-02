import Foundation

struct HealthBodyMeasurementSample: Identifiable, Equatable, Sendable {
    let id: UUID
    let metric: BodyMetricKind
    let value: Double
    let measuredAt: Date
    let source: String
}

enum HealthBodyMeasurementSync {
    private static let orderedMappings: [(HealthMetricKey, BodyMetricKind)] = [
        (.bodyMass, .weight),
        (.bodyFatPercentage, .bodyFatPercentage),
        (.leanBodyMass, .fatFreeMass),
        (.bodyMassIndex, .bodyMassIndex)
    ]

    static func samples(from metrics: [HealthMetricKey: HealthMetricValue]) -> [HealthBodyMeasurementSample] {
        orderedMappings.compactMap { key, metric in
            guard let item = metrics[key],
                  item.availability == .available,
                  let value = item.value,
                  let measuredAt = item.endDate ?? item.startDate,
                  value.isFinite,
                  value > 0 else { return nil }
            return HealthBodyMeasurementSample(
                id: stableID(metric: metric, measuredAt: measuredAt, value: value, source: item.source ?? "Apple Santé"),
                metric: metric,
                value: value,
                measuredAt: measuredAt,
                source: item.source ?? "Apple Santé"
            )
        }
    }

    static func shouldImport(_ sample: HealthBodyMeasurementSample, existing: [BodyMeasurementRecord]) -> Bool {
        !existing.contains { record in
            record.metric == sample.metric &&
            abs(record.measuredAt.timeIntervalSince(sample.measuredAt)) < 1 &&
            abs(record.value - sample.value) < 0.001
        }
    }

    static func stableID(metric: BodyMetricKind, measuredAt: Date, value: Double, source: String) -> UUID {
        let seed = "\(metric.rawValue)|\(measuredAt.timeIntervalSince1970)|\(value)|\(source)"
        var bytes = Array(repeating: UInt8(0), count: 16)
        for (index, byte) in seed.utf8.enumerated() {
            bytes[index % 16] = bytes[index % 16] &* 31 &+ byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
