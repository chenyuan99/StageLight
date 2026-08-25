import Foundation
import SwiftData

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
