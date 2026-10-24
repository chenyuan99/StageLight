import XCTest

@MainActor
final class StageLightUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data", "-skip-onboarding"]
        app.launch()
        return app
    }

    func test_nativeTabsKeepNavigationAndAddAvailable() {
        continueAfterFailure = false
        let app = launchApp()
        for destination in ["Diary", "Profile", "Collection"] {
            let tab = app.buttons[destination].firstMatch
            XCTAssertTrue(tab.waitForExistence(timeout: 5))
            tab.tap()
            XCTAssertTrue(app.buttons["add-performance-button"].waitForExistence(timeout: 5))
            capture("Native navigation - " + destination)
        }
        app.buttons["add-performance-button"].tap()
        XCTAssertTrue(app.buttons["add-manually-button"].waitForExistence(timeout: 5))
        app.buttons["add-manually-button"].tap()
        let title = app.textFields["show-title-field"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Navigation keeps this memory")
        app.buttons["save-performance-button"].tap()
        let savedTitle = app.staticTexts["Navigation keeps this memory"]
        XCTAssertTrue(savedTitle.waitForExistence(timeout: 5))
        savedTitle.tap()
        capture("Native navigation - show detail")
        app.buttons["Diary"].firstMatch.tap()
        XCTAssertTrue(savedTitle.waitForExistence(timeout: 5))
        app.buttons["Collection"].firstMatch.tap()
        XCTAssertTrue(app.buttons["performance-row"].waitForExistence(timeout: 5))
        capture("Native navigation - retained detail")
    }

    func test_emptyLibrary_displaysEmptyStateAndAddAction() {
        continueAfterFailure = false
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Your stage is empty."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["add-performance-button"].exists)
    }

    func test_unsavedDraftSurvivesRotationAndCancelledDiscard() {
        continueAfterFailure = false
        let app = launchApp()
        defer { XCUIDevice.shared.orientation = .portrait }
        app.buttons["add-performance-button"].tap()
        app.buttons["add-manually-button"].tap()
        let title = app.textFields["show-title-field"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Duo draft test")
        capture("Draft before rotation")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertEqual(title.value as? String, "Duo draft test")
        capture("Draft after landscape rotation")
        XCUIDevice.shared.orientation = .portrait
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Keep Editing"].waitForExistence(timeout: 3))
        capture("Discard confirmation")
        app.buttons["Keep Editing"].tap()
        XCTAssertEqual(title.value as? String, "Duo draft test")
        app.buttons["Cancel"].tap()
        app.buttons["Discard Changes"].tap()
        XCTAssertTrue(app.buttons["add-performance-button"].waitForExistence(timeout: 3))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
        XCTAssertTrue(app.switches["Include App Store link"].exists)

        app.buttons["share-memory-card"].tap()

        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 3))
        let saveToPhotos = shareSheet.cells["Save to Photos"]
        XCTAssertTrue(saveToPhotos.waitForExistence(timeout: 3))

        addUIInterruptionMonitor(withDescription: "Photo Library Access") { alert in
            let allowButton = alert.buttons["Allow"]
            guard allowButton.exists else { return false }
            allowButton.tap()
            return true
        }

        saveToPhotos.tap()
        app.tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
