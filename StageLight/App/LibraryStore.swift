import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class LibraryStore {
    private let repository: PerformanceRepositoryProtocol
    let photoStore: PhotoStoreProtocol
    let recognitionService: RecognitionServiceProtocol

    private(set) var shows: [Show] = []
    private(set) var performances: [Performance] = []
    var errorMessage: String?

    init(
        repository: PerformanceRepositoryProtocol,
        photoStore: PhotoStoreProtocol,
        recognitionService: RecognitionServiceProtocol
    ) {
        self.repository = repository
        self.photoStore = photoStore
        self.recognitionService = recognitionService
        refresh()
    }

    convenience init(context: ModelContext) {
        self.init(
            repository: PerformanceRepository(context: context),
            photoStore: LocalPhotoStore(),
            recognitionService: LocalOCRRecognitionService()
        )
    }

    var statistics: LibraryStatistics {
        LibraryStatistics.calculate(performances: performances)
    }

    func refresh() {
        do {
            performances = try repository.fetchPerformances().sorted { $0.date > $1.date }
            shows = try repository.fetchShows().sorted {
                ($0.latestPerformance?.date ?? .distantPast)
                    > ($1.latestPerformance?.date ?? .distantPast)
            }
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.persistence.error("Library refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func duplicateCheck(for draft: PerformanceDraft) -> DuplicateCheckResult {
        DuplicateDetector.check(
            title: draft.showTitle,
            date: draft.date,
            performances: performances
        )
    }

    @discardableResult
    func add(draft: PerformanceDraft, images: [UIImage]) async throws -> Performance {
        var draft = try draft.validate()
        var newFilenames: [String] = []

        do {
            for image in images {
                let filename = try await photoStore.save(image)
                newFilenames.append(filename)
                draft.photoDataByFilename[filename] = try await photoStore.loadData(filename: filename)
            }
            draft.photoFilenames.append(contentsOf: newFilenames)
            let performance = try repository.save(draft: draft)
            refresh()
            return performance
        } catch {
            for filename in newFilenames {
                try? photoStore.delete(filename: filename)
            }
            AppLogger.persistence.error("Performance save failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func update(
        _ performance: Performance,
        draft: PerformanceDraft,
        newImages: [UIImage]
    ) async throws {
        var draft = try draft.validate()
        let originalFilenames = Set(performance.photoList.map(\.filename))
        var newFilenames: [String] = []

        do {
            for image in newImages {
                let filename = try await photoStore.save(image)
                newFilenames.append(filename)
                draft.photoDataByFilename[filename] = try await photoStore.loadData(filename: filename)
            }
            draft.photoFilenames.append(contentsOf: newFilenames)
            try repository.update(performance, with: draft)

            let keptFilenames = Set(draft.photoFilenames)
            for filename in originalFilenames where !keptFilenames.contains(filename) {
                try? photoStore.delete(filename: filename)
            }
            refresh()
        } catch {
            for filename in newFilenames {
                try? photoStore.delete(filename: filename)
            }
            throw error
        }
    }

    func delete(_ performance: Performance) throws {
        for photo in performance.photoList {
            try photoStore.delete(filename: photo.filename)
        }
        try repository.delete(performance)
        refresh()
    }

    func resetForUITesting() {
        do {
            try photoStore.deleteAll()
            try repository.deleteAll()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareCloudSync() async {
        var addedData = false

        for performance in performances {
            for photo in performance.photoList where photo.imageData == nil {
                guard let data = try? await photoStore.loadData(filename: photo.filename) else {
                    continue
                }
                photo.imageData = data
                addedData = true
            }
        }

        guard addedData else { return }
        do {
            try repository.saveChanges()
        } catch {
            AppLogger.persistence.error(
                "Photo sync preparation failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
