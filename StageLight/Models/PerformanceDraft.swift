import Foundation

struct PerformanceDraft: Equatable {
    var showTitle: String
    var date: Date
    var includesTime: Bool
    var time: Date?
    var theatre: String
    var city: String
    var seatSection: String
    var seatRow: String
    var seatNumber: String
    var rating: Double?
    var notes: String
    var photoFilenames: [String]

    init(
        showTitle: String = "",
        date: Date = .now,
        includesTime: Bool = false,
        time: Date? = nil,
        theatre: String = "",
        city: String = "",
        seatSection: String = "",
        seatRow: String = "",
        seatNumber: String = "",
        rating: Double? = nil,
        notes: String = "",
        photoFilenames: [String] = []
    ) {
        self.showTitle = showTitle
        self.date = date
        self.includesTime = includesTime
        self.time = time
        self.theatre = theatre
        self.city = city
        self.seatSection = seatSection
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.rating = rating
        self.notes = notes
        self.photoFilenames = photoFilenames
    }

    init(performance: Performance) {
        self.init(
            showTitle: performance.show?.title ?? "",
            date: performance.date,
            includesTime: performance.time != nil,
            time: performance.time,
            theatre: performance.theatre,
            city: performance.city,
            seatSection: performance.seatSection,
            seatRow: performance.seatRow,
            seatNumber: performance.seatNumber,
            rating: performance.rating,
            notes: performance.notes,
            photoFilenames: performance.photos
                .sorted { $0.sortOrder < $1.sortOrder }
                .map(\.filename)
        )
    }

    func validate() throws -> PerformanceDraft {
        var validated = self
        validated.showTitle = showTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !validated.showTitle.isEmpty else {
            throw DraftValidationError.missingShowTitle
        }

        if let rating {
            let isInRange = (0.5...5).contains(rating)
            let isHalfStep = (rating * 2).rounded() == rating * 2
            guard isInRange, isHalfStep else {
                throw DraftValidationError.invalidRating
            }
        }

        validated.theatre = theatre.trimmingCharacters(in: .whitespacesAndNewlines)
        validated.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        validated.seatSection = seatSection.trimmingCharacters(in: .whitespacesAndNewlines)
        validated.seatRow = seatRow.trimmingCharacters(in: .whitespacesAndNewlines)
        validated.seatNumber = seatNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !includesTime {
            validated.time = nil
        }
        return validated
    }
}

enum DraftValidationError: LocalizedError, Equatable {
    case missingShowTitle
    case invalidRating

    var errorDescription: String? {
        switch self {
        case .missingShowTitle:
            return String(localized: "Enter a show title.")
        case .invalidRating:
            return String(localized: "Choose a rating from 0.5 to 5 stars.")
        }
    }
}
