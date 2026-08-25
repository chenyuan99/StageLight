import XCTest
@testable import StageLight

final class PerformanceDraftTests: XCTestCase {
    func test_validate_whitespaceTitle_throwsMissingTitle() {
        let draft = PerformanceDraft(showTitle: "   ", date: .now)

        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? DraftValidationError, .missingShowTitle)
        }
    }

    func test_validate_validDraft_returnsTrimmedTitle() throws {
        let draft = PerformanceDraft(showTitle: "  Hamilton  ", date: .now, rating: 4.5)

        let validated = try draft.validate()

        XCTAssertEqual(validated.showTitle, "Hamilton")
        XCTAssertEqual(validated.rating, 4.5)
    }

    func test_validate_ratingOutsideRange_throwsInvalidRating() {
        let draft = PerformanceDraft(showTitle: "Hamilton", date: .now, rating: 5.5)

        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? DraftValidationError, .invalidRating)
        }
    }

    func test_validate_unsupportedRatingIncrement_throwsInvalidRating() {
        let draft = PerformanceDraft(showTitle: "Hamilton", date: .now, rating: 4.2)

        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? DraftValidationError, .invalidRating)
        }
    }
}
