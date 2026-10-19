import SwiftUI
import UIKit

@MainActor protocol AppIconService {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }
    func changeIcon(to name: String?) async throws
}

@MainActor struct SystemAppIconService: AppIconService {
    var supportsAlternateIcons: Bool { UIApplication.shared.supportsAlternateIcons }
    var alternateIconName: String? { UIApplication.shared.alternateIconName }
    func changeIcon(to name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

enum AppIconChoice: String, CaseIterable {
    case original, bunny, creamBunny, goldenPremiere
    var iconName: String? {
        switch self {
        case .original: nil
        case .bunny: "BunnyIcon"
        case .creamBunny: "CreamBunnyIcon"
        case .goldenPremiere: "GoldenPremiereIcon"
        }
    }
    var preview: String { iconName.map { $0 + "Preview" } ?? "MemoryCardAppIcon" }
}

@MainActor @Observable final class AppIconStore {
    private let service: any AppIconService
    private(set) var selectedName: String?
    private(set) var supported = false
    private(set) var isChanging = false
    var failed = false

    init(service: any AppIconService = SystemAppIconService()) {
        self.service = service
        refresh()
    }

    func refresh() {
        selectedName = service.alternateIconName
        supported = service.supportsAlternateIcons
    }

    func select(_ choice: AppIconChoice) async {
        guard !isChanging else { return }
        refresh()
        guard supported, selectedName != choice.iconName else { return }
        isChanging = true
        failed = false
        defer { refresh(); isChanging = false }
        do { try await service.changeIcon(to: choice.iconName) }
        catch { failed = true }
    }
}

struct AppIconSettings: View {
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = AppIconStore()

    private func copy(_ key: String) -> String { AppIconCopy.text(key, locale.identifier) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(copy("title")).font(.headline)
            Text(copy("detail")).font(.caption).foregroundStyle(.secondary)
            ForEach(AppIconChoice.allCases, id: \.self) { choice in
                Button {
                    Task { await store.select(choice) }
                } label: {
                    HStack(spacing: 14) {
                        Image(choice.preview).resizable().scaledToFit()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityHidden(true)
                        Text(copy(choice.rawValue)).foregroundStyle(.primary)
                        Spacer()
                        if store.selectedName == choice.iconName {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.primary)
                        }
                    }
                    .padding(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!store.supported || store.isChanging)
                .accessibilityIdentifier("app-icon-\(choice.rawValue)")
                .accessibilityAddTraits(store.selectedName == choice.iconName ? .isSelected : [])
            }
            if store.isChanging { ProgressView().accessibilityLabel(copy("changing")) }
            if !store.supported {
                Text(copy("unsupported")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .onAppear { store.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { store.refresh() } }
        .alert(copy("error"), isPresented: $store.failed) {
            Button(copy("ok"), role: .cancel) {}
        } message: { Text(copy("retry")) }
    }
}

enum AppIconCopy {
    static func text(_ key: String, _ language: String) -> String {
        let index = language.hasPrefix("ja") ? 3 : language.hasPrefix("zh") ?
            (language.contains("Hant") || language.contains("TW") || language.contains("HK") ? 2 : 1) : 0
        return values[key]?[index] ?? key
    }
    static let values: [String: [String]] = [
        "title": ["App icon", "应用图标", "應用程式圖示", "アプリアイコン"],
        "detail": ["Choose a Home Screen icon for this device. Your diary and Mini Theatre are unchanged.", "选择此设备的主屏幕图标，不影响日记或小剧场。", "選擇此裝置的主畫面圖示，不影響日記或小劇場。", "この端末のホーム画面アイコンを選べます。日記や小さな劇場には影響しません。"],
        "original": ["Original", "原版", "原版", "オリジナル"],
        "bunny": ["Theatre bunny", "剧场小兔", "劇場小兔", "劇場のうさぎ"],
        "creamBunny": ["Cream bunny", "奶油小兔", "奶油小兔", "クリームうさぎ"],
        "goldenPremiere": ["Golden premiere", "金色首演", "金色首演", "黄金の初日"],
        "changing": ["Changing icon", "正在更换图标", "正在更換圖示", "アイコンを変更中"],
        "unsupported": ["Icon changes are unavailable on this device.", "此设备暂不支持更换图标。", "此裝置暫不支援更換圖示。", "この端末ではアイコンを変更できません。"],
        "error": ["Could not change icon", "无法更换图标", "無法更換圖示", "アイコンを変更できませんでした"],
        "retry": ["Please try again. Your saved records are unaffected.", "请重试，已保存的记录不受影响。", "請重試，已儲存的記錄不受影響。", "再試行してください。保存済みの記録には影響しません。"],
        "ok": ["OK", "好", "好", "OK"]
    ]
}
