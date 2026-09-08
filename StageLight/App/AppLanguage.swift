import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "appLanguage"

    case system
    case english
    case simplifiedChinese
    case traditionalChinese
    case japanese

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .simplifiedChinese:
            Locale(identifier: "zh-Hans")
        case .traditionalChinese:
            Locale(identifier: "zh-Hant")
        case .japanese:
            Locale(identifier: "ja")
        }
    }

    var displayName: String {
        switch self {
        case .system:
            Self.localized("System Default")
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        case .traditionalChinese:
            "繁體中文"
        case .japanese:
            "日本語"
        }
    }

    static var selected: AppLanguage {
        let storedValue = UserDefaults.standard.string(forKey: storageKey)
        return storedValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    static func localized(_ key: String.LocalizationValue) -> String {
        String(
            localized: key,
            bundle: selected.localizationBundle,
            locale: selected.locale
        )
    }

    private var localizationBundle: Bundle {
        let resourceName: String?
        switch self {
        case .english:
            resourceName = "en"
        case .simplifiedChinese:
            resourceName = "zh-Hans"
        case .traditionalChinese:
            resourceName = "zh-Hant"
        case .japanese:
            resourceName = "ja"
        case .system:
            resourceName = nil
        }

        guard let resourceName,
              let path = Bundle.main.path(forResource: resourceName, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
