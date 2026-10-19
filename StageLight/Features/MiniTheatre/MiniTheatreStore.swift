import Foundation
import Observation
import SwiftData
import MiniTheatreCore
import UIKit

enum CompanionSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Grant.self, Stage.self] }
    @Model final class Grant {
        @Attribute(.unique) var key: String
        var propID: String
        var ruleVersion: Int
        var grantedAt: Date
        var revealedAt: Date?
        init(_ award: Award, at date: Date) {
            key = award.key; propID = award.propID; ruleVersion = award.ruleVersion; grantedAt = date
        }
    }
    @Model final class Stage {
        @Attribute(.unique) var id: String = "main"
        var nickname: String = ""
        var background: String?
        var handheld: String?
        var decoration: String?
        init() {}
        var outfit: [PropSlot: String] {
            get {
                var value: [PropSlot: String] = [:]
                value[.background] = background; value[.handheld] = handheld; value[.decoration] = decoration
                return value
            }
            set { background = newValue[.background]; handheld = newValue[.handheld]; decoration = newValue[.decoration] }
        }
    }
}

@MainActor @Observable final class MiniTheatreStore {
    static let enabledKey = "miniTheatre.enabled"
    static let shortcutKey = "miniTheatre.shortcut"
    private var container: ModelContainer?
    private let inMemory: Bool
    private let storeURL: URL?
    // Fault injection is used only by tests, before commit.
    var beforeSave: (() throws -> Void)?
    private(set) var catalog: CompanionCatalog?
    private(set) var owned = Set<String>()
    private(set) var pending: [String] = []
    private(set) var outfit: [PropSlot: String] = [:]
    private(set) var nickname = ""
    var failed = false
    init(inMemory: Bool = false, storeURL: URL? = nil) { self.inMemory = inMemory; self.storeURL = storeURL }

    static func loadCatalog() throws -> CompanionCatalog {
        struct Document: Decodable { let schemaVersion: Int; let props: [PropDefinition] }
        guard let url = Bundle.main.url(forResource: "MiniTheatreCatalog", withExtension: "json") else {
            throw CompanionError.invalidCatalog
        }
        let document = try JSONDecoder().decode(Document.self, from: Data(contentsOf: url))
        guard document.props.allSatisfy({ MiniCopy.values[$0.id]?.count == 4 && MiniCopy.values[$0.milestoneID]?.count == 4 }) else {
            throw CompanionError.invalidCatalog
        }
        let assets = Set(document.props.filter { UIImage(named: $0.assetName) != nil }.map(\.assetName))
        let catalog = CompanionCatalog(schemaVersion: document.schemaVersion, props: document.props, availableAssets: assets)
        try catalog.validate()
        return catalog
    }
    private func open() throws -> ModelContext {
        if let container { return container.mainContext }
        let schema = Schema(versionedSchema: CompanionSchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration("MiniTheatre", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            let url: URL
            if let storeURL { url = storeURL } else {
                let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                            appropriateFor: nil, create: true).appendingPathComponent("MiniTheatre", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                url = directory.appendingPathComponent("companion.store")
            }
            configuration = ModelConfiguration("MiniTheatre", schema: schema, url: url, cloudKitDatabase: .none)
        }
        let newContainer = try ModelContainer(for: schema, configurations: [configuration])
        newContainer.mainContext.autosaveEnabled = false
        container = newContainer
        return newContainer.mainContext
    }
    // Synchronous MainActor transactions cannot interleave across awaits.
    private func transaction(_ change: (ModelContext, CompanionSchemaV1.Stage, [CompanionSchemaV1.Grant]) throws -> Void) throws {
        let context = try open()
        do {
            let stages = try context.fetch(FetchDescriptor<CompanionSchemaV1.Stage>())
            guard stages.count <= 1, stages.first?.id == nil || stages.first?.id == "main" else { throw CompanionError.invalidCatalog }
            let stage = stages.first ?? CompanionSchemaV1.Stage()
            if stages.isEmpty { context.insert(stage) }
            let grants = try context.fetch(FetchDescriptor<CompanionSchemaV1.Grant>())
            try change(context, stage, grants)
            if context.hasChanges { try beforeSave?(); try context.save() }
            let committed = try context.fetch(FetchDescriptor<CompanionSchemaV1.Grant>())
            owned = Set(committed.map(\.propID)); pending = committed.filter { $0.revealedAt == nil }.map(\.propID).sorted()
            outfit = stage.outfit; nickname = stage.nickname; failed = false
        } catch { context.rollback(); failed = true; throw error }
    }
    func reconcile(enabled: Bool, visits: [CompanionVisit], now: Date = .now, timeZone: TimeZone = .current) {
        guard enabled else { return }
        do {
            let loaded = try Self.loadCatalog()
            try transaction { context, _, grants in
                let awards = try CompanionRules.plan(enabled: true, visits: visits, now: now, timeZone: timeZone,
                                                     catalog: loaded, ownedKeys: Set(grants.map(\.key)))
                for award in awards { context.insert(CompanionSchemaV1.Grant(award, at: now)) }
            }
            catalog = loaded
        } catch { failed = true }
    }
    func acknowledge() {
        do { try transaction { _, _, grants in
            for grant in grants where grant.revealedAt == nil { grant.revealedAt = .now }
        } } catch { failed = true }
    }
    func equip(_ prop: String?, slot: PropSlot) {
        do {
            guard let catalog else { throw CompanionError.invalidCatalog }
            try transaction { _, stage, grants in
                stage.outfit = try CompanionRules.equip(prop, in: slot, ownedPropIDs: Set(grants.map(\.propID)),
                                                       catalog: catalog, outfit: stage.outfit)
            }
        } catch { failed = true }
    }
    func rename(_ value: String) {
        do { let valid = try CompanionRules.validateNickname(value)
            try transaction { _, stage, _ in stage.nickname = valid }
        } catch { failed = true }
    }
    var visibleOutfit: [PropSlot: String] {
        outfit.filter { slot, id in owned.contains(id) && catalog?.props.contains(where: { $0.id == id && $0.slot == slot }) == true }
    }
}
