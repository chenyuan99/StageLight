import UIKit
import XCTest
@testable import StageLight

final class MemoryCardTests: XCTestCase {
    private let source = MemoryCardSource(
        showTitle: "Hamilton",
        date: Date(timeIntervalSince1970: 1_704_153_600),
        theatre: "Richard Rodgers Theatre",
        city: "New York",
        seat: "Orchestra · H · 12",
        rating: 4.5,
        notes: "An electric performance with a wonderful audience."
    )

    func testContentIncludesSelectedDetails() {
        let content = MemoryCardContent.make(
            source: source,
            options: MemoryCardOptions(),
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(content.title, "Hamilton")
        XCTAssertEqual(content.venue, "Richard Rodgers Theatre · New York")
        XCTAssertEqual(content.seat, "Orchestra · H · 12")
        XCTAssertEqual(content.rating, "★ 4.5 / 5")
        XCTAssertEqual(content.note, "An electric performance with a wonderful audience.")
        XCTAssertTrue(content.includesPhoto)
    }

    func testContentHidesEveryOptionalDetail() {
        let options = MemoryCardOptions(
            includesTitle: false,
            includesPhoto: false,
            includesDate: false,
            includesVenue: false,
            includesSeat: false,
            includesRating: false,
            includesNote: false
        )

        let content = MemoryCardContent.make(source: source, options: options)

        XCTAssertNil(content.title)
        XCTAssertFalse(content.includesPhoto)
        XCTAssertNil(content.date)
        XCTAssertNil(content.venue)
        XCTAssertNil(content.seat)
        XCTAssertNil(content.rating)
        XCTAssertNil(content.note)
    }

    func testContentOmitsUnavailableValues() {
        let incomplete = MemoryCardSource(
            showTitle: "The Play",
            date: source.date,
            theatre: "",
            city: "",
            seat: nil,
            rating: nil,
            notes: "   "
        )

        let content = MemoryCardContent.make(source: incomplete, options: MemoryCardOptions())

        XCTAssertNil(content.venue)
        XCTAssertNil(content.seat)
        XCTAssertNil(content.rating)
        XCTAssertNil(content.note)
    }

    func testLongNoteIsLimitedForCardLayout() {
        let longNote = String(repeating: "memorable ", count: 30)
        let longSource = MemoryCardSource(
            showTitle: source.showTitle,
            date: source.date,
            theatre: source.theatre,
            city: source.city,
            seat: source.seat,
            rating: source.rating,
            notes: longNote
        )

        let content = MemoryCardContent.make(source: longSource, options: MemoryCardOptions())

        XCTAssertEqual(content.note?.count, 180)
        XCTAssertTrue(content.note?.hasSuffix("…") == true)
    }

    @MainActor
    func testSharingIncludesCanonicalAppStoreLinkByDefault() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        let items = MemoryCardBrand.activityItems(image: image, includesAppStoreLink: true)

        XCTAssertEqual(MemoryCardBrand.signature, "Made with StageLight")
        XCTAssertEqual(MemoryCardBrand.appStoreURL.absoluteString, "https://apps.apple.com/app/id6806575225")
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.last as? URL, MemoryCardBrand.appStoreURL)
    }

    @MainActor
    func testMemoryCardAppIconIsAvailable() {
        XCTAssertNotNil(UIImage(named: "MemoryCardAppIcon"))
    }

    @MainActor
    func testSharingCanExcludeAppStoreLink() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        let items = MemoryCardBrand.activityItems(image: image, includesAppStoreLink: false)

        XCTAssertEqual(items.count, 1)
        XCTAssertTrue(items.first is UIImage)
    }

    @MainActor
    func testSpotlightRendererProducesHighResolutionPortrait() throws {
        let content = MemoryCardContent.make(source: source, options: MemoryCardOptions())

        let image = try XCTUnwrap(
            MemoryCardRenderer.render(content: content, template: .spotlight, photo: nil)
        )

        XCTAssertEqual(image.cgImage?.width, 1_080)
        XCTAssertEqual(image.cgImage?.height, 1_350)
        XCTAssertNotNil(image.pngData())
    }

    @MainActor
    func testStoryRendererHandlesLongContentAtStoryResolution() throws {
        let longSource = MemoryCardSource(
            showTitle: String(repeating: "A Very Long Show Title ", count: 4),
            date: source.date,
            theatre: String(repeating: "A Theatre With A Long Name ", count: 3),
            city: source.city,
            seat: source.seat,
            rating: source.rating,
            notes: String(repeating: "A vivid memory from the performance. ", count: 12)
        )
        let content = MemoryCardContent.make(source: longSource, options: MemoryCardOptions())

        let image = try XCTUnwrap(
            MemoryCardRenderer.render(content: content, template: .story, photo: nil)
        )

        XCTAssertEqual(image.cgImage?.width, 1_080)
        XCTAssertEqual(image.cgImage?.height, 1_920)
        XCTAssertNotNil(image.pngData())
    }
}
