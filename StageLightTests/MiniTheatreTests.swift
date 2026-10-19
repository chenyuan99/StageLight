import XCTest
import SwiftData
import SwiftUI
import MiniTheatreCore
@testable import StageLight

@MainActor final class MiniTheatreTests: XCTestCase {
    func testSchemaVersionRemainsStableAcrossReads() {
        XCTAssertEqual(CompanionSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertEqual(CompanionSchemaV1.versionIdentifier, CompanionSchemaV1.versionIdentifier)
    }
    private func visits(_ count: Int = 10) -> [CompanionVisit] {
        (0..<count).map { CompanionVisit(id: UUID(), date: .now.addingTimeInterval(-86400 * 4), theatre: "Venue \($0)", city: "NYC") }
    }
    func testBundledCatalogAndFourPosesExist() throws {
        let catalog = try MiniTheatreStore.loadCatalog()
        XCTAssertEqual(catalog.props.count, 6)
        for pose in ["base", "idle", "curious", "celebrate"] {
            XCTAssertNotNil(UIImage(named: "mini_bunny_\(pose)"))
        }
        for strings in MiniCopy.values.values { XCTAssertEqual(strings.count, 4); XCTAssertFalse(strings.contains("")) }
    }
    func testDisabledDoesNotOpenStoreOrGrant() {
        let store = MiniTheatreStore(storeURL: URL(fileURLWithPath: "/nonexistent/companion.store"))
        store.reconcile(enabled: false, visits: visits())
        XCTAssertTrue(store.owned.isEmpty); XCTAssertFalse(store.failed); XCTAssertNil(store.catalog)
    }
    func testBackfillIsSingleDurableBatchAndIdempotent() {
        let store = MiniTheatreStore(inMemory: true)
        let snapshot = visits()
        store.reconcile(enabled: true, visits: snapshot)
        XCTAssertFalse(store.failed); XCTAssertEqual(store.owned.count, 6); XCTAssertEqual(store.pending.count, 6)
        store.reconcile(enabled: true, visits: snapshot)
        XCTAssertEqual(store.pending.count, 6)
        store.acknowledge(); XCTAssertTrue(store.pending.isEmpty)
        store.reconcile(enabled: true, visits: snapshot)
        XCTAssertTrue(store.pending.isEmpty)
    }
    func testFailedCommitCanRetryWithoutPartialOwnership() {
        struct Failure: Error {}
        let store = MiniTheatreStore(inMemory: true)
        store.beforeSave = { throw Failure() }
        store.reconcile(enabled: true, visits: visits())
        XCTAssertTrue(store.failed); XCTAssertTrue(store.owned.isEmpty)
        store.beforeSave = nil
        store.reconcile(enabled: true, visits: visits())
        XCTAssertFalse(store.failed); XCTAssertEqual(store.owned.count, 6)
    }
    func testFailedEquipmentSaveKeepsLastOutfit() {
        struct Failure: Error {}
        let store = MiniTheatreStore(inMemory: true)
        store.reconcile(enabled: true, visits: visits())
        store.equip("welcome_pennant", slot: .handheld)
        store.beforeSave = { throw Failure() }
        store.equip("memory_bouquet", slot: .handheld)
        XCTAssertTrue(store.failed); XCTAssertEqual(store.outfit[.handheld], "welcome_pennant")
        store.beforeSave = nil
        store.reconcile(enabled: true, visits: [])
        XCTAssertEqual(store.outfit[.handheld], "welcome_pennant")
        XCTAssertEqual(store.owned.count, 6)
    }
    func testDisableAndDeletedHistoryKeepAwardsAndOutfit() {
        let store = MiniTheatreStore(inMemory: true)
        store.reconcile(enabled: true, visits: visits())
        store.equip("velvet_curtain", slot: .background)
        store.reconcile(enabled: false, visits: [])
        store.reconcile(enabled: true, visits: [])
        XCTAssertEqual(store.owned.count, 6); XCTAssertEqual(store.outfit[.background], "velvet_curtain")
    }
    func testReopenLocalStorePreservesAwardsAndOutfit() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        do {
            let first = MiniTheatreStore(storeURL: url)
            first.reconcile(enabled: true, visits: visits())
            first.equip("memory_bouquet", slot: .handheld)
            first.rename("My bunny"); first.acknowledge()
            XCTAssertFalse(first.failed)
        }
        let reopened = MiniTheatreStore(storeURL: url)
        reopened.reconcile(enabled: true, visits: [])
        XCTAssertEqual(reopened.owned.count, 6); XCTAssertTrue(reopened.pending.isEmpty)
        XCTAssertEqual(reopened.outfit[.handheld], "memory_bouquet"); XCTAssertEqual(reopened.nickname, "My bunny")
    }
    func testCorruptStoreIsNotDeletedOrRecreated() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("corrupt.store")
        let bytes = Data("not a database".utf8)
        try bytes.write(to: url)
        let store = MiniTheatreStore(storeURL: url)
        store.reconcile(enabled: true, visits: visits())
        XCTAssertTrue(store.failed); XCTAssertEqual(try Data(contentsOf: url), bytes)
    }
    func testDiaryContentRemainsUnchangedOnAwardFailure() {
        struct Failure: Error {}
        let show = Show(title: "Private title")
        let photo = PerformancePhoto(filename: "private.jpg", sortOrder: 0, imageData: Data([1, 2, 3]))
        let p = Performance(date: .now.addingTimeInterval(-86400 * 2), theatre: "Private venue", city: "City", notes: "Secret", show: show, photos: [photo])
        let updated = p.updatedAt, id = p.id
        let store = MiniTheatreStore(inMemory: true)
        store.beforeSave = { throw Failure() }
        store.reconcile(enabled: true, visits: [CompanionVisit(id: p.id, date: p.date, theatre: p.theatre, city: p.city)])
        XCTAssertEqual(p.id, id); XCTAssertEqual(p.updatedAt, updated); XCTAssertEqual(p.notes, "Secret")
        XCTAssertTrue(p.show === show); XCTAssertEqual(photo.imageData, Data([1, 2, 3])); XCTAssertEqual(p.theatre, "Private venue")
    }
    func testCardRendersFourLanguagesAtExportSize() throws {
        for language in ["en", "zh-Hans", "zh-Hant", "ja"] {
            let image = try XCTUnwrap(MiniCardRenderer.render(outfit: [.background: "velvet_curtain", .handheld: "welcome_pennant"], language: language))
            XCTAssertEqual(image.size.width * image.scale, 1080)
            XCTAssertEqual(image.size.height * image.scale, 1350)
            let attachment = XCTAttachment(image: image); attachment.name = "mini-card-\(language)"
            attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
