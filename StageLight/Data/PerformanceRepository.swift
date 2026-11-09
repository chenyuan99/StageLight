import Foundation
import SwiftData

@MainActor
protocol PerformanceRepositoryProtocol {
    func fetchShows() throws -> [Show]
    func fetchPerformances() throws -> [Performance]
    func save(draft: PerformanceDraft) throws -> Performance
    func update(_ performance: Performance, with draft: PerformanceDraft) throws
    func delete(_ performance: Performance) throws
    func deleteAll() throws
    func saveChanges() throws
    func transition(_ performance: Performance, to status: String, expectedStatus: String?) throws
    func updateNotes(_ performance: Performance, notes: String, expectedNotes: String) throws
}

@MainActor
final class PerformanceRepository: PerformanceRepositoryProtocol {
    private let context: ModelContext

    private let persist: () throws -> Void
    init(context: ModelContext, save: (() throws -> Void)? = nil) {
        self.context = context
        self.persist = save ?? { try context.save() }
    }

    private func requireExisting(_ performance: Performance) throws {
        let id = performance.id
        guard !performance.isDeleted,
              try context.fetch(FetchDescriptor<Performance>(predicate: #Predicate { $0.id == id })).contains(where: { $0.persistentModelID == performance.persistentModelID }) else {
            throw PerformanceEditError.missing
        }
    }

    func transition(_ performance: Performance, to status: String, expectedStatus: String?) throws {
        try requireExisting(performance)
        guard performance.statusRaw == expectedStatus else { throw PerformanceEditError.conflict }
        guard ["upcoming", "attended", "cancelled"].contains(status),
              expectedStatus == nil || ["upcoming", "attended", "cancelled"].contains(expectedStatus!) else {
            throw PerformanceEditError.conflict
        }
        let old = performance.statusRaw, timestamp = performance.updatedAt
        performance.statusRaw = status
        performance.updatedAt = .now
        do { try persist() } catch {
            performance.statusRaw = old; performance.updatedAt = timestamp
            throw error
        }
    }

    func updateNotes(_ performance: Performance, notes: String, expectedNotes: String) throws {
        try requireExisting(performance)
        guard performance.notes == expectedNotes else { throw PerformanceEditError.conflict }
        let timestamp = performance.updatedAt
        performance.notes = notes
        performance.updatedAt = .now
        do { try persist() } catch {
            performance.notes = expectedNotes; performance.updatedAt = timestamp
            throw error
        }
    }

    func fetchShows() throws -> [Show] {
        try context.fetch(FetchDescriptor<Show>())
    }

    func fetchPerformances() throws -> [Performance] {
        try context.fetch(FetchDescriptor<Performance>())
    }

    func save(draft: PerformanceDraft) throws -> Performance {
        let draft = try draft.validate()
        let normalizedTitle = TitleNormalizer.normalize(draft.showTitle)
        let show = try fetchShows().first { $0.normalizedTitle == normalizedTitle }
            ?? makeShow(title: draft.showTitle, normalizedTitle: normalizedTitle)

        let performance = Performance(
            date: draft.date,
            time: draft.includesTime ? draft.time : nil,
            theatre: draft.theatre,
            city: draft.city,
            seatSection: draft.seatSection,
            seatRow: draft.seatRow,
            seatNumber: draft.seatNumber,
            rating: draft.rating,
            notes: draft.notes,
            show: show
        )
        performance.statusRaw = draft.statusRaw
        context.insert(performance)

        for (index, filename) in draft.photoFilenames.enumerated() {
            let photo = PerformancePhoto(
                filename: filename,
                sortOrder: index,
                imageData: draft.photoDataByFilename[filename],
                performance: performance
            )
            context.insert(photo)
        }

        try context.save()
        return performance
    }

    func update(_ performance: Performance, with draft: PerformanceDraft) throws {
        let draft = try draft.validate()
        let oldShow = performance.show
        let normalizedTitle = TitleNormalizer.normalize(draft.showTitle)

        if oldShow?.normalizedTitle != normalizedTitle {
            oldShow?.performances?.removeAll { $0.id == performance.id }
            let newShow = try fetchShows().first { $0.normalizedTitle == normalizedTitle }
                ?? makeShow(title: draft.showTitle, normalizedTitle: normalizedTitle)
            performance.show = newShow
            if let oldShow, oldShow.performanceList.isEmpty {
                context.delete(oldShow)
            }
        } else {
            oldShow?.title = draft.showTitle
        }

        performance.statusRaw = draft.statusRaw
        performance.date = draft.date
        performance.time = draft.includesTime ? draft.time : nil
        performance.theatre = draft.theatre
        performance.city = draft.city
        performance.seatSection = draft.seatSection
        performance.seatRow = draft.seatRow
        performance.seatNumber = draft.seatNumber
        performance.rating = draft.rating
        performance.notes = draft.notes
        performance.updatedAt = .now

        let desiredFilenames = Set(draft.photoFilenames)
        for photo in performance.photoList where !desiredFilenames.contains(photo.filename) {
            context.delete(photo)
        }
        performance.photos?.removeAll { !desiredFilenames.contains($0.filename) }

        let existingFilenames = Set(performance.photoList.map(\.filename))
        for (index, filename) in draft.photoFilenames.enumerated() {
            if let photo = performance.photoList.first(where: { $0.filename == filename }) {
                photo.sortOrder = index
                if photo.imageData == nil {
                    photo.imageData = draft.photoDataByFilename[filename]
                }
            } else if !existingFilenames.contains(filename) {
                let photo = PerformancePhoto(
                    filename: filename,
                    sortOrder: index,
                    imageData: draft.photoDataByFilename[filename],
                    performance: performance
                )
                context.insert(photo)
            }
        }

        try context.save()
    }

    func delete(_ performance: Performance) throws {
        let show = performance.show
        show?.performances?.removeAll { $0.id == performance.id }
        context.delete(performance)
        if let show, show.performanceList.isEmpty {
            context.delete(show)
        }
        try context.save()
    }

    func deleteAll() throws {
        try context.delete(model: PerformancePhoto.self)
        try context.delete(model: Performance.self)
        try context.delete(model: Show.self)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }

    private func makeShow(title: String, normalizedTitle: String) -> Show {
        let show = Show(title: title, normalizedTitle: normalizedTitle)
        context.insert(show)
        return show
    }
}

// Test doubles that do not exercise focused editing keep their existing behavior.
extension PerformanceRepositoryProtocol {
    func transition(_ performance: Performance, to status: String, expectedStatus: String?) throws { throw PerformanceEditError.missing }
    func updateNotes(_ performance: Performance, notes: String, expectedNotes: String) throws { throw PerformanceEditError.missing }
}

enum PerformanceEditError: LocalizedError {
    case conflict, missing
    var errorDescription: String? {
        switch self {
        case .conflict: AppLanguage.localized("This record changed. Your draft is safe. Review the latest version before saving.")
        case .missing: AppLanguage.localized("This performance is no longer available. Copy your draft before closing.")
        }
    }
}
