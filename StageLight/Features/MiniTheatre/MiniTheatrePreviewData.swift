#if DEBUG
import Foundation
import SwiftData

enum MiniTheatrePreviewData {
    @MainActor static func insert(into context: ModelContext) {
        let samples = [
            ("STRANGER THINGS The First Shadow", "Marquis Theatre", "New York", 10),
            ("STRANGER THINGS The First Shadow", "Marquis Theatre", "New York", 60),
            ("Wicked", "Gershwin Theatre", "New York", 120),
            ("Hamilton", "Richard Rodgers Theatre", "New York", 200),
            ("A theatre night in London", "National Theatre", "London", 240),
            ("An evening in Tokyo", "帝国劇場", "東京", 300)
        ]
        for (title, theatre, city, daysAgo) in samples {
            let show = Show(title: title)
            let performance = Performance(date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
                                          theatre: theatre, city: city, notes: "A night to remember.", show: show)
            context.insert(performance)
        }
    }
}
#endif
