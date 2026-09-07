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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
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

    private var bottomNavigation: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                navigationButton("Collection", icon: "square.grid.2x2", tab: 0)
                navigationButton("Diary", icon: "book.pages", tab: 1)
            }
            .frame(maxWidth: .infinity)

            Button {
                isAddingPerformance = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 44)
                    .background(Color(red: 1, green: 0.16, blue: 0.28), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("add-performance-button")
            .accessibilityLabel("Add a performance")

            navigationButton("Profile", icon: "person.crop.circle", tab: 2)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func navigationButton(_ title: LocalizedStringKey, icon: String, tab: Int) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}
