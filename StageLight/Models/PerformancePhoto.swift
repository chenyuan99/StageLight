import Foundation
import SwiftData

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
