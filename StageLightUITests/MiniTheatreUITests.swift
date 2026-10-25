import XCTest

@MainActor final class MiniTheatreUITests: XCTestCase {
    func testDedicatedNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mini-preview", "-skip-onboarding", "-appLanguage", "simplifiedChinese", "-miniTheatre.enabled", "YES"]
        app.launch()
        let tab = app.buttons["小剧场"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        capture(app, "navigation-collection")
        tab.tap()
        XCTAssertTrue(app.scrollViews["mini-scroll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["add-performance-button"].exists)
        capture(app, "navigation-mini-theatre")
        app.buttons["mini-acknowledge"].tap()
        capture(app, "navigation-mini-acknowledged")
        app.buttons["add-performance-button"].tap()
        XCTAssertTrue(app.buttons["取消"].waitForExistence(timeout: 5))
    }

    func testDisabledHasNoCollectionShortcutOrAward() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mini-preview", "-skip-onboarding", "-appLanguage", "english",
                               "-miniTheatre.enabled", "NO", "-miniTheatre.shortcut", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Profile"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Mini Theatre"].exists)
        XCTAssertFalse(app.buttons["mini-entry"].exists)
        XCTAssertFalse(app.buttons["mini-award-notice"].exists)
    }
    func testBunnyUnlockEquipAndShare() {
        flow(language: "english", remove: "Remove", prefix: "mini")
    }
    func testChineseBunnyAndShare() {
        flow(language: "simplifiedChinese", remove: "收起", prefix: "mini-zh")
    }
    func testChineseLandscapeBunnyAndShare() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        flow(language: "simplifiedChinese", remove: "收起", prefix: "mini-zh-landscape")
    }
    private func flow(language: String, remove: String, prefix: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-mini-preview", "-skip-onboarding", "-appLanguage", language, "-miniTheatre.enabled", "YES"]
        app.launch()
        let notice = app.buttons["mini-award-notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 10))
        notice.tap()
        let done = app.buttons["mini-acknowledge"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        capture(app, "\(prefix)-01-awards")
        done.tap()
        let equip = app.buttons["mini-equip-welcome_pennant"]
        reveal(equip, in: app.scrollViews["mini-scroll"])
        equip.tap()
        XCTAssertEqual(equip.label, remove)
        capture(app, "\(prefix)-02-props")
        let share = app.buttons["mini-share"]
        reveal(share, in: app.scrollViews["mini-scroll"])
        share.tap()
        XCTAssertTrue(app.otherElements["mini-card-preview"].waitForExistence(timeout: 5))
        capture(app, "\(prefix)-03-share")
    }
    private func reveal(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<30 where !element.isHittable {
            // Small drags avoid skipping short localized rows; reverse if already above the viewport.
            let above = element.exists && element.frame.maxY < scroll.frame.minY + 40
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.4 : 0.65))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.65 : 0.4)))
        }
        XCTAssertTrue(element.isHittable)
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        // Capture the display, not the app window's rotated coordinate rectangle on iPad.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
