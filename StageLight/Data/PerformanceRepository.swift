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
}

@MainActor
final class PerformanceRepository: PerformanceRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
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
