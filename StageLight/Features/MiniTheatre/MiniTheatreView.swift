import Combine
import MiniTheatreCore
import SwiftUI

enum MiniPalette {
    static var accent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.92, green: 0.77, blue: 0.42, alpha: 1)
                : UIColor(red: 0.44, green: 0.31, blue: 0.10, alpha: 1)
        })
    }
}

struct MiniTheatreRuntime: ViewModifier {
    @Environment(LibraryStore.self) private var library
    @Environment(\.scenePhase) private var phase
    @Environment(\.locale) private var locale
    @AppStorage(MiniTheatreStore.enabledKey) private var enabled = true
    @State private var store = MiniTheatreStore(inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing"))
    private var visits: [CompanionVisit] {
        enabled ? library.performances.map { CompanionVisit(id: $0.id, date: $0.date, theatre: $0.theatre, city: $0.city) } : []
    }
    func body(content: Content) -> some View {
        content.environment(store)
            .onAppear { reconcile() }
            .onChange(of: visits) { _, _ in reconcile() }
            .onChange(of: enabled) { _, _ in reconcile() }
            .onChange(of: phase) { _, value in if value == .active { reconcile() } }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                if phase == .active { reconcile() }
            }
    }
    private func reconcile() { store.reconcile(enabled: enabled, visits: visits) }
}

// This notice belongs inside scroll/navigation content, so it cannot cover
// native horizontal or vertical navigation bars.
struct MiniTheatreRewardNotice: View {
    @Environment(MiniTheatreStore.self) private var store
    @Environment(\.locale) private var locale
    @AppStorage(MiniTheatreStore.enabledKey) private var enabled = true
    @State private var presents = false

    var body: some View {
        VStack(spacing: 0) {
            if enabled && !store.pending.isEmpty {
                Button { presents = true } label: {
                    Label(MiniCopy.text("new", locale.identifier), systemImage: "gift")
                        .padding(12).background(.regularMaterial, in: Capsule())
                }
                .tint(MiniPalette.accent)
                .padding(.vertical, 8)
                .accessibilityIdentifier("mini-award-notice")
            }
        }
        // Keep the presenter alive after acknowledging the pending rewards.
        .sheet(isPresented: $presents) {
            NavigationStack {
                MiniTheatreView().toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MiniCopy.text("done", locale.identifier)) { presents = false }
                    }
                }
            }.environment(store)
        }
    }
}

struct MiniTheatreEntry: View {
    @Environment(\.locale) private var locale
    var body: some View {
        NavigationLink { MiniTheatreView() } label: {
            Label(MiniCopy.text("title", locale.identifier), systemImage: "theatermasks")
                .font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(16)
                .background(StageTheme.spotlight.opacity(0.25), in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain).accessibilityIdentifier("mini-entry")
    }
}
struct MiniTheatreSettings: View {
    @Environment(\.locale) private var locale
    @AppStorage(MiniTheatreStore.enabledKey) private var enabled = true
    @AppStorage(MiniTheatreStore.shortcutKey) private var shortcut = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(MiniCopy.text("title", locale.identifier)).font(.headline)
            Text(MiniCopy.text("privacy", locale.identifier)).font(.caption).foregroundStyle(.secondary)
            Toggle(MiniCopy.text("enable", locale.identifier), isOn: $enabled).accessibilityIdentifier("mini-enable")
            if enabled {
                Toggle(MiniCopy.text("shortcut", locale.identifier), isOn: $shortcut)
            }
        }.tint(MiniPalette.accent)
    }
}

struct MiniStage: View {
    let outfit: [PropSlot: String]
    var pose = "base"
    var body: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.98, green: 0.94, blue: 0.83))
                if let id = outfit[.background] { sprite(id).frame(width: g.size.width, height: g.size.height) }
                Image("mini_bunny_\(pose)").resizable().scaledToFit()
                    .frame(width: g.size.width * 0.64, height: g.size.height * 0.85)
                    .offset(y: g.size.height * 0.08)
                if let id = outfit[.decoration] {
                    sprite(id).frame(width: g.size.width * 0.27).offset(x: g.size.width * 0.29, y: g.size.height * 0.27)
                }
                if let id = outfit[.handheld] {
                    sprite(id).frame(width: g.size.width * 0.26)
                        .scaleEffect(x: id == "welcome_pennant" ? -1 : 1, y: 1)
                        .offset(x: -g.size.width * 0.16, y: g.size.height * 0.13)
                }
            }.clipShape(RoundedRectangle(cornerRadius: 24))
        }.aspectRatio(1.2, contentMode: .fit).accessibilityHidden(true)
    }
    private func sprite(_ id: String) -> some View { Image("mini_\(id)").resizable().scaledToFit() }
}

