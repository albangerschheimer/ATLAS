import XCTest

@MainActor
final class ATLASAccessibilityUITests: XCTestCase {
    func testDashboardLaunchesInDarkModeWithLargestDynamicType() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR",
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Jour"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Bonjour"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Connecter Apple Santé"].waitForExistence(timeout: 3))
    }
}
