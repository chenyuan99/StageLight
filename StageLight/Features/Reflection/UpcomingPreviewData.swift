#if DEBUG
import Foundation
import SwiftData

enum UpcomingPreviewData {
    @MainActor static func insert(into context: ModelContext) {
        let show = Show(title: "Hadestown")
        let p = Performance(id: UUID(), date: Calendar.current.date(byAdding: .day, value: 7, to: .now)!, theatre: "Walter Kerr Theatre", city: "New York", seatSection: "Orchestra", seatRow: "F", seatNumber: "12", show: show)
        p.statusRaw = "upcoming"
        context.insert(p)
        let pastShow = Show(title: "A night at the theatre")
        context.insert(Performance(date: Calendar.current.date(byAdding: .day, value: -14, to: .now)!, theatre: "Local theatre", rating: 4.5, notes: "The curtain call was unforgettable.", show: pastShow))
        try? context.save()
    }
}
#endif
