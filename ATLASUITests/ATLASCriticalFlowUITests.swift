import XCTest

@MainActor
final class ATLASCriticalFlowUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Séance"].waitForExistence(timeout: 8))
    }

    func testManualNutritionEntryCanBeAddedAndDeleted() {
        app.tabBars.buttons["Profil"].tap()
        app.buttons["profile.nutrition"].tap()
        XCTAssertTrue(app.navigationBars["Nutrition"].waitForExistence(timeout: 4))

        app.buttons["nutrition.add"].tap()
        app.buttons["nutrition.add.manual"].tap()
        type("Collation UI", into: "nutrition.entry.name")
        app.buttons["nutrition.entry.save"].tap()

        let entry = app.staticTexts["Collation UI"]
        XCTAssertTrue(entry.waitForExistence(timeout: 4))
        entry.swipeLeft()
        app.buttons["Supprimer"].tap()
        XCTAssertFalse(entry.waitForExistence(timeout: 2))
    }

    func testTodayNutritionCardOpensTheNutritionJournal() {
        app.tabBars.buttons["Jour"].tap()
        app.buttons["today.nutrition"].tap()
        XCTAssertTrue(app.navigationBars["Nutrition"].waitForExistence(timeout: 4))
    }

    func testCreateExerciseProgramWorkoutAndHistory() {
        app.tabBars.buttons["Séance"].tap()

        app.staticTexts["Bibliothèque d’exercices"].tap()
        app.buttons["exercise.new"].tap()
        type("Squat UI", into: "exercise.name.fr")
        app.buttons["exercise.save"].tap()
        search(for: "Squat UI", in: "exercise.library.search")
        XCTAssertTrue(app.staticTexts["Squat UI"].waitForExistence(timeout: 3))
        navigateBack(from: "Exercices")

        app.staticTexts["Programmes"].tap()
        app.buttons["program.new"].tap()
        type("Programme UI", into: "program.name")
        app.buttons["program.save"].tap()
        XCTAssertTrue(app.staticTexts["Programme UI"].waitForExistence(timeout: 3))
        app.staticTexts["Programme UI"].tap()

        app.buttons["program.day.new"].tap()
        type("Jour UI", into: "program.day.name")
        app.buttons["program.day.save"].tap()
        XCTAssertTrue(app.staticTexts["Jour UI"].waitForExistence(timeout: 3))
        app.staticTexts["Jour UI"].tap()

        app.buttons["program.day.exercise.add"].tap()
        search(for: "Squat UI", in: "exercise.picker.search")
        XCTAssertTrue(app.staticTexts["Squat UI"].waitForExistence(timeout: 3))
        app.staticTexts["Squat UI"].tap()
        XCTAssertTrue(app.buttons["program.day.start"].waitForExistence(timeout: 3))
        app.buttons["program.day.start"].tap()

        let loadField = app.textFields["workout.exercise.0.set.0.load"]
        XCTAssertTrue(loadField.waitForExistence(timeout: 5))
        let loadFields = app.textFields.matching(
            NSPredicate(format: "identifier MATCHES %@", "workout\\.exercise\\.0\\.set\\.[0-9]+\\.load")
        )
        let initialSetCount = loadFields.count
        app.buttons["workout.exercise.0.set.add"].tap()
        let removableSetIdentifier = "workout.exercise.0.set.\(initialSetCount).load"
        let removableSet = app.textFields[removableSetIdentifier]
        XCTAssertTrue(removableSet.waitForExistence(timeout: 3))
        removableSet.swipeRight()
        XCTAssertEqual(loadFields.count, initialSetCount)

        loadField.tap()
        loadField.typeText("80")
        app.buttons["workout.exercise.0.set.0.complete"].tap()
        app.buttons["workout.finish"].tap()
        app.buttons["Enregistrer la séance"].tap()

        XCTAssertTrue(app.navigationBars["Jour UI"].waitForExistence(timeout: 5))
        navigateBack(from: "Jour UI")
        navigateBack(from: "Programme UI")
        navigateBack(from: "Programmes")

        app.staticTexts["Historique"].tap()
        XCTAssertTrue(app.staticTexts["Jour UI"].waitForExistence(timeout: 5))
        app.staticTexts["Jour UI"].tap()
        XCTAssertTrue(app.staticTexts["Squat UI"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["80 kg × 8"].waitForExistence(timeout: 3))
    }

    func testBrowseExercisesFromArmsToBiceps() {
        app.tabBars.buttons["Séance"].tap()
        app.staticTexts["Bibliothèque d’exercices"].tap()

        let muscleBrowser = app.buttons["exercise.library.muscleBrowser"]
        XCTAssertTrue(muscleBrowser.waitForExistence(timeout: 4))
        muscleBrowser.tap()
        XCTAssertTrue(app.navigationBars["Carte musculaire"].waitForExistence(timeout: 4))

        app.buttons["muscle.region.arms"].tap()
        XCTAssertTrue(app.navigationBars["Bras"].waitForExistence(timeout: 3))
        app.buttons["muscle.group.biceps"].tap()
        XCTAssertTrue(app.navigationBars["Biceps"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Curl barre droite"].waitForExistence(timeout: 3))
    }

    private func type(_ text: String, into identifier: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Champ introuvable : \(identifier)")
        field.tap()
        field.typeText(text)
    }

    private func search(for text: String, in identifier: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Champ de recherche introuvable : \(identifier)")
        field.tap()
        field.typeText(text)
    }

    private func navigateBack(from title: String) {
        let navigationBar = app.navigationBars[title]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 3), "Navigation absente : \(title)")
        navigationBar.buttons.element(boundBy: 0).tap()
    }
}
