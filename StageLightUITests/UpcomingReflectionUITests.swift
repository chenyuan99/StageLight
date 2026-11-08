import XCTest

@MainActor final class UpcomingReflectionUITests: XCTestCase {
    func testUpcomingAttendanceAndReflection() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-upcoming-preview", "-skip-onboarding", "-appLanguage", "english", "-reflection.enabled", "YES"]
        app.launch()
        app.buttons["Diary"].firstMatch.tap()
        XCTAssertTrue(app.buttons["upcoming-row"].firstMatch.waitForExistence(timeout: 10))
        capture("01-upcoming-diary")
        app.buttons["upcoming-row"].firstMatch.tap()
        XCTAssertTrue(app.buttons["mark-attended"].waitForExistence(timeout: 5))
        capture("02-booking-detail")
        app.buttons["mark-attended"].tap()
        XCTAssertTrue(app.buttons["reflection-offer"].waitForExistence(timeout: 5))
        capture("03-reflection-offer")
        app.buttons["reflection-offer"].tap()
        let editor = app.textViews["reflection-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("The final song stayed with me.")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(editor.value as? String == "The final song stayed with me.")
        XCUIDevice.shared.orientation = .portrait
        capture("04-reflection-editor")
        app.buttons["reflection-save"].tap()
        XCTAssertTrue(app.staticTexts["The final song stayed with me."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reflection-offer"].exists)
        capture("05-saved-memory")
    }

    func testOptOutAndCancelledBookingRestoration() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-upcoming-preview", "-skip-onboarding", "-appLanguage", "english", "-reflection.enabled", "NO"]
        app.launch()
        app.buttons["Diary"].firstMatch.tap()
        app.buttons["upcoming-row"].firstMatch.tap()
        app.buttons["cancel-booking"].tap()
        app.buttons["confirm-cancel-booking"].firstMatch.tap()
        XCTAssertTrue(app.buttons["restore-booking"].waitForExistence(timeout: 5))
        app.buttons["restore-booking"].tap()
        app.buttons["mark-attended"].tap()
        XCTAssertFalse(app.buttons["reflection-offer"].exists)
        app.buttons["edit-reflection"].tap()
        let editor = app.textViews["reflection-editor"]
        editor.tap(); editor.typeText("Do not discard")
        app.buttons["reflection-cancel"].tap()
        app.buttons["Keep Editing"].tap()
        XCTAssertEqual(editor.value as? String, "Do not discard")
        app.buttons["reflection-cancel"].tap()
        app.buttons["Discard Changes"].tap()
        XCTAssertFalse(app.staticTexts["Do not discard"].exists)
    }

    func testCreateUpcomingBooking() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-skip-onboarding", "-appLanguage", "english"]
        app.launch()
        app.buttons["add-performance-button"].tap()
        app.buttons["add-manually-button"].tap()
        let field = app.textFields["show-title-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("My next theatre night")
        app.buttons["attendance-picker"].tap()
        app.buttons["Upcoming"].firstMatch.tap()
        capture("06-new-booking-form")
        app.buttons["save-performance-button"].tap()
        app.buttons["Diary"].firstMatch.tap()
        XCTAssertTrue(app.buttons["upcoming-row"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["upcoming-row"].firstMatch.tap()
        XCTAssertTrue(app.buttons["mark-attended"].waitForExistence(timeout: 5))
    }

    private func capture(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
