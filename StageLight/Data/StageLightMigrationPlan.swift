import Foundation
import SwiftData

enum StageLightSchemaV1: VersionedSchema {
    nonisolated(unsafe) static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        Show.self,
        Performance.self,
        PerformancePhoto.self
    ]

    @Model
    final class Show {
        @Attribute(.unique) var id: UUID
        var title: String
        var normalizedTitle: String
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Performance.show)
        var performances: [Performance]

        init(
            id: UUID = UUID(),
            title: String,
            normalizedTitle: String,
            createdAt: Date = .now,
            performances: [Performance] = []
        ) {
            self.id = id
            self.title = title
            self.normalizedTitle = normalizedTitle
            self.createdAt = createdAt
            self.performances = performances
        }
    }

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
    }

    @Model
    final class PerformancePhoto {
        @Attribute(.unique) var id: UUID
        var filename: String
        var sortOrder: Int
        var createdAt: Date
        var performance: Performance?

        init(
            id: UUID = UUID(),
            filename: String,
            sortOrder: Int,
            createdAt: Date = .now,
            performance: Performance? = nil
        ) {
            self.id = id
            self.filename = filename
            self.sortOrder = sortOrder
            self.createdAt = createdAt
            self.performance = performance
        }
    }
}

// Frozen shipped schema. Never add properties here; evolve the next schema instead.
enum StageLightSchemaV2: VersionedSchema {
    nonisolated(unsafe) static let versionIdentifier = Schema.Version(2, 0, 0)
    static let models: [any PersistentModel.Type] = [Show.self, Performance.self, PerformancePhoto.self]
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

    @Model
    final class Performance {
        var id: UUID = UUID()
        var date: Date = Date.now
        var time: Date?
        var theatre: String = ""
        var city: String = ""
        var seatSection: String = ""
        var seatRow: String = ""
        var seatNumber: String = ""
        var rating: Double?
        var notes: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var show: Show?

        @Relationship(deleteRule: .cascade, inverse: \PerformancePhoto.performance)
        var photos: [PerformancePhoto]?

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

        var photoList: [PerformancePhoto] { photos ?? [] }

        var formattedSeat: String? {
            let components = [seatSection, seatRow, seatNumber]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return components.isEmpty ? nil : components.joined(separator: " · ")
        }
    }

    @Model
    final class PerformancePhoto {
        var id: UUID = UUID()
        var filename: String = ""
        var sortOrder: Int = 0
        var createdAt: Date = Date.now
        @Attribute(.externalStorage) var imageData: Data?
        var performance: Performance?

        init(
            id: UUID = UUID(),
            filename: String,
            sortOrder: Int,
            createdAt: Date = .now,
            imageData: Data? = nil,
            performance: Performance? = nil
        ) {
            self.id = id
            self.filename = filename
            self.sortOrder = sortOrder
            self.createdAt = createdAt
            self.imageData = imageData
            self.performance = performance
        }
    }
}

enum StageLightSchemaV3: VersionedSchema {
    nonisolated(unsafe) static let versionIdentifier = Schema.Version(3, 0, 0)
    static let models: [any PersistentModel.Type] = [Show.self, Performance.self, PerformancePhoto.self]
}

enum StageLightMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [StageLightSchemaV1.self, StageLightSchemaV2.self, StageLightSchemaV3.self]
    nonisolated(unsafe) static let stages: [MigrationStage] = [
        .lightweight(fromVersion: StageLightSchemaV1.self, toVersion: StageLightSchemaV2.self),
        .lightweight(fromVersion: StageLightSchemaV2.self, toVersion: StageLightSchemaV3.self)
    ]
}
