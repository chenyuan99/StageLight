import XCTest

@MainActor
final class TheatreHistoryUITests: XCTestCase {
    private func launch(language: String = "english") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Run on dedicated review simulators. Never reset an existing diary.
        app.launchArguments = ["-ui-testing", "-skip-onboarding", "-appLanguage", language]
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEnglishBrowseDetailCardAndShare() {
        let app = launch()
        let entry = app.buttons["theatre-history-entry"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        capture(app, "01-collection-en")
        entry.tap()
        let event = app.buttons["history-event-salesman-broadway-1949"]
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        capture(app, "02-history-en")
        event.tap()
        XCTAssertTrue(app.buttons["history-create-card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.links["history-source"].exists || app.buttons["history-source"].exists)
        capture(app, "03-detail-en")
        app.buttons["history-create-card"].tap()
        XCTAssertTrue(app.otherElements["history-card-preview"].waitForExistence(timeout: 3))
        capture(app, "04-card-en")
        app.buttons["history-share"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["ActivityListView"].cells["Save to Photos"].waitForExistence(timeout: 15))
        capture(app, "05-share-en")
    }

    func testChineseStoryCard() {
        let app = launch(language: "simplifiedChinese")
        app.buttons["theatre-history-entry"].tap()
        XCTAssertTrue(app.staticTexts["浏览历史"].waitForExistence(timeout: 5))
        capture(app, "06-history-zh")
        let event = app.buttons["history-event-phantom-broadway-1988"]
        for _ in 0..<4 where !event.isHittable { app.swipeUp() }
        XCTAssertTrue(event.isHittable)
        event.tap()
        capture(app, "07-detail-zh")
        app.buttons["history-create-card"].tap()
        XCTAssertTrue(app.buttons["故事长图"].waitForExistence(timeout: 3))
        app.buttons["故事长图"].tap()
        capture(app, "08-story-zh")
    }

    func testOptionalEntryCanBeHidden() {
        let app = launch()
        XCTAssertTrue(app.buttons["add-performance-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["theatre-history-entry"].exists)
        app.buttons["Profile"].tap()
        let toggle = app.switches["theatre-history-toggle"]
        for _ in 0..<5 where !toggle.isHittable { app.swipeUp() }
        XCTAssertTrue(toggle.isHittable)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        app.buttons["Collection"].tap()
        XCTAssertFalse(app.buttons["theatre-history-entry"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["add-performance-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["theatre-history-entry"].exists)
        app.buttons["Profile"].tap()
        for _ in 0..<5 where !toggle.isHittable { app.swipeUp() }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
        app.buttons["Collection"].tap()
        XCTAssertTrue(app.buttons["theatre-history-entry"].waitForExistence(timeout: 3))
    }
}
