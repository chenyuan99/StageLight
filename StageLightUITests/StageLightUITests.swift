import XCTest

@MainActor
final class StageLightUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data", "-skip-onboarding"]
        app.launch()
    }

    func test_emptyLibrary_displaysEmptyStateAndAddAction() {
        XCTAssertTrue(app.staticTexts["Your stage is empty."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["add-performance-button"].exists)
    }

    func test_manualAdd_savesPerformanceIntoCollection() {
        app.buttons["add-performance-button"].tap()
        app.buttons["add-manually-button"].tap()

        let titleField = app.textFields["show-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Hamilton")
        app.buttons["save-performance-button"].tap()

        XCTAssertTrue(app.staticTexts["Hamilton"].waitForExistence(timeout: 3))
    }
}
