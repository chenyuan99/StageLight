import Combine
import CoreData
import SwiftData
import SwiftUI

@main
struct StageLightApp: App {
    private static let cloudKitContainerIdentifier = "iCloud.com.chenyuan.StageLight"
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.system.rawValue
    private let modelContainer: ModelContainer
    @State private var library: LibraryStore

    init() {
        do {
            let schema = Schema(versionedSchema: StageLightSchemaV2.self)
            let configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StageLightMigrationPlan.self,
                configurations: [configuration]
            )
            let library = LibraryStore(context: container.mainContext)
            if ProcessInfo.processInfo.arguments.contains("-reset-data") {
                library.resetForUITesting()
            }
            modelContainer = container
            _library = State(initialValue: library)
        } catch {
            fatalError("Unable to create StageLight's local store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(
                    \.locale,
                    AppLanguage(rawValue: selectedLanguage)?.locale ?? .autoupdatingCurrent
                )
                .task {
                    await library.prepareCloudSync()
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
                        .receive(on: DispatchQueue.main)
                ) { _ in
                    library.refresh()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    library.refresh()
                }
        }
        .modelContainer(modelContainer)
    }
}
