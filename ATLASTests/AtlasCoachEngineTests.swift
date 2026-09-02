import XCTest
@testable import ATLAS

final class AtlasCoachEngineTests: XCTestCase {
    func testLowReadinessProducesImportantActionableInsight() {
        let context = makeContext(readiness: 35)
        let insights = AtlasCoachEngine.insights(for: context)
        XCTAssertEqual(insights.first?.id, "readiness-low")
        XCTAssertEqual(insights.first?.priority, .important)
        XCTAssertNotNil(insights.first?.action)
    }

    func testMissingSleepDoesNotCreateSleepAlertOrBlockAdvice() {
        let context = makeContext(readiness: 78, sleep: nil)
        let insights = AtlasCoachEngine.insights(for: context)
        XCTAssertFalse(insights.contains { $0.id == "short-sleep" })
        XCTAssertFalse(insights.isEmpty)
    }

    func testRaisedRestingHeartRateUsesBaseline() {
        let context = AtlasCoachContext(
            readinessScore: 60, restingHeartRate: 66, restingBaseline: 58,
            sleepHours: nil, strengthSessionsThisWeek: 2, enduranceSessionsThisWeek: 0,
            trainingDays: [], proteinToday: nil, proteinGoal: 150, currentHour: 12
        )
        XCTAssertTrue(AtlasCoachEngine.insights(for: context).contains { $0.id == "resting-hr-high" })
    }

    private func makeContext(readiness: Int, sleep: Double? = nil) -> AtlasCoachContext {
        AtlasCoachContext(
            readinessScore: readiness, restingHeartRate: 55, restingBaseline: 55,
            sleepHours: sleep, strengthSessionsThisWeek: 2, enduranceSessionsThisWeek: 1,
            trainingDays: [], proteinToday: 120, proteinGoal: 150, currentHour: 12
        )
    }
}
