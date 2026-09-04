import Foundation

struct ReviewPromptPolicy {
    static let minimumPerformanceCount = 3

    static func shouldRequestReview(
        performanceCount: Int,
        currentVersion: String,
        lastRequestedVersion: String?,
        isUITesting: Bool
    ) -> Bool {
        guard !isUITesting else { return false }
        guard performanceCount >= minimumPerformanceCount else { return false }
        guard !currentVersion.isEmpty else { return false }
        return lastRequestedVersion != currentVersion
    }
}
