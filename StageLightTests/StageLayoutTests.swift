import XCTest
@testable import StageLight

final class StageLayoutTests: XCTestCase {
    func testCompactLayoutPreservesTwoColumns() {
        XCTAssertEqual(StageLayout.collectionColumnCount(width: 390, regular: false, accessibility: false), 2)
    }

    func testRegularLayoutAdaptsToWindowWidth() {
        XCTAssertEqual(StageLayout.collectionColumnCount(width: 834, regular: true, accessibility: false), 4)
        XCTAssertEqual(StageLayout.collectionColumnCount(width: 1194, regular: true, accessibility: false), 6)
        XCTAssertEqual(StageLayout.collectionColumnCount(width: 500, regular: true, accessibility: false), 2)
        XCTAssertEqual(StageLayout.collectionColumnCount(width: 0, regular: true, accessibility: false), 1)
    }

    func testAccessibilityTextUsesOneColumn() {
        for regular in [false, true] {
            XCTAssertEqual(StageLayout.collectionColumnCount(width: 1194, regular: regular, accessibility: true), 1)
        }
    }
}
