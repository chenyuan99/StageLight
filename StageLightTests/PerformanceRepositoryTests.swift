import SwiftData
import XCTest
@testable import StageLight

final class PerformanceRepositoryTests: XCTestCase {
    @MainActor
    func test_save_firstPerformance_createsShowAndRelationship() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        let draft = PerformanceDraft(
            showTitle: "Hamilton",
            date: .now,
            theatre: "Richard Rodgers Theatre",
            rating: 5
        )

        let performance = try repository.save(draft: draft)
        let shows = try repository.fetchShows()

        XCTAssertEqual(shows.count, 1)
        XCTAssertEqual(shows[0].normalizedTitle, "hamilton")
        XCTAssertEqual(shows[0].performanceList.count, 1)
        XCTAssertEqual(performance.show?.id, shows[0].id)
    }

    @MainActor
    func test_save_repeatViewing_reusesExistingShow() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        _ = try repository.save(draft: PerformanceDraft(showTitle: "Hamilton", date: .now))
        _ = try repository.save(
            draft: PerformanceDraft(
                showTitle: " HAMILTON ",
                date: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
            )
        )

        let shows = try repository.fetchShows()

        XCTAssertEqual(shows.count, 1)
        XCTAssertEqual(shows[0].performanceList.count, 2)

    }

    @MainActor
    func test_save_photoData_persistsCloudSyncedPayload() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        let imageData = Data([0x01, 0x02, 0x03])
        let draft = PerformanceDraft(
            showTitle: "Hamilton",
            photoFilenames: ["photo.jpg"],
            photoDataByFilename: ["photo.jpg": imageData]
        )

        let performance = try repository.save(draft: draft)

        XCTAssertEqual(performance.photoList.count, 1)
        XCTAssertEqual(performance.photoList[0].imageData, imageData)
    }

    @MainActor
    func test_delete_lastPerformance_deletesEmptyParentShow() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        let performance = try repository.save(
            draft: PerformanceDraft(showTitle: "Hamilton", date: .now)
        )

        try repository.delete(performance)

        XCTAssertTrue(try repository.fetchShows().isEmpty)
        XCTAssertTrue(try repository.fetchPerformances().isEmpty)
    }

    @MainActor
    private func makeRepository() throws -> (ModelContainer, PerformanceRepository) {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: Show.self,
            Performance.self,
            PerformancePhoto.self,
            configurations: configuration
        )
        return (container, PerformanceRepository(context: container.mainContext))
    }
}
