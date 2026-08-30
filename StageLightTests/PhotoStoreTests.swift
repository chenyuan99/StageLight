import XCTest
import UIKit
@testable import StageLight

final class PhotoStoreTests: XCTestCase {
    func test_resizedSize_largeImage_capsLongEdge() {
        let size = ImageProcessor.resizedSize(for: CGSize(width: 4_000, height: 2_000))

        XCTAssertEqual(size.width, 2_400)
        XCTAssertEqual(size.height, 1_200)
    }

    func test_resizedSize_smallImage_doesNotUpscale() {
        let size = CGSize(width: 800, height: 1_200)

        XCTAssertEqual(ImageProcessor.resizedSize(for: size), size)
    }

    @MainActor
    func test_saveAndLoad_validImage_roundTripsAndDeletes() async throws {
        let (directory, store) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200))
        let source = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
        }

        let filename = try await store.save(source)
        let loaded = try await store.load(filename: filename)
        let storedData = try await store.loadData(filename: filename)

        XCTAssertEqual(loaded.size, CGSize(width: 100, height: 200))
        XCTAssertFalse(storedData.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appending(path: filename).path))

        try store.delete(filename: filename)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appending(path: filename).path))
    }

    @MainActor
    func test_load_pathTraversal_throwsInvalidFilename() async {
        let (directory, store) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            _ = try await store.load(filename: "../secret.jpg")
            XCTFail("Expected invalid filename")
        } catch {
            XCTAssertEqual(error as? PhotoStoreError, .invalidFilename)
        }
    }

    @MainActor
    private func makeStore() -> (URL, LocalPhotoStore) {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        return (directory, LocalPhotoStore(directory: directory))
    }
}
