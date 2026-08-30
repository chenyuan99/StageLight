import CloudKit
import XCTest
@testable import StageLight

final class CloudSyncStatusProviderTests: XCTestCase {
    func test_availableAccount_reportsSyncOn() {
        let status = CloudSyncAvailability(accountStatus: .available)

        XCTAssertEqual(status, .available)
        XCTAssertEqual(status.title, "On")
    }

    func test_missingAccount_requestsSignIn() {
        let status = CloudSyncAvailability(accountStatus: .noAccount)

        XCTAssertEqual(status, .noAccount)
        XCTAssertEqual(status.title, "Sign In Required")
    }

    func test_temporaryFailure_explainsAutomaticRetry() {
        let status = CloudSyncAvailability(accountStatus: .temporarilyUnavailable)

        XCTAssertEqual(status, .temporarilyUnavailable)
        XCTAssertTrue(status.message.contains("retry automatically"))
    }

    func test_unknownAccountStatus_reportsUnavailable() {
        let status = CloudSyncAvailability(accountStatus: .couldNotDetermine)

        XCTAssertEqual(status, .unavailable)
    }
}
