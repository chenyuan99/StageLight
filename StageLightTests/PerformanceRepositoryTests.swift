import SwiftData
import XCTest
@testable import StageLight

final class PerformanceRepositoryTests: XCTestCase {
    @MainActor
    func test_save_firstPerformance_createsShowAndRelationship() throws {
        let (_, repository) = try makeRepository()
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
        XCTAssertEqual(shows[0].performances.count, 1)
        XCTAssertEqual(performance.show?.id, shows[0].id)
    }

    @MainActor
    func test_save_repeatViewing_reusesExistingShow() throws {
        let (_, repository) = try makeRepository()
        _ = try repository.save(draft: PerformanceDraft(showTitle: "Hamilton", date: .now))
        _ = try repository.save(
            draft: PerformanceDraft(
                showTitle: " HAMILTON ",
                date: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
            )
        )

        let shows = try repository.fetchShows()

        XCTAssertEqual(shows.count, 1)
        XCTAssertEqual(shows[0].performances.count, 2)
    }

    @MainActor
    func test_delete_lastPerformance_deletesEmptyParentShow() throws {
        let (_, repository) = try makeRepository()
        let performance = try repository.save(
            draft: PerformanceDraft(showTitle: "Hamilton", date: .now)
        )

        try repository.delete(performance)

        XCTAssertTrue(try repository.fetchShows().isEmpty)
        XCTAssertTrue(try repository.fetchPerformances().isEmpty)
    }

    @MainActor
    private func makeRepository() throws -> (ModelContainer, PerformanceRepository) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Show.self,
            Performance.self,
            PerformancePhoto.self,
            configurations: configuration
        )
        return (container, PerformanceRepository(context: container.mainContext))
    }
}
