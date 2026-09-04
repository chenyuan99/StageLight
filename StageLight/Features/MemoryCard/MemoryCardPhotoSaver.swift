import Photos
import UIKit

enum MemoryCardPhotoSaveError: LocalizedError, Equatable {
    case accessDenied
    case accessRestricted
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            String(localized: "Allow StageLight to add photos in Settings, then try again.")
        case .accessRestricted:
            String(localized: "This device does not allow apps to save photos.")
        case .imageEncodingFailed:
            String(localized: "The memory card could not be prepared for Photos.")
        }
    }
}

@MainActor
protocol MemoryCardPhotoSaving: Sendable {
    func save(_ image: UIImage) async throws
}

@MainActor
struct SystemMemoryCardPhotoSaver: MemoryCardPhotoSaving {
    func save(_ image: UIImage) async throws {
        guard let imageData = image.pngData() else {
            throw MemoryCardPhotoSaveError.imageEncodingFailed
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        switch status {
        case .authorized, .limited:
            break
        case .restricted:
            throw MemoryCardPhotoSaveError.accessRestricted
        case .denied, .notDetermined:
            throw MemoryCardPhotoSaveError.accessDenied
        @unknown default:
            throw MemoryCardPhotoSaveError.accessDenied
        }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appending(path: "StageLight-MemoryCard-\(UUID().uuidString).png")
        try imageData.write(to: temporaryURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: temporaryURL)
        }
    }
}

final class MemoryCardSaveToPhotosActivity: UIActivity, @unchecked Sendable {
    private let photoSaver: any MemoryCardPhotoSaving
    private var image: UIImage?

    init(photoSaver: any MemoryCardPhotoSaving = SystemMemoryCardPhotoSaver()) {
        self.photoSaver = photoSaver
        super.init()
    }

    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("co.riseworks.StageLight.save-memory-card-to-photos")
    }

    override var activityTitle: String? {
        String(localized: "Save to Photos")
    }

    override var activityImage: UIImage? {
        UIImage(systemName: "photo.badge.arrow.down")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        activityItems.contains { $0 is UIImage }
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        image = activityItems.compactMap { $0 as? UIImage }.first
    }

    override func perform() {
        guard let image else {
            Task { @MainActor [weak self] in
                self?.activityDidFinish(false)
            }
            return
        }

        let photoSaver = photoSaver
        Task { @MainActor [weak self] in
            do {
                try await photoSaver.save(image)
                self?.activityDidFinish(true)
            } catch {
                self?.activityDidFinish(false)
            }
        }
    }
}
