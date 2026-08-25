import SwiftData
import SwiftUI

@main
struct StageLightApp: App {
    private let modelContainer: ModelContainer
    @State private var library: LibraryStore

    init() {
        do {
            let schema = Schema([
                Show.self,
                Performance.self,
                PerformancePhoto.self
            ])
            let container = try ModelContainer(for: schema)
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
        }
        .modelContainer(modelContainer)
    }
}
