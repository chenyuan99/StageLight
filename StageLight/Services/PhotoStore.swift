import Foundation
import UIKit

@MainActor
protocol PhotoStoreProtocol {
    func save(_ image: UIImage) async throws -> String
    func load(filename: String) async throws -> UIImage
    func loadData(filename: String) async throws -> Data
    func delete(filename: String) throws
    func deleteAll() throws
}

enum PhotoStoreError: LocalizedError, Equatable {
    case encodingFailed
    case invalidFilename
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return String(localized: "The photo could not be prepared.")
        case .invalidFilename:
            return String(localized: "The photo filename is invalid.")
        case .unreadableImage:
            return String(localized: "The photo could not be opened.")
        }
    }
}

@MainActor
final class LocalPhotoStore: PhotoStoreProtocol {
    private let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.directory = applicationSupport.appending(
                path: "PerformancePhotos",
                directoryHint: .isDirectory
            )
        }
    }

    func save(_ image: UIImage) async throws -> String {
        let data = try ImageProcessor.jpegData(from: image)
        let filename = "\(UUID().uuidString.lowercased()).jpg"
        let directory = directory
        let destination = directory.appending(path: filename)

        try await Task.detached(priority: .utility) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try data.write(to: destination, options: .atomic)
        }.value
        return filename
    }

    func load(filename: String) async throws -> UIImage {
        let data = try await loadData(filename: filename)
        guard let image = UIImage(data: data) else {
            throw PhotoStoreError.unreadableImage
        }
        return image
    }

    func loadData(filename: String) async throws -> Data {
        let url = try safeURL(filename: filename)
        return try await Task.detached(priority: .utility) {
            try Data(contentsOf: url, options: .mappedIfSafe)
        }.value
    }

    func delete(filename: String) throws {
        let url = try safeURL(filename: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    func deleteAll() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private func safeURL(filename: String) throws -> URL {
        guard !filename.isEmpty,
              filename == URL(fileURLWithPath: filename).lastPathComponent,
              !filename.contains("..") else {
            throw PhotoStoreError.invalidFilename
        }
        return directory.appending(path: filename)
    }
}

enum ImageProcessor {
    static let maximumLongEdge: CGFloat = 2_400

    @MainActor
    static func jpegData(from image: UIImage) throws -> Data {
        let size = resizedSize(for: image.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalized = renderer.image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = normalized.jpegData(compressionQuality: 0.85) else {
            throw PhotoStoreError.encodingFailed
        }
        return data
    }

    static func resizedSize(for size: CGSize) -> CGSize {
        let longEdge = max(size.width, size.height)
        guard longEdge > maximumLongEdge, longEdge > 0 else { return size }
        let scale = maximumLongEdge / longEdge
        return CGSize(
            width: max(1, (size.width * scale).rounded()),
            height: max(1, (size.height * scale).rounded())
        )
    }
}
