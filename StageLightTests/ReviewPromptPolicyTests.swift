import XCTest
@testable import StageLight

final class ReviewPromptPolicyTests: XCTestCase {
    func test_fewerThanThreePerformances_isNotEligible() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 2,
                currentVersion: "1.2.0",
                lastRequestedVersion: nil,
                isUITesting: false
            )
        )
    }

    func test_threePerformancesAndNoPriorRequest_isEligible() {
        XCTAssertTrue(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 3,
                currentVersion: "1.2.0",
                lastRequestedVersion: nil,
                isUITesting: false
            )
        )
    }

    func test_sameVersionWasAlreadyRequested_isNotEligible() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 8,
                currentVersion: "1.2.0",
                lastRequestedVersion: "1.2.0",
                isUITesting: false
            )
        )
    }

    func test_newVersionAfterPriorRequest_isEligibleAgain() {
        XCTAssertTrue(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 8,
                currentVersion: "1.2.0",
                lastRequestedVersion: "1.1.0",
                isUITesting: false
            )
        )
    }

    func test_uiTesting_neverRequestsReview() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 20,
                currentVersion: "1.2.0",
                lastRequestedVersion: nil,
                isUITesting: true
            )
        )
    }

    func test_missingBundleVersion_isNotEligible() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequestReview(
                performanceCount: 3,
                currentVersion: "",
                lastRequestedVersion: nil,
                isUITesting: false
            )
        )
    }
}
