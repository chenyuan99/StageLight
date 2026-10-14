import SwiftUI
import XCTest
@testable import StageLight

final class TheatreHistoryTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func event(id: String = "example", year: Int = 2003, month: Int = 10,
                       day: Int = 30, source: String = "https://example.org/event") -> TheatreHistoryEvent {
        TheatreHistoryEvent(id: id, year: year, month: month, day: day,
            title: "Example", venue: "Example Theatre", sourceName: "Archive",
            sourceURL: URL(string: source)!, translations: [
                "en": .init(heading: "Broadway opening", summary: "An example opened on Broadway.")
            ])
    }

    private func catalog(_ events: [TheatreHistoryEvent]) throws -> TheatreHistoryCatalog {
        try TheatreHistoryCatalog(schemaVersion: 1, revision: 1, events: events).validated()
    }

    func testBundledCatalogHasFiveSourcedEventsAndAllTranslations() throws {
        let catalog = try TheatreHistoryCatalog.bundled()
        XCTAssertEqual(catalog.events.count, 5)
        for event in catalog.events {
            XCTAssertEqual(Set(event.translations.keys), Set(["en", "zh-Hans", "zh-Hant", "ja"]))
            XCTAssertEqual(event.sourceURL.scheme, "https")
            XCTAssertFalse(event.localized(for: "ja").isFallback)
        }
    }

    func testMatchesOnlyExactLocalMonthAndDay() throws {
        let catalog = try catalog([event()])
        XCTAssertEqual(catalog.events(on: date("2026-10-30T12:00:00Z"), timeZone: utc).count, 1)
        XCTAssertTrue(catalog.events(on: date("2026-10-29T12:00:00Z"), timeZone: utc).isEmpty)
    }

    func testUsesLocalTimeZoneNotUTCOrPreferredCalendar() throws {
        let catalog = try catalog([event()])
        let instant = date("2026-10-30T01:00:00Z")
        XCTAssertTrue(catalog.events(on: instant, timeZone: TimeZone(identifier: "America/New_York")!).isEmpty)
        XCTAssertEqual(catalog.events(on: instant, timeZone: TimeZone(identifier: "Asia/Tokyo")!).count, 1)
    }

    func testExcludesCurrentYearAndFutureEvents() throws {
        let catalog = try catalog([event(year: 2026), event(id: "future", year: 2027)])
        XCTAssertTrue(catalog.events(on: date("2026-10-30T12:00:00Z"), timeZone: utc).isEmpty)
    }

    func testLeapDayDoesNotShiftToFebruary28() throws {
        let catalog = try catalog([event(year: 2000, month: 2, day: 29)])
        XCTAssertTrue(catalog.events(on: date("2026-02-28T12:00:00Z"), timeZone: utc).isEmpty)
        XCTAssertEqual(catalog.events(on: date("2028-02-29T12:00:00Z"), timeZone: utc).count, 1)
    }

    func testOrderIsDeterministicOldestFirstThenID() throws {
        let catalog = try catalog([event(id: "z"), event(id: "b", year: 1988), event(id: "a")])
        XCTAssertEqual(catalog.events(on: date("2026-10-30T12:00:00Z"), timeZone: utc).map(\.id), ["b", "a", "z"])
    }

    func testRejectsDuplicateIDsAndInvalidDate() {
        XCTAssertThrowsError(try catalog([event(), event()]))
        XCTAssertThrowsError(try catalog([event(year: 2001, month: 2, day: 29)]))
        XCTAssertThrowsError(try catalog([event(month: 13)]))
        XCTAssertThrowsError(try catalog([event(id: " ")]))
    }

    func testRejectsUnsafeSourcesAndUnsupportedEnvelope() {
        XCTAssertThrowsError(try catalog([event(source: "http://example.org")]))
        XCTAssertThrowsError(try TheatreHistoryCatalog(schemaVersion: 2, revision: 1, events: []).validated())
        XCTAssertThrowsError(try TheatreHistoryCatalog(schemaVersion: 1, revision: 0, events: []).validated())
    }

    func testRejectsMissingEnglishAndOverlongContent() throws {
        var value = event()
        value.translations = [:]
        XCTAssertThrowsError(try catalog([value]))
        value.translations = ["en": .init(heading: "Opening", summary: String(repeating: "x", count: 601))]
        XCTAssertThrowsError(try catalog([value]))
    }

    func testLocaleResolutionAndVisibleFallback() {
        XCTAssertEqual(HistoryLanguage.code(for: "zh_TW"), "zh-Hant")
        XCTAssertEqual(HistoryLanguage.code(for: "zh-HK"), "zh-Hant")
        XCTAssertEqual(HistoryLanguage.code(for: "zh-Hans-CN"), "zh-Hans")
        XCTAssertEqual(HistoryLanguage.code(for: "zh-Hans-TW"), "zh-Hans")
        XCTAssertEqual(HistoryLanguage.code(for: "zh-Hant-CN"), "zh-Hant")
        XCTAssertEqual(HistoryLanguage.code(for: "ja_JP"), "ja")
        XCTAssertEqual(HistoryLanguage.code(for: "en_US"), "en")
        XCTAssertTrue(event().localized(for: "ja").isFallback)
        XCTAssertEqual(event().localized(for: "ja").text.summary, "An example opened on Broadway.")
        XCTAssertFalse(event().localized(for: "en").isFallback)
    }

    func testDecodeRejectsMalformedInput() {
        XCTAssertThrowsError(try TheatreHistoryCatalog.decode(Data("not json".utf8)))
    }

    func testInterfaceTranslationsArePresent() {
        XCTAssertEqual(HistoryCopy.text("title", language: "en"), "Theatre on This Day")
        XCTAssertEqual(HistoryCopy.text("title", language: "zh-Hans"), "剧场的今天")
        XCTAssertEqual(HistoryCopy.text("title", language: "zh-Hant"), "劇場的今天")
        XCTAssertEqual(HistoryCopy.text("title", language: "ja"), "劇場の今日は何の日")
    }

    @MainActor
    func testDetailDoesNotOverflowCompactOrIPadWidth() throws {
        let event = try XCTUnwrap(TheatreHistoryCatalog.bundled().events.first { $0.id == "phantom-broadway-1988" })
        for width in [320.0, 402.0, 760.0] {
            for language in ["en", "zh-Hans", "zh-Hant", "ja"] {
                let host = UIHostingController(rootView: TheatreHistoryDetail(event: event)
                    .environment(\.locale, Locale(identifier: language))
                    .environment(\.dynamicTypeSize, .accessibility3))
                XCTAssertLessThanOrEqual(host.sizeThatFits(in: CGSize(width: width, height: 900)).width, width + 0.5)
            }
        }
    }

    @MainActor
    func testCardsRenderBothExportSizesInAllLanguages() throws {
        let event = try XCTUnwrap(TheatreHistoryCatalog.bundled().events.first { $0.id == "phantom-broadway-1988" })
        for language in ["en", "zh-Hans", "zh-Hant", "ja"] {
            for template in MemoryCardTemplate.allCases {
                let image = try XCTUnwrap(HistoryCardRenderer.render(event: event, language: language, template: template))
                XCTAssertEqual(image.cgImage?.width, Int(template.pixelSize.width))
                XCTAssertEqual(image.cgImage?.height, Int(template.pixelSize.height))
                let attachment = XCTAttachment(image: image)
                attachment.name = "export-\(language)-\(template.rawValue)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        XCTAssertEqual(MemoryCardBrand.signature, "Made with StageLight")
    }
}