struct MiniTheatreView: View {
    @Environment(MiniTheatreStore.self) private var store
    @Environment(LibraryStore.self) private var library
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(MiniTheatreStore.enabledKey) private var enabled = true
    @AppStorage("miniTheatre.haptics") private var haptics = false
    @State private var nickname = ""
    @State private var sharing = false
    @State private var editing: Performance?
    @State private var feedback = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if enabled {
                    Text(copy("intro")).font(.system(.title2, design: .serif))
                    MiniStage(outfit: store.visibleOutfit, pose: store.pending.isEmpty || reduceMotion ? "base" : "celebrate")
                    Text(store.nickname.isEmpty ? copy("name") : store.nickname).font(.headline)
                    if store.failed {
                        Text(copy("error")).foregroundStyle(.red)
                        Button(copy("retry")) { refresh() }
                    }
                    if !store.pending.isEmpty {
                        VStack(alignment: .leading) {
                            Text(copy("new")).font(.headline)
                            Text(store.pending.map { copy($0) }.joined(separator: " · "))
                            Button(copy("done")) { store.acknowledge(); if haptics { feedback += 1 } }
                                .accessibilityIdentifier("mini-acknowledge")
                        }.padding().background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    Text(copy("props")).font(.title2)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(store.catalog?.props ?? [], id: \.id) { prop in
                            propCell(prop)
                        }
                    }
                    // Unknown/retired selections remain stored but can always be removed.
                    ForEach(PropSlot.allCases, id: \.self) { slot in
                        if let id = store.outfit[slot], store.catalog?.props.contains(where: { $0.id == id }) != true {
                            Button(copy("unequip")) { store.equip(nil, slot: slot) }
                        }
                    }
                    Button { sharing = true } label: { Label(copy("share"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("mini-share")
                    TextField(copy("nickname"), text: $nickname).textFieldStyle(.roundedBorder)
                    Button(copy("save")) { store.rename(nickname) }
                    Toggle(copy("haptics"), isOn: $haptics)
                    if let latest = library.performances.first(where: { $0.date <= .now }) {
                        Text(copy("reflect")).font(.headline)
                        Button(copy("note")) { editing = latest }
                    }
                    Text(copy("policy")).font(.footnote).foregroundStyle(.secondary)
                } else { MiniTheatreSettings() }
            }.padding(24).readableStageContent()
        }
        .accessibilityIdentifier("mini-scroll")
        .background(StageTheme.background).tint(MiniPalette.accent)
        .navigationTitle(copy("title")).navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh(); nickname = store.nickname.isEmpty ? copy("name") : store.nickname }
        .sensoryFeedback(.success, trigger: feedback)
        .sheet(isPresented: $sharing) { MiniTheatreCardComposer(outfit: store.visibleOutfit) }
        .sheet(item: $editing) { AddPerformanceFlow(editing: $0) }
    }
    private func propCell(_ prop: PropDefinition) -> some View {
        let owned = store.owned.contains(prop.id)
        let equipped = store.outfit[prop.slot] == prop.id
        return VStack(spacing: 8) {
            Image(prop.assetName).resizable().scaledToFit().frame(height: 90).opacity(owned ? 1 : 0.35).accessibilityHidden(true)
            Text(copy(prop.id)).font(.headline)
            Text(copy(prop.milestoneID)).font(.caption).foregroundStyle(.secondary)
            if owned {
                Button(copy(equipped ? "unequip" : "equip")) { store.equip(equipped ? nil : prop.id, slot: prop.slot) }
                    .buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("mini-equip-\(prop.id)")
            } else { Label(copy("locked"), systemImage: "lock").font(.caption).frame(minHeight: 44) }
        }.frame(maxWidth: .infinity).padding(12).background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
    private func refresh() {
        store.reconcile(enabled: enabled, visits: library.performances.map {
            CompanionVisit(id: $0.id, date: $0.date, theatre: $0.theatre, city: $0.city)
        })
    }
    private func copy(_ key: String) -> String { MiniCopy.text(key, locale.identifier) }
}
