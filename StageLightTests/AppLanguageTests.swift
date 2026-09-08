import XCTest
@testable import StageLight

final class AppLanguageTests: XCTestCase {
    private var previousSelection: Any?

    override func setUp() {
        super.setUp()
        previousSelection = UserDefaults.standard.object(forKey: AppLanguage.storageKey)
    }

    override func tearDown() {
        if let previousSelection {
            UserDefaults.standard.set(previousSelection, forKey: AppLanguage.storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
        }
        super.tearDown()
    }

    func testAllLanguageOptionsAreAvailable() {
        XCTAssertEqual(
            AppLanguage.allCases,
            [.system, .english, .simplifiedChinese, .traditionalChinese, .japanese]
        )
    }

    func testStoredSelectionResolvesToChosenLanguage() {
        UserDefaults.standard.set(
            AppLanguage.simplifiedChinese.rawValue,
            forKey: AppLanguage.storageKey
        )

        XCTAssertEqual(AppLanguage.selected, .simplifiedChinese)
        XCTAssertEqual(AppLanguage.selected.locale.identifier, "zh-Hans")
    }

    func testInvalidStoredSelectionFallsBackToSystem() {
        UserDefaults.standard.set("unsupported", forKey: AppLanguage.storageKey)

        XCTAssertEqual(AppLanguage.selected, .system)
    }

    func testJapaneseSelectionLoadsJapaneseResources() {
        UserDefaults.standard.set(AppLanguage.japanese.rawValue, forKey: AppLanguage.storageKey)
        XCTAssertEqual(AppLanguage.selected, .japanese)
        XCTAssertEqual(AppLanguage.selected.locale.identifier, "ja")
        XCTAssertEqual(AppLanguage.selected.displayName, "日本語")
        XCTAssertEqual(AppLanguage.localized("Collection"), "コレクション")
        XCTAssertEqual(AppLanguage.localized("Share Memory"), "思い出をシェア")
        XCTAssertEqual(AppLanguage.localized("System Default"), "システム設定に従う")
    }

    func testSimplifiedChineseLocalization() {
        UserDefaults.standard.set(
            AppLanguage.simplifiedChinese.rawValue,
            forKey: AppLanguage.storageKey
        )

        XCTAssertEqual(AppLanguage.localized("Collection"), "收藏")
        XCTAssertEqual(AppLanguage.localized("Share Memory"), "分享回忆")
    }

    func testTraditionalChineseLocalization() {
        UserDefaults.standard.set(
            AppLanguage.traditionalChinese.rawValue,
            forKey: AppLanguage.storageKey
        )

        XCTAssertEqual(AppLanguage.localized("Performances"), "演出紀錄")
        XCTAssertEqual(AppLanguage.localized("Share Memory"), "分享回憶")
    }

    func testEnglishSelectionUsesEnglishResources() {
        UserDefaults.standard.set(
            AppLanguage.english.rawValue,
            forKey: AppLanguage.storageKey
        )

        XCTAssertEqual(AppLanguage.localized("On"), "On")
        XCTAssertEqual(AppLanguage.localized("Untitled Show"), "Untitled Show")
    }
}
