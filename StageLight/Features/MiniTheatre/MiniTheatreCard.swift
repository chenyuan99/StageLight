import MiniTheatreCore
import SwiftUI
import UIKit

// Deliberately accepts only outfit IDs, not a model, nickname or diary snapshot.
struct MiniTheatreCard: View {
    let outfit: [PropSlot: String]
    let language: String
    var body: some View {
        VStack(spacing: 18) {
            Text(MiniCopy.text("title", language)).font(.system(size: 25, weight: .medium, design: .serif))
            Text(MiniCopy.text("intro", language)).font(.system(size: 13))
            MiniStage(outfit: outfit).frame(width: 304, height: 254)
            Spacer(minLength: 0)
            HStack {
                Image("MemoryCardAppIcon").resizable().frame(width: 24, height: 24).clipShape(RoundedRectangle(cornerRadius: 5))
                Text("Made with StageLight").font(.system(size: 12, weight: .medium))
            }
        }.padding(28).frame(width: 360, height: 450)
            .foregroundStyle(Color(red: 0.22, green: 0.15, blue: 0.10))
            .background(Color(red: 0.99, green: 0.97, blue: 0.92))
            .environment(\.colorScheme, .light).environment(\.dynamicTypeSize, .medium)
    }
}
enum MiniCardRenderer {
    @MainActor static func render(outfit: [PropSlot: String], language: String) -> UIImage? {
        let renderer = ImageRenderer(content: MiniTheatreCard(outfit: outfit, language: language))
        renderer.scale = 3; renderer.isOpaque = true
        return renderer.uiImage
    }
}
struct MiniTheatreCardComposer: View {
    let outfit: [PropSlot: String]
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @State private var link = false
    @State private var shared: Export?
    @State private var failed = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GeometryReader { g in
                        MiniTheatreCard(outfit: outfit, language: locale.identifier)
                            .scaleEffect(g.size.width / 360, anchor: .topLeading)
                    }.aspectRatio(0.8, contentMode: .fit)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(copy("share")).accessibilityIdentifier("mini-card-preview")
                    Text(copy("sharePrivacy")).font(.caption)
                    Toggle(copy("link"), isOn: $link)
                    Button(copy("export")) {
                        if let image = MiniCardRenderer.render(outfit: outfit, language: locale.identifier) {
                            shared = Export(image: image, link: link)
                        } else { failed = true }
                    }.buttonStyle(.borderedProminent)
                }.padding(20).frame(maxWidth: 340).frame(maxWidth: .infinity)
            }.tint(MiniPalette.accent).navigationTitle(copy("share")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("done")) { dismiss() } } }
                .sheet(item: $shared) { MemoryCardActivityView(image: $0.image, includesAppStoreLink: $0.link) }
                .alert(copy("error"), isPresented: $failed) { Button(copy("done"), role: .cancel) {} }
        }
    }
    private func copy(_ key: String) -> String { MiniCopy.text(key, locale.identifier) }
    private struct Export: Identifiable { let id = UUID(); let image: UIImage; let link: Bool }
}
