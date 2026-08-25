import Foundation

enum DuplicateCheckResult: Equatable {
    case none
    case possible(Performance)

    static func == (lhs: DuplicateCheckResult, rhs: DuplicateCheckResult) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.possible(lhsPerformance), .possible(rhsPerformance)):
            return lhsPerformance.id == rhsPerformance.id
        default:
            return false
        }
    }
}

enum DuplicateDetector {
    static func check(
        title: String,
        date: Date,
        performances: [Performance],
        calendar: Calendar = .current
    ) -> DuplicateCheckResult {
        let normalizedTitle = TitleNormalizer.normalize(title)
        guard !normalizedTitle.isEmpty else { return .none }

        if let match = performances.first(where: { performance in
            performance.show?.normalizedTitle == normalizedTitle
                && calendar.isDate(performance.date, inSameDayAs: date)
        }) {
            return .possible(match)
        }
        return .none
    }
}
