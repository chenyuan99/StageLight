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
            }
            .tabItem { Label("Collection", systemImage: "square.grid.2x2") }
            .tag(0)

            NavigationStack {
                DiaryView()
            }
            .tabItem { Label("Diary", systemImage: "book.pages") }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(2)
        }
        .tint(.primary)
        .overlay(alignment: .bottom) {
            Button {
                isAddingPerformance = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.background)
                    .frame(width: 52, height: 52)
                    .background(.primary)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
            }
            .accessibilityIdentifier("add-performance-button")
            .accessibilityLabel("Add a performance")
            // Keep the action above the tab items so the Diary tab remains
            // visible and tappable.
            .padding(.bottom, 52)
        }
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
}
