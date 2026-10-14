import SwiftUI
import UIKit

struct HistoryCardCanvas: View {
    let event: TheatreHistoryEvent
    let language: String
    let template: MemoryCardTemplate
    private let ink = Color(red: 0.16, green: 0.13, blue: 0.09)
    private let gold = Color(red: 0.48, green: 0.35, blue: 0.12)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(HistoryCopy.text("history", language: language))
                    .font(.system(size: 11, weight: .bold)).tracking(1.4)
                Spacer()
                Image(systemName: "theatermasks").font(.system(size: 22))
            }
            .foregroundStyle(gold)
            Rectangle().fill(gold.opacity(0.45)).frame(height: 1)
            Text(String(event.year))
                .font(.system(size: template == .story ? 72 : 52, weight: .regular, design: .serif))
                .foregroundStyle(gold)
            Text(event.title)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .lineLimit(3).minimumScaleFactor(0.65)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 7) {
                Text(event.localized(for: language).text.heading).font(.system(size: 14, weight: .semibold))
                Text(event.dateLabel(language: language)).font(.system(size: 14))
                Text(event.venue).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
            }
            if template == .story {
                Text(event.localized(for: language).text.summary)
                    .font(.system(size: 16)).lineSpacing(4)
                    .lineLimit(9).minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 10) {
                Text(HistoryCopy.text("credit", language: language) + ": " + event.sourceName)
                    .font(.system(size: 9))
                Rectangle().fill(gold.opacity(0.45)).frame(height: 1)
                HStack(spacing: 8) {
                    Image("MemoryCardAppIcon").resizable().frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text(MemoryCardBrand.signature).font(.system(size: 11, weight: .medium))
                }
            }
        }
        .padding(26)
        .frame(width: template.canvasSize.width, height: template.canvasSize.height)
        .foregroundStyle(ink)
        .background(Color(red: 0.98, green: 0.96, blue: 0.90))
        .environment(\.colorScheme, .light)
        .environment(\.dynamicTypeSize, .medium)
    }
}

enum HistoryCardRenderer {
    @MainActor
    static func render(event: TheatreHistoryEvent, language: String, template: MemoryCardTemplate) -> UIImage? {
        let renderer = ImageRenderer(content: HistoryCardCanvas(event: event, language: language, template: template))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

struct HistoryCardComposer: View {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    let event: TheatreHistoryEvent
    @State private var template = MemoryCardTemplate.spotlight
    @State private var includesLink = true
    @State private var sharedImage: HistorySharedImage?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    GeometryReader { geometry in
                        HistoryCardCanvas(event: event, language: locale.identifier, template: template)
                            .scaleEffect(geometry.size.width / template.canvasSize.width, anchor: .topLeading)
                    }
                    .aspectRatio(template.canvasSize.width / template.canvasSize.height, contentMode: .fit)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(event.title + ", " + event.dateLabel(language: locale.identifier))
                    .accessibilityIdentifier("history-card-preview")
                    Picker(copy("card"), selection: $template) {
                        Text(copy("portrait")).tag(MemoryCardTemplate.spotlight)
                        Text(copy("story")).tag(MemoryCardTemplate.story)
                    }.pickerStyle(.segmented)
                    Toggle(copy("link"), isOn: $includesLink)
                    Button {
                        if let image = HistoryCardRenderer.render(event: event, language: locale.identifier, template: template) {
                            sharedImage = HistorySharedImage(image: image, includesLink: includesLink)
                        } else { failed = true }
                    } label: {
                        Label(copy("export"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("history-share")
                }
                .padding(20)
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
            }
            .background(StageTheme.background)
            .navigationTitle(copy("card"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(copy("done")) { dismiss() } } }
            .sheet(item: $sharedImage) { item in
                MemoryCardActivityView(image: item.image, includesAppStoreLink: item.includesLink)
            }
            .alert(copy("renderError"), isPresented: $failed) { Button(copy("done"), role: .cancel) {} }
        }
    }
    private func copy(_ key: String) -> String { HistoryCopy.text(key, language: locale.identifier) }
}

private struct HistorySharedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let includesLink: Bool
}
