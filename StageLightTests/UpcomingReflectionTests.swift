import SwiftData
import XCTest
import MiniTheatreCore
@testable import StageLight

@MainActor final class UpcomingReflectionTests: XCTestCase {
    func testLegacyFutureDateRemainsAttendedAndUnknownStateIsPreserved() throws {
        let p = Performance(date: .distantFuture)
        XCTAssertTrue(p.isAttended)
        p.statusRaw = "future-status"
        XCTAssertFalse(p.isAttended)
        XCTAssertEqual(PerformanceDraft(performance: p).statusRaw, "future-status")
    }

    func testTransitionsPreserveIdentityContentAndPhotosAfterReload() throws {
        let c = try container()
        let r = PerformanceRepository(context: c.mainContext)
        var d = PerformanceDraft(showTitle: "Hamilton", theatre: "Hobby Center", seatRow: "P", rating: 4.5, notes: " 原文\n🎭 ", photoFilenames: ["ticket.jpg"], photoDataByFilename: ["ticket.jpg": Data([1,2,3])])
        d.statusRaw = "upcoming"
        let p = try r.save(draft: d)
        let id = p.id, photoID = p.photoList[0].id, showID = p.show?.id, created = p.createdAt
        for (from, to) in [("upcoming", "attended"), ("attended", "upcoming"), ("upcoming", "cancelled"), ("cancelled", "upcoming")] {
            try r.transition(p, to: to, expectedStatus: from)
        }
        let other = ModelContext(c)
        let restored = try XCTUnwrap(other.fetch(FetchDescriptor<Performance>()).first)
        XCTAssertEqual(restored.id, id)
        XCTAssertEqual(restored.show?.id, showID)
        XCTAssertEqual(restored.createdAt, created)
        XCTAssertEqual(restored.notes, d.notes)
        XCTAssertEqual(restored.seatRow, "P")
        XCTAssertEqual(restored.rating, 4.5)
        XCTAssertEqual(restored.photoList[0].id, photoID)
        XCTAssertEqual(restored.photoList[0].imageData, Data([1,2,3]))
        XCTAssertEqual(try r.fetchPerformances().count, 1)
    }

    func testFocusedNotesRejectConflictAndDoNotOverwriteOtherFields() throws {
        let c = try container(), r = PerformanceRepository(context: c.mainContext)
        let p = try r.save(draft: PerformanceDraft(showTitle: "Test", notes: "original"))
        p.theatre = "New venue"
        try c.mainContext.save()
        try r.updateNotes(p, notes: " 中文\n日本語 🎭 ", expectedNotes: "original")
        XCTAssertEqual(p.theatre, "New venue")
        XCTAssertThrowsError(try r.updateNotes(p, notes: "stale draft", expectedNotes: "original"))
        XCTAssertEqual(p.notes, " 中文\n日本語 🎭 ")
        try r.updateNotes(p, notes: "", expectedNotes: p.notes)
        XCTAssertEqual(p.notes, "")
    }

    func testStaleTransitionAndDeletedRecordDoNotRecreateData() throws {
        let c = try container(), r = PerformanceRepository(context: c.mainContext)
        let p = try r.save(draft: PerformanceDraft(showTitle: "Test"))
        XCTAssertThrowsError(try r.transition(p, to: "attended", expectedStatus: "upcoming"))
        try r.delete(p)
        XCTAssertThrowsError(try r.updateNotes(p, notes: "recover me", expectedNotes: ""))
        XCTAssertTrue(try r.fetchPerformances().isEmpty)
    }

    func testNonAttendedRecordsDoNotContributeToStatisticsOrShowRating() {
        let show = Show(title: "Test")
        let a = Performance(date: .now, rating: 3, show: show)
        let b = Performance(date: .now, rating: 5, show: show)
        b.statusRaw = "upcoming"
        let c = Performance(date: .now, rating: 1, show: show)
        c.statusRaw = "cancelled"
        show.performances = [a,b,c]
        XCTAssertEqual(LibraryStatistics.calculate(performances: [a,b,c]).performanceCount, 1)
        XCTAssertEqual(show.averageRating, 3)
        XCTAssertEqual(show.attendedPerformances.count, 1)
    }

    func testReflectionIsOffByDefaultAndOfferIsConsumedOncePerVisit() {
        let suite = "reflection-test-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = UUID(), other = UUID()
        XCTAssertFalse(ReflectionPolicy.consumeOffer(for: id, defaults: defaults))
        defaults.set(true, forKey: ReflectionPolicy.enabledKey)
        XCTAssertTrue(ReflectionPolicy.consumeOffer(for: id, defaults: defaults))
        XCTAssertFalse(ReflectionPolicy.consumeOffer(for: id, defaults: defaults))
        XCTAssertTrue(ReflectionPolicy.consumeOffer(for: other, defaults: defaults))
        defaults.set(false, forKey: ReflectionPolicy.enabledKey)
        XCTAssertFalse(ReflectionPolicy.consumeOffer(for: UUID(), defaults: defaults))
    }

    func testSaveFailureRestoresOnlyChangedFields() throws {
        let c = try container()
        let p = Performance(date: .now, notes: "original")
        c.mainContext.insert(p)
        try c.mainContext.save()
        let r = PerformanceRepository(context: c.mainContext, save: { throw CocoaError(.fileWriteUnknown) })
        p.city = "Keep unrelated edit"
        XCTAssertThrowsError(try r.updateNotes(p, notes: "draft", expectedNotes: "original"))
        XCTAssertEqual(p.notes, "original")
        XCTAssertEqual(p.city, "Keep unrelated edit")
        XCTAssertThrowsError(try r.transition(p, to: "upcoming", expectedStatus: nil))
        XCTAssertNil(p.statusRaw)
    }

    func testPlanningAndStatusTogglesDoNotDuplicateBunnyAwards() throws {
        let c = try container(), r = PerformanceRepository(context: c.mainContext)
        var draft = PerformanceDraft(showTitle: "Test", date: .now.addingTimeInterval(-86400))
        draft.statusRaw = "upcoming"
        let p = try r.save(draft: draft)
        let library = LibraryStore(context: c.mainContext)
        let bunny = MiniTheatreStore(inMemory: true)
        func reconcile() {
            library.refresh()
            bunny.reconcile(enabled: true, visits: library.attendedPerformances.map {
                CompanionVisit(id: $0.id, date: $0.date, theatre: $0.theatre, city: $0.city)
            })
        }
        reconcile()
        let initial = bunny.owned
        try r.transition(p, to: "attended", expectedStatus: "upcoming")
        reconcile()
        let earned = bunny.owned
        XCTAssertGreaterThan(earned.count, initial.count)
        try r.transition(p, to: "upcoming", expectedStatus: "attended")
        reconcile()
        XCTAssertEqual(bunny.owned, earned)
        try r.transition(p, to: "attended", expectedStatus: "upcoming")
        reconcile()
        XCTAssertEqual(bunny.owned, earned)
    }

    func testUnrelatedEditPreservesUnknownStatus() throws {
        let c = try container(), r = PerformanceRepository(context: c.mainContext)
        let p = try r.save(draft: PerformanceDraft(showTitle: "Test"))
        p.statusRaw = "future-version-state"
        try c.mainContext.save()
        var draft = PerformanceDraft(performance: p)
        draft.city = "London"
        try r.update(p, with: draft)
        XCTAssertEqual(p.statusRaw, "future-version-state")
        XCTAssertEqual(p.city, "London")
    }

    private func container() throws -> ModelContainer {
        try ModelContainer(for: Show.self, Performance.self, PerformancePhoto.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }
}
