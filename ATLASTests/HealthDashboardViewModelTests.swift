import Foundation
import XCTest
@testable import ATLAS

@MainActor
final class HealthDashboardViewModelTests: XCTestCase {
    func testRefreshDoesNotQueryHealthBeforeExplicitRequest() async {
        let provider = MockHealthDataProvider(snapshot: availableSnapshot)
        let viewModel = HealthDashboardViewModel(provider: provider)

        await viewModel.refresh(hasRequestedAccess: false, now: testDate)

        XCTAssertEqual(viewModel.snapshot[.sleep].availability, .permissionNotRequested)
        XCTAssertEqual(provider.authorizationRequestCount, 0)
    }

    func testRequestAccessLoadsAvailableSnapshot() async {
        let provider = MockHealthDataProvider(snapshot: availableSnapshot)
        let viewModel = HealthDashboardViewModel(provider: provider)

        let succeeded = await viewModel.requestAccess(now: testDate)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(provider.authorizationRequestCount, 1)
        XCTAssertEqual(viewModel.snapshot[.sleep].value, 7.5)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUnavailableHealthDataProducesExplicitState() async {
        let provider = MockHealthDataProvider(
            snapshot: .empty(availability: .healthUnavailable, healthDataAvailable: false)
        )
        let viewModel = HealthDashboardViewModel(provider: provider)

        await viewModel.refresh(hasRequestedAccess: true, now: testDate)

        XCTAssertFalse(viewModel.snapshot.healthDataAvailable)
        XCTAssertEqual(viewModel.snapshot[.sleep].availability, .healthUnavailable)
    }

    private var testDate: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private var availableSnapshot: HealthSnapshot {
        var metrics = HealthSnapshot.empty(availability: .noData, generatedAt: testDate).metrics
        metrics[.sleep] = HealthMetricValue(
            key: .sleep,
            value: 7.5,
            unit: "h",
            startDate: testDate.addingTimeInterval(-27_000),
            endDate: testDate,
            source: "Mi Fitness",
            availability: .available
        )
        return HealthSnapshot(
            generatedAt: testDate,
            metrics: metrics,
            workouts: [],
            healthDataAvailable: true
        )
    }
}
