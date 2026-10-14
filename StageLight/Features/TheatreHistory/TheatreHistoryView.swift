import SwiftUI

enum HistoryCopy {
    static let preferenceKey = "showsTheatreHistory"

    static func text(_ key: String, language: String) -> String {
        let code = HistoryLanguage.code(for: language)
        let bundle = Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(forKey: key, value: nil, table: "History")
    }
}

struct TheatreHistoryEntry: View {
    @Environment(\.locale) private var locale
    var body: some View {
        NavigationLink {
            TheatreHistoryView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "theatermasks").font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(HistoryCopy.text("title", language: locale.identifier)).font(.headline)
                    Text(HistoryCopy.text("intro", language: locale.identifier))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StageTheme.spotlight.opacity(0.25), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("theatre-history-entry")
    }
}

struct TheatreHistorySettings: View {
    @Environment(\.locale) private var locale
    @AppStorage(HistoryCopy.preferenceKey) private var showsHistory = true
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(HistoryCopy.text("show", language: locale.identifier), isOn: $showsHistory)
                .accessibilityIdentifier("theatre-history-toggle")
            Text(HistoryCopy.text("optional", language: locale.identifier))
                .font(.caption).foregroundStyle(.secondary)
            TheatreHistoryEntry()
        }
    }
}

struct TheatreHistoryView: View {
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var catalog: TheatreHistoryCatalog?
    @State private var failed = false
    @State private var now = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let catalog {
                    TimelineView(.periodic(from: now, by: 60)) { context in
                        today(catalog: catalog, date: max(now, context.date))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy("browse")).font(.title2.bold())
                        Text(copy("starter")).font(.subheadline).foregroundStyle(.secondary)
                    }
                    ForEach(catalog.chronologicalEvents) { event in
                        NavigationLink {
                            TheatreHistoryDetail(event: event)
                        } label: {
                            HistoryEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("history-event-\(event.id)")
                    }
                } else if failed {
                    ContentUnavailableView {
                        Label(copy("error"), systemImage: "books.vertical")
                    } actions: { Button(copy("retry"), action: load) }
                } else { ProgressView() }
            }
            .padding(20)
            .readableStageContent()
        }
        .background(StageTheme.background)
        .navigationTitle(copy("title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load(); now = Date() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { now = Date() } }
    }

    private func copy(_ key: String) -> String { HistoryCopy.text(key, language: locale.identifier) }

    private func load() {
        do { catalog = try TheatreHistoryCatalog.bundled(); failed = false }
        catch { catalog = nil; failed = true }
    }

    private func today(catalog: TheatreHistoryCatalog, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(copy("today")).font(.caption.bold()).textCase(.uppercase)
            Text(date.formatted(Date.FormatStyle(date: .long, time: .omitted,
                locale: locale, calendar: Calendar(identifier: .gregorian)).month(.wide).day()))
                .font(.system(.largeTitle, design: .serif, weight: .medium))
            let events = catalog.events(on: date)
            if events.isEmpty {
                Text(copy("empty")).foregroundStyle(.secondary)
                    .accessibilityIdentifier("history-empty-today")
            } else {
                ForEach(events) { event in
                    NavigationLink { TheatreHistoryDetail(event: event) } label: { HistoryEventRow(event: event) }
                        .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(StageTheme.spotlight.opacity(0.25), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct HistoryEventRow: View {
    @Environment(\.locale) private var locale
    let event: TheatreHistoryEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.dateLabel(language: locale.identifier)).font(.caption).foregroundStyle(.secondary)
            Text(event.title).font(.system(.title2, design: .serif, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(event.localized(for: locale.identifier).text.heading).font(.subheadline)
            Text(event.venue).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct TheatreHistoryDetail: View {
    @Environment(\.locale) private var locale
    let event: TheatreHistoryEvent
    @State private var showsComposer = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "theatermasks").font(.system(size: 52)).accessibilityHidden(true)
                Text(event.dateLabel(language: locale.identifier)).font(.headline).foregroundStyle(.secondary)
                Text(event.title).font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                let content = event.localized(for: locale.identifier)
                Text(content.text.heading).font(.title3.bold())
                Text(event.venue).foregroundStyle(.secondary)
                Text(content.text.summary).font(.body).fixedSize(horizontal: false, vertical: true)
                if content.isFallback { Text(copy("fallback")).font(.caption).foregroundStyle(.secondary) }
                Divider()
                Link(destination: event.sourceURL) {
                    Label(copy("source") + " · " + event.sourceName, systemImage: "arrow.up.right.square")
                }.accessibilityIdentifier("history-source")
                Button { showsComposer = true } label: {
                    Label(copy("share"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("history-create-card")
            }
            .padding(24)
            .readableStageContent()
        }
        .background(StageTheme.background)
        .navigationTitle(copy("title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsComposer) { HistoryCardComposer(event: event) }
    }
    private func copy(_ key: String) -> String { HistoryCopy.text(key, language: locale.identifier) }
}
