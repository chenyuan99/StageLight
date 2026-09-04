import Photos
import UIKit

enum MemoryCardPhotoSaveError: LocalizedError, Equatable {
    case accessDenied
    case accessRestricted

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            String(localized: "Allow StageLight to add photos in Settings, then try again.")
        case .accessRestricted:
            String(localized: "This device does not allow apps to save photos.")
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

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
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
            activityDidFinish(false)
            return
        }

        Task {
            do {
                try await photoSaver.save(image)
                activityDidFinish(true)
            } catch {
                activityDidFinish(false)
            }
        }
    }
}
