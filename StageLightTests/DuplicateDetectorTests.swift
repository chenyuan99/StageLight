import XCTest
@testable import StageLight

final class DuplicateDetectorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func test_check_sameNormalizedTitleAndDay_returnsPossibleDuplicate() throws {
        let existing = makePerformance(title: "Hamilton", date: date(2026, 8, 24, 14))

        let result = DuplicateDetector.check(
            title: " HAMILTON ",
            date: date(2026, 8, 24, 19),
            performances: [existing],
            calendar: calendar
        )

        guard case let .possible(match) = result else {
            return XCTFail("Expected a possible duplicate")
        }
        XCTAssertEqual(match.id, existing.id)
    }

    func test_check_sameTitleDifferentDay_returnsNone() {
        let existing = makePerformance(title: "Hamilton", date: date(2026, 8, 24, 19))

        let result = DuplicateDetector.check(
            title: "Hamilton",
            date: date(2026, 8, 25, 19),
            performances: [existing],
            calendar: calendar
        )

        XCTAssertEqual(result, .none)
    }

    func test_check_differentTitleSameDay_returnsNone() {
        let existing = makePerformance(title: "Hamilton", date: date(2026, 8, 24, 19))

        let result = DuplicateDetector.check(
            title: "Hadestown",
            date: date(2026, 8, 24, 19),
            performances: [existing],
            calendar: calendar
        )

        XCTAssertEqual(result, .none)
    }

    private func makePerformance(title: String, date: Date) -> Performance {
        let show = Show(title: title)
        let performance = Performance(date: date, show: show)
        show.performances.append(performance)
        return performance
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
