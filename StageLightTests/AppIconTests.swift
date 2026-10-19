import XCTest
import UIKit
@testable import StageLight

@MainActor final class AppIconTests: XCTestCase {
    final class Service: AppIconService {
        var supportsAlternateIcons = true
        var alternateIconName: String?
        var requests: [String?] = []
        var fail = false
        var pending: CheckedContinuation<Void, Never>?
        var suspend = false
        func changeIcon(to name: String?) async throws {
            requests.append(name)
            if suspend { await withCheckedContinuation { pending = $0 } }
            if fail { throw NSError(domain: "test", code: 1) }
            alternateIconName = name
        }
    }
    func testSwitchAndRestore() async {
        let service = Service()
        let subject = AppIconStore(service: service)
        await subject.select(.bunny)
        XCTAssertEqual(subject.selectedName, "BunnyIcon")
        await subject.select(.original)
        XCTAssertEqual(subject.selectedName, "AppIcon")
        XCTAssertEqual(service.requests.count, 2)
        XCTAssertFalse(subject.failed)
    }
    func testEveryChoiceCanBeSelectedAndRestored() async {
        let service = Service()
        let store = AppIconStore(service: service)
        for choice in AppIconChoice.allCases {
            await store.select(choice)
            XCTAssertEqual(store.selectedName, choice.iconName)
            XCTAssertNotNil(UIImage(named: choice.preview))
            for language in ["en", "zh-Hans", "zh-Hant", "ja"] {
                XCTAssertNotEqual(AppIconCopy.text(choice.rawValue, language), choice.rawValue)
            }
        }
        await store.select(.goldenPremiere)
        XCTAssertNil(store.selectedName)
    }
    func testFailureKeepsActualIconAndAllowsRetry() async {
        let service = Service()
        service.fail = true
        let store = AppIconStore(service: service)
        await store.select(.bunny)
        XCTAssertNil(store.selectedName)
        XCTAssertTrue(store.failed)
        XCTAssertFalse(store.isChanging)
        service.fail = false
        await store.select(.bunny)
        XCTAssertEqual(store.selectedName, "BunnyIcon")
        XCTAssertFalse(store.failed)
    }
    func testUnsupportedAndSameSelectionDoNotCallSystem() async {
        let service = Service(), other = Service()
        service.supportsAlternateIcons = false
        await AppIconStore(service: service).select(.bunny)
        await AppIconStore(service: other).select(.goldenPremiere)
        XCTAssertTrue(service.requests.isEmpty)
        XCTAssertTrue(other.requests.isEmpty)
    }
    func testRefreshReadsSystemRatherThanStoredPreference() {
        let service = Service()
        let store = AppIconStore(service: service)
        service.alternateIconName = "BunnyIcon"
        store.refresh()
        XCTAssertEqual(store.selectedName, "BunnyIcon")
    }
    func testGoldIsDefaultAndLegacyGoldRemainsSelected() async {
        let service = Service()
        let store = AppIconStore(service: service)
        XCTAssertNil(AppIconChoice.goldenPremiere.iconName)
        XCTAssertEqual(AppIconChoice.original.iconName, "AppIcon")
        XCTAssertNil(store.selectedName)
        service.alternateIconName = "GoldenPremiereIcon"
        store.refresh()
        XCTAssertNil(store.selectedName)
        await store.select(.goldenPremiere)
        XCTAssertTrue(service.requests.isEmpty)
    }
    func testConcurrentChangesAreIgnored() async {
        let service = Service()
        service.suspend = true
        let store = AppIconStore(service: service)
        let first = Task { await store.select(.bunny) }
        while service.pending == nil { await Task.yield() }
        XCTAssertTrue(store.isChanging)
        await store.select(.original)
        XCTAssertEqual(service.requests.count, 1)
        service.pending?.resume()
        await first.value
        XCTAssertFalse(store.isChanging)
    }
    func testBundledIconsForPhoneAndPadAndLocalizedCopy() throws {
        // Read the raw plist: Bundle.infoDictionary resolves device-qualified keys.
        let data = try Data(contentsOf: Bundle.main.bundleURL.appendingPathComponent("Info.plist"))
        let metadata = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"] {
            let icons = try XCTUnwrap(metadata[key] as? [String: Any])
            let alternates = try XCTUnwrap(icons["CFBundleAlternateIcons"] as? [String: Any])
            for choice in AppIconChoice.allCases {
                if let name = choice.iconName { XCTAssertNotNil(alternates[name]) }
            }
            XCTAssertNotNil(icons["CFBundlePrimaryIcon"])
            let primary = try XCTUnwrap(icons["CFBundlePrimaryIcon"] as? [String: Any])
            XCTAssertEqual(primary["CFBundleIconName"] as? String, "DefaultAppIcon")
            XCTAssertNotNil(alternates["GoldenPremiereIcon"], "Keep legacy installed icon name")
        }
        XCTAssertNotNil(UIImage(named: "BunnyIconPreview"))
        XCTAssertNotNil(UIImage(named: "MemoryCardAppIcon"))
        for values in AppIconCopy.values.values {
            XCTAssertEqual(values.count, 4)
            XCTAssertFalse(values.contains(""))
        }
        XCTAssertEqual(AppIconCopy.text("bunny", "zh-Hant"), "劇場小兔")
        XCTAssertEqual(AppIconCopy.text("bunny", "ja"), "劇場のうさぎ")
    }
}
