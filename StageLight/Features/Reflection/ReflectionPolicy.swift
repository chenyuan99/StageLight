import Foundation

@MainActor enum ReflectionPolicy {
    static let enabledKey = "reflection.enabled"
    static func consumeOffer(for id: UUID, defaults: UserDefaults = .standard) -> Bool {
        guard defaults.bool(forKey: enabledKey) else { return false }
        let key = "reflection.offered.v1.\(id.uuidString)"
        guard !defaults.bool(forKey: key) else { return false }
        defaults.set(true, forKey: key)
        return true
    }
}
