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
            let isRunningUnitTests = ProcessInfo.processInfo.environment[
                "XCTestConfigurationFilePath"
            ] != nil
            var isMiniPreview = false
            var isUITesting = false
            #if DEBUG
            isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
            isMiniPreview = isUITesting
                && ProcessInfo.processInfo.arguments.contains("-mini-preview")
            #endif
            let configuration = if isRunningUnitTests || isUITesting {
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            } else {
                ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
                )
            }
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StageLightMigrationPlan.self,
                configurations: [configuration]
            )
            let library = LibraryStore(context: container.mainContext)
            #if DEBUG
            if isMiniPreview {
                MiniTheatrePreviewData.insert(into: container.mainContext)
                library.refresh()
            }
            #endif
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
                .modifier(MiniTheatreRuntime())
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
