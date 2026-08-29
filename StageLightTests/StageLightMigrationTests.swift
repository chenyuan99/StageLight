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

        let schema = Schema(versionedSchema: StageLightSchemaV2.self)
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
}
