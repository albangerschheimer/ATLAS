import Foundation
import XCTest
@testable import ATLAS

final class HealthActivityCanonicalizerTests: XCTestCase {
    func testEquivalentStravaAndMiFitnessRunsBecomeOneCanonicalActivity() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let miFitness = activity(
            source: "Mi Fitness",
            bundle: "com.xiaomi.mifitness",
            start: start,
            duration: 3_600,
            distance: 10_000
        )
        let strava = activity(
            source: "Strava",
            bundle: "com.strava.stravaride",
            start: start.addingTimeInterval(42),
            duration: 3_570,
            distance: 10_080
        )

        let result = HealthActivityCanonicalizer.canonicalize([miFitness, strava])

        let canonical = try XCTUnwrap(result.first)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(canonical.source, "Strava")
        XCTAssertEqual(canonical.contributingSources, ["Mi Fitness", "Strava"])
    }

    func testSeparateRunsRemainSeparate() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let morning = activity(source: "Strava", bundle: nil, start: start, duration: 1_800, distance: 5_000)
        let evening = activity(source: "Strava", bundle: nil, start: start.addingTimeInterval(20_000), duration: 1_800, distance: 5_000)

        XCTAssertEqual(HealthActivityCanonicalizer.canonicalize([morning, evening]).count, 2)
    }

    func testSimilarTimingButDifferentDistanceIsNotMerged() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let short = activity(source: "Source A", bundle: nil, start: start, duration: 1_800, distance: 5_000)
        let long = activity(source: "Source B", bundle: nil, start: start, duration: 1_800, distance: 8_000)

        XCTAssertEqual(HealthActivityCanonicalizer.canonicalize([short, long]).count, 2)
    }

    private func activity(
        source: String,
        bundle: String?,
        start: Date,
        duration: TimeInterval,
        distance: Double?
    ) -> HealthWorkoutValue {
        HealthWorkoutValue(
            id: UUID(),
            sport: .running,
            startedAt: start,
            durationSeconds: duration,
            source: source,
            sourceBundleIdentifier: bundle,
            distanceMeters: distance
        )
    }
}
