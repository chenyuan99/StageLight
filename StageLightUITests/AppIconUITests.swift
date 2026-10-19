import XCTest

/// Uses the real UIApplication icon API, not the unit-test service double.
/// Run on an unlocked, trusted iPhone or iPad. Diary fixtures are in-memory.
@MainActor final class AppIconUITests: XCTestCase {
    func testRealIconSwitchesPersistAcrossRelaunchAndRestore() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mini-preview", "-skip-onboarding",
                               "-appLanguage", "english", "-miniTheatre.enabled", "NO"]
        let monitor = addUIInterruptionMonitor(withDescription: "System icon confirmation") { alert in
            if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
            return false
        }
        defer { removeUIInterruptionMonitor(monitor) }
        openSettings(app)
        let choices = ["original", "bunny", "creamBunny", "goldenPremiere"]
        let original = try XCTUnwrap(choices.first { app.buttons["app-icon-\($0)"].isSelected })
        // Restore the user's starting icon, even if an assertion later fails.
        addTeardownBlock {
            app.terminate()
            self.openSettings(app)
            self.choose(original, in: app)
            XCTAssertTrue(app.buttons["app-icon-\(original)"].isSelected)
        }
        for choice in choices {
            choose(choice, in: app)
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "app-icon-\(choice)-selected"
            attachment.lifetime = .keepAlways
            add(attachment)
            // Relaunch forces the selection to be read back from UIApplication.
            app.terminate()
            openSettings(app)
            XCTAssertTrue(app.buttons["app-icon-\(choice)"].isSelected)
            XCUIDevice.shared.press(.home)
            let home = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            home.name = "app-icon-\(choice)-home-screen"
            home.lifetime = .keepAlways
            add(home)
            app.activate()
        }
    }

    private func openSettings(_ app: XCUIApplication) {
        app.launch()
        let profile = app.buttons["Profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 15))
        profile.tap()
        reveal(app.buttons["app-icon-original"], in: app)
    }

    private func choose(_ choice: String, in app: XCUIApplication) {
        let button = app.buttons["app-icon-\(choice)"]
        reveal(button, in: app)
        XCTAssertTrue(button.isEnabled, "System alternate icons must be supported")
        if !button.isSelected { button.tap() }
        dismissConfirmation(app)
        let selected = NSPredicate { _, _ in button.isSelected }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: selected, object: nil)], timeout: 10), .completed)
        dismissConfirmation(app)
    }

    private func dismissConfirmation(_ app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for alerts in [app.alerts, springboard.alerts] {
            let ok = alerts.buttons["OK"].firstMatch
            if ok.waitForExistence(timeout: 2) { ok.tap() }
        }
    }

    private func reveal(_ button: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        // isHittable can be true for content behind our floating tab bar.
        // Bring the whole row into the middle of the screen before tapping.
        for _ in 0..<20 {
            let top = max(scroll.frame.minY + 40, app.frame.height * 0.2)
            let bottom = app.frame.height * 0.72
            if button.isHittable && button.frame.minY >= top && button.frame.maxY <= bottom { break }
            let above = button.exists && button.frame.minY < top
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.4 : 0.65))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.65 : 0.4)))
        }
        XCTAssertTrue(button.isHittable)
    }
}
