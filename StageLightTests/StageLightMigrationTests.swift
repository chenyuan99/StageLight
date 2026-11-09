import SwiftData
import XCTest
@testable import StageLight

@MainActor
final class StageLightMigrationTests: XCTestCase {
    func test_migrateVersion1Store_preservesExistingLibrary() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StageLightMigration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("default.store")
        let performanceID = UUID()

        do {
            let schema = Schema(versionedSchema: StageLightSchemaV1.self)
            let configuration = ModelConfiguration(
                "StageLightMigration",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            let context = container.mainContext
            let show = StageLightSchemaV1.Show(
                title: "Hadestown",
                normalizedTitle: "hadestown"
            )
            let performance = StageLightSchemaV1.Performance(
                id: performanceID,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                theatre: "Walter Kerr Theatre",
                city: "New York",
                rating: 4.5,
                notes: "Original local note",
                show: show
            )
            let photo = StageLightSchemaV1.PerformancePhoto(
                filename: "legacy-photo.jpg",
                sortOrder: 0,
                performance: performance
            )
            show.performances = [performance]
            performance.photos = [photo]
            context.insert(show)
            context.insert(performance)
            context.insert(photo)
            try context.save()
        }

        let schema = Schema(versionedSchema: StageLightSchemaV3.self)
        let configuration = ModelConfiguration(
            "StageLightMigration",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: StageLightMigrationPlan.self,
            configurations: [configuration]
        )
        let context = container.mainContext

        let shows = try context.fetch(FetchDescriptor<Show>())
        let performances = try context.fetch(FetchDescriptor<Performance>())
        let photos = try context.fetch(FetchDescriptor<PerformancePhoto>())

        XCTAssertEqual(shows.map(\.title), ["Hadestown"])
        XCTAssertEqual(shows.first?.performanceList.map(\.id), [performanceID])
        XCTAssertEqual(performances.first?.theatre, "Walter Kerr Theatre")
        XCTAssertEqual(performances.first?.city, "New York")
        XCTAssertEqual(performances.first?.rating, 4.5)
        XCTAssertEqual(performances.first?.notes, "Original local note")
        XCTAssertEqual(performances.first?.show?.title, "Hadestown")
        XCTAssertEqual(performances.first?.photoList.map(\.filename), ["legacy-photo.jpg"])
        XCTAssertEqual(photos.first?.performance?.id, performanceID)
        XCTAssertNil(photos.first?.imageData)
    }
    func testVersion2MigrationPreservesFutureBookingAsLegacyAttendedAndPhotoBytes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("legacy.store"), id = UUID(), photoID = UUID()
        let date = Date(timeIntervalSince1970: 2_000_000_000)
        do {
            let schema = Schema(versionedSchema: StageLightSchemaV2.self)
            let c = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let show = StageLightSchemaV2.Show(title: "Legacy")
            let p = StageLightSchemaV2.Performance(id: id, date: date, time: date, theatre: "Venue", city: "City", seatSection: "Stalls", seatRow: "P", seatNumber: "123", rating: 4.5, notes: "原文\n🎭", createdAt: date, updatedAt: date, show: show)
            let photo = StageLightSchemaV2.PerformancePhoto(id: photoID, filename: "original.jpg", sortOrder: 2, imageData: Data([9,8,7]), performance: p)
            show.performances = [p]; p.photos = [photo]
            c.mainContext.insert(show)
            try c.mainContext.save()
        }
        let schema = Schema(versionedSchema: StageLightSchemaV3.self)
        let c = try ModelContainer(for: schema, migrationPlan: StageLightMigrationPlan.self, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let p = try XCTUnwrap(c.mainContext.fetch(FetchDescriptor<Performance>()).first)
        XCTAssertEqual(p.id, id); XCTAssertNil(p.statusRaw); XCTAssertTrue(p.isAttended)
        XCTAssertEqual(p.date, date); XCTAssertEqual(p.time, date)
        XCTAssertEqual(p.createdAt, date); XCTAssertEqual(p.updatedAt, date)
        XCTAssertEqual(p.theatre, "Venue"); XCTAssertEqual(p.city, "City")
        XCTAssertEqual(p.seatSection, "Stalls"); XCTAssertEqual(p.seatRow, "P"); XCTAssertEqual(p.seatNumber, "123")
        XCTAssertEqual(p.rating, 4.5); XCTAssertEqual(p.notes, "原文\n🎭")
        XCTAssertEqual(p.show?.title, "Legacy")
        XCTAssertEqual(p.photoList.first?.id, photoID)
        XCTAssertEqual(p.photoList.first?.filename, "original.jpg")
        XCTAssertEqual(p.photoList.first?.sortOrder, 2)
        XCTAssertEqual(p.photoList.first?.imageData, Data([9,8,7]))
    }

}
