import Combine
import CoreData
import SwiftData
import SwiftUI

@main
struct StageLightApp: App {
    private static let cloudKitContainerIdentifier = "iCloud.com.chenyuan.StageLight"
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.system.rawValue
    private let modelContainer: ModelContainer?
    @State private var library: LibraryStore?
    private let startupError: String?

    init() {
        do {
            let schema = Schema(versionedSchema: StageLightSchemaV3.self)
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
            if isUITesting && ProcessInfo.processInfo.arguments.contains("-upcoming-preview") {
                UpcomingPreviewData.insert(into: container.mainContext)
                library.refresh()
            }
            if isMiniPreview {
                MiniTheatrePreviewData.insert(into: container.mainContext)
                library.refresh()
            }
            if isUITesting && ProcessInfo.processInfo.arguments.contains("-reset-data") {
                library.resetForUITesting()
            }
            #endif
            startupError = nil
            modelContainer = container
            _library = State(initialValue: library)
        } catch {
            modelContainer = nil
            _library = State(initialValue: nil)
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let library, let modelContainer {
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
                    .modelContainer(modelContainer)
            } else {
                ContentUnavailableView {
                    Label("Unable to open your library", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your stored files have not been reset. Close and reopen StageLight to retry. If this continues, contact support before reinstalling.")
                    if let startupError { Text(startupError).font(.caption).textSelection(.enabled) }
                }
            }
        }
    }
}
