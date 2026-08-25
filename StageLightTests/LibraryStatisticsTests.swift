import XCTest
@testable import StageLight

final class LibraryStatisticsTests: XCTestCase {
    func test_calculate_knownLibrary_returnsExpectedValues() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 25))!

        let hamilton = Show(title: "Hamilton")
        let hadestown = Show(title: "Hadestown")
        let performances = [
            Performance(date: date(2026, 8, 24, calendar), theatre: "Richard Rodgers Theatre", rating: 5, show: hamilton),
            Performance(date: date(2025, 12, 18, calendar), theatre: "Richard Rodgers Theatre", rating: 4, show: hamilton),
            Performance(date: date(2026, 5, 2, calendar), theatre: "Walter Kerr Theatre", rating: nil, show: hadestown)
        ]
        hamilton.performances = Array(performances.prefix(2))
        hadestown.performances = [performances[2]]

        let statistics = LibraryStatistics.calculate(
            performances: performances,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(statistics.showCount, 2)
        XCTAssertEqual(statistics.performanceCount, 3)
        XCTAssertEqual(statistics.theatreCount, 2)
        XCTAssertEqual(statistics.averageRating, 4.5)
        XCTAssertEqual(statistics.performancesThisYear, 2)
        XCTAssertEqual(statistics.mostWatchedShow, "Hamilton")
        XCTAssertEqual(statistics.favoriteTheatre, "Richard Rodgers Theatre")
    }

    func test_calculate_emptyLibrary_returnsSafeEmptyValues() {
        let statistics = LibraryStatistics.calculate(performances: [])

        XCTAssertEqual(statistics.showCount, 0)
        XCTAssertEqual(statistics.performanceCount, 0)
        XCTAssertEqual(statistics.theatreCount, 0)
        XCTAssertNil(statistics.averageRating)
        XCTAssertNil(statistics.mostWatchedShow)
        XCTAssertNil(statistics.favoriteTheatre)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
