# Optional bunny app icon

## Additional approved designs

Cream bunny and Golden premiere are also selectable, alongside Original and Theatre bunny. All four choices are localized in English, Simplified Chinese, Traditional Chinese and Japanese. Each alternate has an opaque 1024×1024 PNG and matching settings preview. Existing icon names remain stable. No stored data migration is required. The two new designs use a consistent close-up cream bunny; Golden premiere adds a burgundy bow tie and gold background.

Profile → App icon offers Golden premiere (default), Original, Theatre bunny and Cream bunny. Version 1.5.0 uses DefaultAppIcon containing Golden premiere artwork as the primary icon. Original artwork remains selectable under AppIcon. Existing alternate names, including GoldenPremiereIcon, stay bundled for upgrade compatibility; legacy gold selection is displayed as the default gold option without forcing a system change. Existing users using the primary icon receive the new primary artwork on upgrade; explicitly selected alternate icons remain selected. This is independent of Mini Theatre opt-in, rewards and language. No purchases or unlock requirement.

Use the public UIApplication alternate-icon API. Read the current selection from the system, including on foreground; do not duplicate it in SwiftData or iCloud. Disable simultaneous requests, keep the actual selection after a failure, allow retry and restoration via nil. Retain the system confirmation. Unsupported devices show an explanation. No diary schema or data changes.

Bundle BunnyIcon as an alternate app-icon asset for both iPhone and iPad in Debug and Release. Provide English, Simplified Chinese, Traditional Chinese and Japanese settings. Rows support VoiceOver selected state and Dynamic Type. Test switching, restoring, failure/retry, unsupported devices, duplicate requests, foreground refresh and generated bundle metadata.

## Physical-device regression

`AppIconUITests.testRealIconSwitchesPersistAcrossRelaunchAndRestore` exercises the real public UIApplication API through Profile, cycles all four icons, acknowledges the system confirmation, relaunches and verifies the selected icon read back from the system. Teardown restores the icon selected before testing. Run on an unlocked trusted iPhone/iPad using `-only-testing:StageLightUITests/AppIconUITests`. The test uses existing in-memory diary fixtures and does not erase app data. XCTest attachments include selection and Home Screen screenshots for manual visual inspection (the Home Screen may contain personal information; do not publish attachments automatically). Selection persistence is asserted; SpringBoard artwork is a manual screenshot check, not a pixel assertion. A disconnected device or terminated test runner can prevent teardown, so check the icon after interrupted runs.

Verified 2026-10-19 on the connected iPhone 18 Pro (iOS 27.0.1): the full UI scenario passed, cycling all four choices, checking persistence after each relaunch, and restoring the initial selection. Result: `/private/tmp/bunny-device-tests/Logs/Test/Test-StageLight-2026.10.19_13-18-14--0400.xcresult`. The first run exposed a test-scrolling issue (a row behind the floating tab bar was reported hittable); the helper now brings the whole row into the central viewport before tapping. No automated pixel-level Home Screen assertion is claimed.

## Artwork

Generated with imagegen in reference-image edit mode from design/mini-theatre/v1/bunny/bunny-base.png; mechanically resized to 1024×1024 PNG. No text or pre-rounded corners; opaque gold background. Original StageLight icon is unchanged.

Prompt: Create a production iOS alternate app icon based on the referenced original StageLight lop-eared bunny. Preserve the same cream bunny, golden ear tips, brown oval eyes, tiny pink nose and gold chest patch. Square 1024x1024 composition, fully opaque warm pale golden background extending to all edges. Enlarge the bunny's head and upper torso for excellent small-size recognition, centered, ears entirely within canvas with comfortable 10% safe margin. Clean soft flat illustration matching reference. No text, no border, no rounded canvas corners, no extra props, no mockup. Output an actual app icon image.
