import XCTest
@testable import StageLight

final class TitleNormalizerTests: XCTestCase {
    func test_normalize_caseAndWhitespace_returnsCanonicalTitle() {
        XCTAssertEqual(TitleNormalizer.normalize("Hamilton"), "hamilton")
        XCTAssertEqual(TitleNormalizer.normalize(" HAMILTON "), "hamilton")
        XCTAssertEqual(TitleNormalizer.normalize("hamilton"), "hamilton")
    }

    func test_normalize_internalWhitespace_preservesMeaningfulSpacing() {
        XCTAssertEqual(TitleNormalizer.normalize("  The   Lion King  "), "the   lion king")
    }

    func test_normalize_distinctTitles_doesNotCreateSemanticAlias() {
        XCTAssertNotEqual(
            TitleNormalizer.normalize("The Phantom of the Opera"),
            TitleNormalizer.normalize("Phantom")
        )
    }
}
