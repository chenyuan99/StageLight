import Foundation
import SwiftData

@Model
final class Show {
    var id: UUID = UUID()
    var title: String = ""
    var normalizedTitle: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Performance.show)
    var performances: [Performance]?

    init(
        id: UUID = UUID(),
        title: String,
        normalizedTitle: String? = nil,
        createdAt: Date = .now,
        performances: [Performance] = []
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.normalizedTitle = normalizedTitle ?? TitleNormalizer.normalize(title)
        self.createdAt = createdAt
        self.performances = performances
    }

    var performanceList: [Performance] { performances ?? [] }

    var latestPerformance: Performance? {
        performanceList.max { $0.date < $1.date }
    }

    var averageRating: Double? {
        let ratings = performanceList.compactMap(\.rating)
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
}
