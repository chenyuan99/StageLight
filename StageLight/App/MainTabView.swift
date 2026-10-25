import SwiftUI

struct MainTabView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.locale) private var locale
    @AppStorage(MiniTheatreStore.enabledKey) private var miniEnabled = true
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

            if miniEnabled {
                NavigationStack {
                    MiniTheatreView()
                        .toolbar { addPerformanceToolbar }
                }
                .tabItem {
                    Label { Text(MiniCopy.text("tab", locale.identifier)) } icon: { miniTheatreIcon }
                }
                .tag(3)
            }

            NavigationStack {
                ProfileView()
                    .toolbar { addPerformanceToolbar }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(2)
        }
        .onChange(of: miniEnabled) { _, enabled in
            if !enabled && selectedTab == 3 { selectedTab = 0 }
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

    private var miniTheatreIcon: some View {
        Image(uiImage: Self.bunnyIcon).renderingMode(.template)
    }

    private static let bunnyIcon: UIImage = {
        UIGraphicsImageRenderer(size: CGSize(width: 28, height: 25)).image { context in
            UIColor.black.setFill()
            // Broad head and drooping ears retain the companion's silhouette at tab size.
            let shape = UIBezierPath()
            shape.move(to: CGPoint(x: 14, y: 3))
            shape.addCurve(to: CGPoint(x: 7, y: 6), controlPoint1: CGPoint(x: 10, y: 3), controlPoint2: CGPoint(x: 9, y: 4))
            shape.addCurve(to: CGPoint(x: 1, y: 17), controlPoint1: CGPoint(x: 4, y: 8), controlPoint2: CGPoint(x: 1, y: 13))
            shape.addCurve(to: CGPoint(x: 5, y: 21), controlPoint1: CGPoint(x: 0, y: 21), controlPoint2: CGPoint(x: 3, y: 23))
            shape.addCurve(to: CGPoint(x: 8, y: 13), controlPoint1: CGPoint(x: 7, y: 19), controlPoint2: CGPoint(x: 7, y: 16))
            shape.addCurve(to: CGPoint(x: 7, y: 19), controlPoint1: CGPoint(x: 8, y: 16), controlPoint2: CGPoint(x: 7, y: 17))
            shape.addCurve(to: CGPoint(x: 21, y: 19), controlPoint1: CGPoint(x: 8, y: 25), controlPoint2: CGPoint(x: 20, y: 25))
            shape.addCurve(to: CGPoint(x: 20, y: 13), controlPoint1: CGPoint(x: 21, y: 17), controlPoint2: CGPoint(x: 20, y: 16))
            shape.addCurve(to: CGPoint(x: 23, y: 21), controlPoint1: CGPoint(x: 21, y: 16), controlPoint2: CGPoint(x: 21, y: 19))
            shape.addCurve(to: CGPoint(x: 27, y: 17), controlPoint1: CGPoint(x: 25, y: 23), controlPoint2: CGPoint(x: 28, y: 21))
            shape.addCurve(to: CGPoint(x: 21, y: 6), controlPoint1: CGPoint(x: 27, y: 13), controlPoint2: CGPoint(x: 24, y: 8))
            shape.addCurve(to: CGPoint(x: 14, y: 3), controlPoint1: CGPoint(x: 19, y: 4), controlPoint2: CGPoint(x: 18, y: 3))
            shape.close()
            shape.fill()
            context.cgContext.setBlendMode(.clear)
            context.cgContext.fillEllipse(in: CGRect(x: 10, y: 13, width: 2, height: 3))
            context.cgContext.fillEllipse(in: CGRect(x: 16, y: 13, width: 2, height: 3))
        }.withRenderingMode(.alwaysTemplate)
    }()

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
