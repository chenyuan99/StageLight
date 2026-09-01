import XCTest

@MainActor
final class StageLightUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data", "-skip-onboarding"]
        app.launch()
        return app
    }

    func test_emptyLibrary_displaysEmptyStateAndAddAction() {
        continueAfterFailure = false
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Your stage is empty."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["add-performance-button"].exists)
    }

    func test_manualAdd_savesPerformanceIntoCollection() {
        continueAfterFailure = false
        let app = launchApp()

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
