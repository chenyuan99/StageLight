import XCTest

@MainActor final class SettingsUITests: XCTestCase {
    func testDedicatedSettingsAndPersistentReflectionPreference() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-upcoming-preview", "-skip-onboarding", "-appLanguage", "english"]
        app.launch()
        app.buttons["Profile"].firstMatch.tap()
        XCTAssertTrue(app.buttons["settings-entry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["reflection-setting"].exists)
        XCTAssertFalse(app.switches["mini-enable"].exists)
        capture("01-profile")
        app.buttons["settings-entry"].tap()
        for id in ["language", "icon", "diary", "mini", "history", "sync"] {
            XCTAssertTrue(app.buttons["settings-\(id)"].exists)
        }
        capture("02-settings")
        app.buttons["settings-diary"].tap()
        let toggle = app.switches["reflection-setting"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let original = toggle.value as? String
        toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let changed = toggle.value as? String
        XCTAssertNotEqual(changed, original)
        capture("03-diary-preferences")
        app.terminate()
        app.launch()
        app.buttons["Profile"].firstMatch.tap()
        app.buttons["settings-entry"].tap()
        app.buttons["settings-diary"].tap()
        XCTAssertEqual(toggle.value as? String, changed)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, original)
    }

    private func capture(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
