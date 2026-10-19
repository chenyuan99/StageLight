import Foundation

public enum PropSlot: String, Codable, CaseIterable, Sendable { case background, handheld, decoration }
public enum MilestoneRule: Equatable, Codable, Sendable { case welcome, visits(Int), venues(Int) }
public struct PropDefinition: Equatable, Codable, Sendable {
    public let id: String
    public let milestoneID: String
    public let ruleVersion: Int
    public let slot: PropSlot
    public let assetName: String
    public let rule: MilestoneRule
    public init(id: String, milestoneID: String, ruleVersion: Int, slot: PropSlot, assetName: String, rule: MilestoneRule) {
        self.id = id; self.milestoneID = milestoneID; self.ruleVersion = ruleVersion
        self.slot = slot; self.assetName = assetName; self.rule = rule
    }
}
public struct CompanionVisit: Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let theatre: String
    public let city: String
    public init(id: UUID, date: Date, theatre: String, city: String) {
        self.id = id; self.date = date; self.theatre = theatre; self.city = city
    }
}
public struct CompanionCatalog: Sendable {
    public let schemaVersion: Int
    public let props: [PropDefinition]
    public let availableAssets: Set<String>
    public init(schemaVersion: Int, props: [PropDefinition], availableAssets: Set<String>) {
        self.schemaVersion = schemaVersion; self.props = props; self.availableAssets = availableAssets
    }
    public func validate() throws {
        guard schemaVersion == 1, Set(props.map(\.id)).count == props.count,
              Set(props.map(\.milestoneID)).count == props.count else { throw CompanionError.invalidCatalog }
        for p in props {
            guard !p.id.isEmpty, !p.milestoneID.isEmpty, p.ruleVersion > 0,
                  availableAssets.contains(p.assetName) else { throw CompanionError.invalidCatalog }
            switch p.rule {
            case .welcome: break
            case .visits(let n), .venues(let n):
                guard n >= 0 else { throw CompanionError.invalidCatalog }
            }
        }
    }
}
public struct Award: Equatable, Sendable {
    public let key: String
    public let propID: String
    public let ruleVersion: Int
    public init(key: String, propID: String, ruleVersion: Int) {
        self.key = key; self.propID = propID; self.ruleVersion = ruleVersion
    }
}
public enum CompanionError: Error, Equatable {
    case invalidCatalog, unownedProp, slotMismatch, unknownProp, invalidNickname
}
public enum CompanionRules {
    private struct Venue: Hashable { let theatre: String; let city: String }
    public static func plan(enabled: Bool, visits: [CompanionVisit], now: Date,
                            timeZone: TimeZone, catalog: CompanionCatalog,
                            ownedKeys: Set<String>) throws -> [Award] {
        guard enabled else { return [] }
        try catalog.validate()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let cutoff = calendar.startOfDay(for: now)
        var ids = Set<UUID>(), venues = Set<Venue>()
        for visit in visits where visit.date < cutoff {
            guard ids.insert(visit.id).inserted else { continue }
            let theatre = visit.theatre.trimmingCharacters(in: .whitespacesAndNewlines)
            if !theatre.isEmpty {
                venues.insert(Venue(theatre: theatre, city: visit.city.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        return catalog.props.compactMap { p in
            guard !ownedKeys.contains(p.milestoneID) else { return nil }
            let eligible: Bool
            switch p.rule {
            case .welcome: eligible = true
            case .visits(let n): eligible = ids.count >= n
            case .venues(let n): eligible = venues.count >= n
            }
            return eligible ? Award(key: p.milestoneID, propID: p.id, ruleVersion: p.ruleVersion) : nil
        }
    }
    public static func equip(_ propID: String?, in slot: PropSlot,
                             ownedPropIDs: Set<String>, catalog: CompanionCatalog,
                             outfit: [PropSlot: String]) throws -> [PropSlot: String] {
        var result = outfit
        guard let propID else { result.removeValue(forKey: slot); return result }
        guard let prop = catalog.props.first(where: { $0.id == propID }) else { throw CompanionError.unknownProp }
        guard ownedPropIDs.contains(propID) else { throw CompanionError.unownedProp }
        guard prop.slot == slot else { throw CompanionError.slotMismatch }
        result[slot] = propID
        return result
    }
    public static func validateNickname(_ nickname: String) throws -> String {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 24 else { throw CompanionError.invalidNickname }
        return name
    }
}
