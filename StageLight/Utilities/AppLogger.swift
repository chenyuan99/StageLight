import Foundation
import OSLog

enum AppLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "StageLight"
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let photo = Logger(subsystem: subsystem, category: "photo")
    static let recognition = Logger(subsystem: subsystem, category: "recognition")
    static let navigation = Logger(subsystem: subsystem, category: "navigation")
    static let general = Logger(subsystem: subsystem, category: "general")
}
