import Foundation

struct LibraryStatistics: Equatable {
    var showCount: Int
    var performanceCount: Int
    var theatreCount: Int
    var averageRating: Double?
    var performancesThisYear: Int
    var mostWatchedShow: String?
    var favoriteTheatre: String?

    static let empty = LibraryStatistics(
        showCount: 0,
        performanceCount: 0,
        theatreCount: 0,
        averageRating: nil,
        performancesThisYear: 0,
        mostWatchedShow: nil,
        favoriteTheatre: nil
    )

    static func calculate(
        performances: [Performance],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> LibraryStatistics {
        guard !performances.isEmpty else { return .empty }

        let showIDs = Set(performances.compactMap { $0.show?.id })
        let theatres = Set(
            performances
                .map { $0.theatre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        let ratings = performances.compactMap(\.rating)
        let averageRating = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
        let currentYear = calendar.component(.year, from: now)
        let thisYear = performances.filter {
            calendar.component(.year, from: $0.date) == currentYear
        }.count

        let showCounts = Dictionary(grouping: performances.compactMap(\.show), by: \.id)
            .map { (show: $0.value[0], count: $0.value.count) }
        let mostWatchedShow = showCounts
            .sorted {
                $0.count == $1.count
                    ? $0.show.title.localizedStandardCompare($1.show.title) == .orderedAscending
                    : $0.count > $1.count
            }
            .first?.show.title

        let namedTheatres = performances
            .map { $0.theatre.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let theatreGroups = Dictionary(grouping: namedTheatres, by: { $0.lowercased() })
            .map { (name: $0.value[0], count: $0.value.count) }
        let favoriteTheatre = theatreGroups
            .sorted {
                $0.count == $1.count
                    ? $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    : $0.count > $1.count
            }
            .first?.name

        return LibraryStatistics(
            showCount: showIDs.count,
            performanceCount: performances.count,
            theatreCount: theatres.count,
            averageRating: averageRating,
            performancesThisYear: thisYear,
            mostWatchedShow: mostWatchedShow,
            favoriteTheatre: favoriteTheatre
        )
    }
}
