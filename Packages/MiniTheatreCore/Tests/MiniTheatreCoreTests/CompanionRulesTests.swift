import Foundation
import XCTest
@testable import MiniTheatreCore

final class CompanionRulesTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!
    private var now: Date { date("2026-10-18T12:00:00Z") }
    private func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }
    private func prop(_ id: String, _ key: String, _ rule: MilestoneRule,
                      _ slot: PropSlot = .decoration, version: Int = 1) -> PropDefinition {
        PropDefinition(id: id, milestoneID: key, ruleVersion: version,
                       slot: slot, assetName: id, rule: rule)
    }
    private var props: [PropDefinition] { [
        prop("welcome_pennant", "welcome", .welcome, .handheld),
        prop("keepsake_ticket", "visits_1", .visits(1)),
        prop("golden_spotlight", "visits_3", .visits(3)),
        prop("velvet_curtain", "visits_5", .visits(5), .background),
        prop("memory_bouquet", "visits_10", .visits(10), .handheld),
        prop("theatre_suitcase", "venues_3", .venues(3))
    ] }
    private func catalog(_ values: [PropDefinition]? = nil, schema: Int = 1,
                         assets: Set<String>? = nil) -> CompanionCatalog {
        let values = values ?? props
        return CompanionCatalog(schemaVersion: schema, props: values,
                                availableAssets: assets ?? Set(values.map(\.assetName)))
    }
    private func visit(id: UUID = UUID(), at: Date? = nil,
                       theatre: String = "Marquis", city: String = "New York") -> CompanionVisit {
        CompanionVisit(id: id, date: at ?? date("2026-10-16T19:00:00Z"), theatre: theatre, city: city)
    }
    private func awards(_ visits: [CompanionVisit] = [], enabled: Bool = true,
                        owned: Set<String> = [], at: Date? = nil, zone: TimeZone? = nil,
                        using source: CompanionCatalog? = nil) throws -> [Award] {
        try CompanionRules.plan(enabled: enabled, visits: visits, now: at ?? now,
                                timeZone: zone ?? utc, catalog: source ?? catalog(), ownedKeys: owned)
    }
    private func keys(_ visits: [CompanionVisit] = []) throws -> [String] {
        try awards(visits).map(\.key)
    }
    private func invalid(_ value: CompanionCatalog, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try awards(using: value), file: file, line: line) {
            XCTAssertEqual($0 as? CompanionError, .invalidCatalog, file: file, line: line)
        }
    }
    func testDisabledProducesNoAwardsEvenForOldLibrary() throws {
        XCTAssertEqual(try awards((0..<20).map { _ in visit() }, enabled: false), [])
    }
    func testDisabledDoesNotValidateUnusedCatalog() throws {
        XCTAssertEqual(try awards(enabled: false, using: catalog(schema: 99)), [])
    }
    func testActivationGrantsWelcomeWithoutVisits() throws {
        XCTAssertEqual(try keys(), ["welcome"])
    }
    func testAllVisitThresholdBoundariesInCatalogOrder() throws {
        for (count, expected) in [(0, ["welcome"]), (1, ["welcome", "visits_1"]),
            (2, ["welcome", "visits_1"]), (3, ["welcome", "visits_1", "visits_3"]),
            (4, ["welcome", "visits_1", "visits_3"]),
            (5, ["welcome", "visits_1", "visits_3", "visits_5"]),
            (9, ["welcome", "visits_1", "visits_3", "visits_5"]),
            (10, ["welcome", "visits_1", "visits_3", "visits_5", "visits_10"])] {
            XCTAssertEqual(try keys((0..<count).map { _ in visit() }), expected, "count=\(count)")
        }
    }
    func testDuplicateUUIDCountsOnlyOnce() throws {
        let v = visit()
        XCTAssertEqual(try keys([v, v, v]), ["welcome", "visits_1"])
    }
    func testDistinctRepeatViewingsCountOnSameDay() throws {
        XCTAssertEqual(try keys([visit(), visit(), visit()]), ["welcome", "visits_1", "visits_3"])
    }
    func testTodayAndFutureDoNotCount() throws {
        XCTAssertEqual(try keys([visit(at: now), visit(at: now.addingTimeInterval(86400))]), ["welcome"])
    }
    func testStrictMidnightBoundary() throws {
        let midnight = date("2026-10-18T00:00:00Z")
        XCTAssertEqual(try keys([visit(at: midnight)]), ["welcome"])
        XCTAssertEqual(try keys([visit(at: midnight.addingTimeInterval(-1))]), ["welcome", "visits_1"])
    }
    func testInjectedTimeZoneChangesDayEligibility() throws {
        let clock = date("2026-10-18T01:00:00Z")
        let v = visit(at: date("2026-10-17T23:00:00Z"))
        XCTAssertEqual(try awards([v], at: clock).map(\.key), ["welcome", "visits_1"])
        XCTAssertEqual(try awards([v], at: clock, zone: TimeZone(identifier: "America/New_York")!).map(\.key), ["welcome"])
    }
    func testDSTUsesCalendarMidnightNotLast24Hours() throws {
        let ny = TimeZone(identifier: "America/New_York")!
        for (clock, boundary) in [("2026-03-08T20:00:00Z", "2026-03-08T05:00:00Z"),
                                  ("2026-11-01T20:00:00Z", "2026-11-01T04:00:00Z")] {
            XCTAssertEqual(try awards([visit(at: date(boundary))], at: date(clock), zone: ny).map(\.key), ["welcome"])
            XCTAssertEqual(try awards([visit(at: date(boundary).addingTimeInterval(-1))], at: date(clock), zone: ny).map(\.key), ["welcome", "visits_1"])
        }
    }
    func testBlankTheatreCountsVisitsButNotVenues() throws {
        XCTAssertEqual(try keys([visit(theatre: ""), visit(theatre: " \n"), visit(theatre: "\t")]), ["welcome", "visits_1", "visits_3"])
    }
    func testVenueWhitespaceIsTrimmed() throws {
        XCTAssertFalse(try keys([visit(), visit(theatre: " Marquis ", city: " New York\n"), visit()]).contains("venues_3"))
    }
    func testDifferentAndUnknownCitiesStayDistinct() throws {
        XCTAssertTrue(try keys([visit(), visit(city: "London"), visit(city: "")]).contains("venues_3"))
    }
    func testCaseAndAliasAreNotMerged() throws {
        XCTAssertTrue(try keys([visit(), visit(theatre: "MARQUIS"), visit(theatre: "Marquis Theatre")]).contains("venues_3"))
    }
    func testVenueKeyAvoidsDelimiterCollision() throws {
        XCTAssertTrue(try keys([visit(theatre: "A|B", city: "C"), visit(theatre: "A", city: "B|C"), visit()]).contains("venues_3"))
    }
    func testReconciliationIsIdempotent() throws {
        let visits = [visit(), visit(), visit()]
        let first = try awards(visits)
        XCTAssertEqual(try awards(visits, owned: Set(first.map(\.key))), [])
    }
    func testRuleVersionIsNotPartOfOwnershipKey() throws {
        let updated = catalog([prop("welcome_pennant", "welcome", .welcome, .handheld, version: 2)])
        XCTAssertEqual(try awards(owned: ["welcome"], using: updated), [])
    }
    func testAwardPayloadHasStableIdentityAndVersion() throws {
        XCTAssertEqual(try awards(), [Award(key: "welcome", propID: "welcome_pennant", ruleVersion: 1)])
    }
    func testDeletedHistoryProducesNoReplayOrRevocationPlan() throws {
        XCTAssertEqual(try awards([], owned: ["welcome", "visits_1", "retired_milestone"]), [])
    }
    func testExhaustedCatalogReturnsEmpty() throws {
        XCTAssertEqual(try awards((0..<20).map { visit(theatre: "Venue \($0)") }, owned: Set(props.map(\.milestoneID))), [])
    }
    func testNewMilestoneBackfillsWithoutRegrantingExisting() throws {
        let extra = prop("new_prop", "visits_2", .visits(2))
        XCTAssertEqual(try awards([visit(), visit()], owned: Set(props.map(\.milestoneID)), using: catalog(props + [extra])).map(\.key), ["visits_2"])
    }
    func testInvalidCatalogFailsClosed() {
        invalid(catalog(schema: 99))
        invalid(catalog(props + [props[0]]))
        invalid(catalog(props + [prop("different", "welcome", .welcome)]))
        invalid(catalog(props + [prop("welcome_pennant", "different", .visits(1))]))
        invalid(catalog([prop("bad", "bad", .visits(-1))]))
        invalid(catalog([prop("bad", "bad", .venues(-1))]))
        invalid(catalog(assets: []))
    }
    func testInputOrderDoesNotChangeAwards() throws {
        let visits = [visit(), visit(city: "London"), visit(city: "Tokyo")]
        XCTAssertEqual(try awards(visits), try awards(Array(visits.reversed())))
    }
    func testThousandVisitsHasBoundedAwardsAndImmutableInput() throws {
        let visits = (0..<1000).map { visit(theatre: "Venue \($0)") }
        let copy = visits
        XCTAssertEqual(try awards(visits).map(\.key), props.map(\.milestoneID))
        XCTAssertEqual(visits, copy)
    }
    func testEquipReplacesOnlyMatchingSlot() throws {
        let before: [PropSlot: String] = [.handheld: "welcome_pennant", .background: "velvet_curtain"]
        let after = try CompanionRules.equip("memory_bouquet", in: .handheld, ownedPropIDs: ["memory_bouquet"], catalog: catalog(), outfit: before)
        XCTAssertEqual(after, [.handheld: "memory_bouquet", .background: "velvet_curtain"])
        XCTAssertEqual(before[.handheld], "welcome_pennant")
    }
    func testUnequipRetiredPropIsAllowed() throws {
        XCTAssertEqual(try CompanionRules.equip(nil, in: .decoration, ownedPropIDs: [], catalog: catalog(), outfit: [.decoration: "retired"]), [:])
    }
    func testCannotEquipUnownedProp() {
        XCTAssertThrowsError(try CompanionRules.equip("welcome_pennant", in: .handheld, ownedPropIDs: [], catalog: catalog(), outfit: [:])) {
            XCTAssertEqual($0 as? CompanionError, .unownedProp)
        }
    }
    func testCannotEquipWrongSlot() {
        XCTAssertThrowsError(try CompanionRules.equip("welcome_pennant", in: .background, ownedPropIDs: ["welcome_pennant"], catalog: catalog(), outfit: [:])) {
            XCTAssertEqual($0 as? CompanionError, .slotMismatch)
        }
    }
    func testCannotNewlyEquipUnknownProp() {
        XCTAssertThrowsError(try CompanionRules.equip("retired", in: .handheld, ownedPropIDs: ["retired"], catalog: catalog(), outfit: [:])) {
            XCTAssertEqual($0 as? CompanionError, .unknownProp)
        }
    }
    func testNicknameTrimsAndAccepts24Graphemes() throws {
        XCTAssertEqual(try CompanionRules.validateNickname("  小剧灯\n"), "小剧灯")
        let composed = String(repeating: "👨‍👩‍👧‍👦", count: 24)
        XCTAssertEqual(try CompanionRules.validateNickname(composed), composed)
    }
    func testNicknameRejectsBlankAnd25Graphemes() {
        for input in [" \n", String(repeating: "兔", count: 25)] {
            XCTAssertThrowsError(try CompanionRules.validateNickname(input)) {
                XCTAssertEqual($0 as? CompanionError, .invalidNickname)
            }
        }
    }
}
