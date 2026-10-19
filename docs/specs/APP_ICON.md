# Optional bunny app icon

## Additional approved designs

Cream bunny and Golden premiere are also selectable, alongside Original and Theatre bunny. All four choices are localized in English, Simplified Chinese, Traditional Chinese and Japanese. Each alternate has an opaque 1024×1024 PNG and matching settings preview. Existing icon names remain stable. No stored data migration is required. The two new designs use a consistent close-up cream bunny; Golden premiere adds a burgundy bow tie and gold background.

Profile → App icon offers Original and Theatre bunny. Original remains the installation default. This is independent of Mini Theatre opt-in, rewards and language. No purchases, unlock requirement or automatic changes.

Use the public UIApplication alternate-icon API. Read the current selection from the system, including on foreground; do not duplicate it in SwiftData or iCloud. Disable simultaneous requests, keep the actual selection after a failure, allow retry and restoration via nil. Retain the system confirmation. Unsupported devices show an explanation. No diary schema or data changes.

Bundle BunnyIcon as an alternate app-icon asset for both iPhone and iPad in Debug and Release. Provide English, Simplified Chinese, Traditional Chinese and Japanese settings. Rows support VoiceOver selected state and Dynamic Type. Test switching, restoring, failure/retry, unsupported devices, duplicate requests, foreground refresh and generated bundle metadata.

## Artwork

Generated with imagegen in reference-image edit mode from design/mini-theatre/v1/bunny/bunny-base.png; mechanically resized to 1024×1024 PNG. No text or pre-rounded corners; opaque gold background. Original StageLight icon is unchanged.

Prompt: Create a production iOS alternate app icon based on the referenced original StageLight lop-eared bunny. Preserve the same cream bunny, golden ear tips, brown oval eyes, tiny pink nose and gold chest patch. Square 1024x1024 composition, fully opaque warm pale golden background extending to all edges. Enlarge the bunny's head and upper torso for excellent small-size recognition, centered, ears entirely within canvas with comfortable 10% safe margin. Clean soft flat illustration matching reference. No text, no border, no rounded canvas corners, no extra props, no mockup. Output an actual app icon image.
