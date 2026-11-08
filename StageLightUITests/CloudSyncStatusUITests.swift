import XCTest

@MainActor
final class CloudSyncStatusUITests: XCTestCase {
    func test_profileDisplaysICloudSyncStatusAndRefreshAction() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data", "-skip-onboarding"]
        app.launch()

        app.buttons["Profile"].tap()

        app.buttons["settings-entry"].tap()
        app.buttons["settings-sync"].tap()

        XCTAssertTrue(
            app.staticTexts["icloud-sync-section-title"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["Automatic Sync"].exists)
        XCTAssertTrue(app.buttons["Check Status"].exists)
    }
}
