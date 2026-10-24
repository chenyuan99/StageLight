import SwiftUI

struct MainTabView: View {
    @Environment(LibraryStore.self) private var library
    @State private var selectedTab = 0
    @State private var isAddingPerformance = false

    var body: some View {
        @Bindable var library = library

        TabView(selection: $selectedTab) {
            NavigationStack {
                CollectionView {
                    isAddingPerformance = true
                }
                .toolbar { addPerformanceToolbar }
            }
            .tabItem { Label("Collection", systemImage: "square.grid.2x2") }
            .tag(0)

            NavigationStack {
                DiaryView()
                    .toolbar { addPerformanceToolbar }
            }
            .tabItem { Label("Diary", systemImage: "book.pages") }
            .tag(1)

            NavigationStack {
                ProfileView()
                    .toolbar { addPerformanceToolbar }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(2)
        }
        .tint(.primary)
        .sheet(isPresented: $isAddingPerformance) {
            AddPerformanceFlow()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { library.errorMessage != nil },
                set: { if !$0 { library.errorMessage = nil } }
            )
        ) {
            Button("OK") { library.errorMessage = nil }
        } message: {
            Text(library.errorMessage ?? "")
        }
    }

    // Keep the sheet and tab selection above the individual navigation stacks so
    // system bar repositioning never replaces an in-progress editor.
    @ToolbarContentBuilder
    private var addPerformanceToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isAddingPerformance = true
            } label: {
                Label("Add a performance", systemImage: "plus")
            }
            .accessibilityIdentifier("add-performance-button")
        }
    }
}
