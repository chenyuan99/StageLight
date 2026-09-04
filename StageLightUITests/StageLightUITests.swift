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

    func test_savedPerformance_opensMemoryCardComposer() {
        continueAfterFailure = false
        let app = launchApp()

        app.buttons["add-performance-button"].tap()
        app.buttons["add-manually-button"].tap()

        let titleField = app.textFields["show-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Hamilton")
        app.buttons["save-performance-button"].tap()

        let showTitle = app.staticTexts["Hamilton"]
        XCTAssertTrue(showTitle.waitForExistence(timeout: 3))
        showTitle.tap()

        let performanceRow = app.buttons["performance-row"]
        XCTAssertTrue(performanceRow.waitForExistence(timeout: 2))
        performanceRow.tap()

        let actions = app.buttons["performance-actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 2))
        actions.tap()
        app.buttons["Share Memory"].tap()

        XCTAssertTrue(app.otherElements["memory-card-preview"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["share-memory-card"].exists)
        XCTAssertTrue(app.buttons["Spotlight"].exists)
        XCTAssertTrue(app.buttons["Story"].exists)
    }
}
