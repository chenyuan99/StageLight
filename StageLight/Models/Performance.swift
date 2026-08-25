import Foundation
import SwiftData

@Model
final class Performance {
    @Attribute(.unique) var id: UUID
    var date: Date
    var time: Date?
    var theatre: String
    var city: String
    var seatSection: String
    var seatRow: String
    var seatNumber: String
    var rating: Double?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var show: Show?

    @Relationship(deleteRule: .cascade, inverse: \PerformancePhoto.performance)
    var photos: [PerformancePhoto]

    init(
        id: UUID = UUID(),
        date: Date,
        time: Date? = nil,
        theatre: String = "",
        city: String = "",
        seatSection: String = "",
        seatRow: String = "",
        seatNumber: String = "",
        rating: Double? = nil,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        show: Show? = nil,
        photos: [PerformancePhoto] = []
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.theatre = theatre
        self.city = city
        self.seatSection = seatSection
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.show = show
        self.photos = photos
    }

    var formattedSeat: String? {
        let components = [seatSection, seatRow, seatNumber]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: " · ")
    }
}
