# StageLight — Localization PRD

Status: requirements and release checklist; not a declaration that every check has passed.
Updated: September 7, 2026.

This document supplements [the core PRD](PRD.md) for localization of the iOS app and landing page. It defines the language experience and its acceptance criteria. It does not expand the app's content, recognition, or data-storage scope.

## Objective

Let theatre-goers use StageLight in their preferred language while preserving their original performance records and the app's private, local-first experience.

Success means users can discover a language option, switch without restarting, complete the core recording and sharing flows, and return to their existing collection without losing or modifying content.

## Supported languages and naming

| Language | Locale | Picker label | App display name |
| --- | --- | --- | --- |
| English | `en` | English | StageLight |
| Simplified Chinese | `zh-Hans` | 简体中文 | 剧光灯 |
| Traditional Chinese | `zh-Hant` | 繁體中文 | 劇光燈 |
| Japanese | `ja` | 日本語 | StageLight |

The app also offers a localized **System Default** option. Japanese app support is introduced in PR #20 and Japanese landing-page support in PR #19; those changes are not evidence of App Store release availability. Confirm the shipped build before updating marketing claims.

The home-screen name and system permission prompts follow iOS's selected app/device localization. The in-app picker controls StageLight's own interface; it must not promise to immediately rename the home-screen icon or change system-owned sheets.

## User stories

| Need | Required behavior |
| --- | --- |
| Start in a familiar language | System Default uses iOS localization selection among the supported languages, with English as the development-language fallback. |
| Choose explicitly | Profile → App Language lists all language names in their own writing system. |
| Switch immediately | Choosing a language updates app-owned text without restart, navigating away, or resetting the collection. |
| Keep my choice | An explicit choice survives relaunch and takes precedence over the device language. |
| Return to system behavior | System Default removes the explicit language override in behavior and follows system selection again. |
| Keep my original memories | Titles, venue names, notes, seats, and photos remain exactly as entered. |
| Read the website | The landing-page selector offers the same four explicit language choices independently of the app. |

## App requirements

### Selection and persistence

The existing `appLanguage` preference is the only persisted language choice. Preserve the existing values `system`, `english`, `simplifiedChinese`, and `traditionalChinese`; Japanese adds `japanese`. Missing or unrecognized values fall back to System Default without a crash.

This is a device-local preference, not an iCloud-synced setting. Changing it must not clear onboarding, filters, stored records, or photos. Switching language must not recreate the persistent store. If switching occurs while a draft exists, preserve the draft rather than silently discarding it.

### Translation coverage

Translate all app-owned text in the following flows, including accessibility labels and recovery instructions:

- onboarding, navigation, empty states, collection search and filters;
- diary, show detail, performance detail, and profile statistics;
- manual add/edit, date and seat fields, ratings, validation, duplicate warnings, and delete confirmation;
- photo selection entry points, camera guidance, and recognition fallback messages;
- memory-card controls, optional detail labels, sharing, and photo-save errors;
- language settings, iCloud status, and permission guidance;
- localized camera and photo-save usage descriptions supplied to iOS.

OS-owned pickers, share sheets, and permission buttons follow iOS localization. Do not replace native controls merely to force their language. Third-party or system errors should have a localized app-owned explanation when possible; do not expose diagnostic details as primary user copy.

Japanese initially covers 153 resource keys. The count is an implementation snapshot, not a permanent completeness target: new user-visible strings must be added to every supported language.

### Formatting and terminology

Use locale-aware formatting for displayed dates, times, and counts. Preserve the underlying date/time values and numeric ratings. Never parse a stored record using translated display text or change its value when switching language.

Preserve substitution types and argument order in translated strings, using numbered placeholders when the language requires reordering. Support singular/plural or count phrasing where appropriate. No raw placeholders, untranslated localization keys, or clipped critical actions may appear.

Use consistent Japanese terminology: 公演 for a performance, 作品 for a show, 劇場 for a theatre, 観劇記録 for performance history, and メモリーカード for a memory card. Keep product and service names such as StageLight, iCloud, Apple Maps, and App Store recognizable. Do not automatically translate show titles or artist names.

### Memory cards

App-generated labels should use the selected language wherever they are localized. User-authored text stays unchanged. Preserve the established “Made with StageLight” brand attribution unless a separate branding decision changes it. Exported images already saved or shared are not rewritten when language changes.

### Layout and accessibility

Support Japanese glyphs and natural line wrapping in existing layouts. Validate compact and large iPhones, light/dark appearances, and larger Dynamic Type sizes. Buttons, selection labels, forms, and exported cards must remain readable and usable.

VoiceOver must announce translated action labels and the selected language correctly. Do not use flags to represent languages. Do not rely on a fixed English text width for navigation or calls to action.

## Landing-page requirements

Offer English, 简体中文, 繁體中文, and 日本語. Honor a valid saved `stagelight-site-language` preference first; otherwise infer a supported language from the browser locale, including `ja-JP`, and fall back to English. Selection updates the page immediately, persists locally, and updates the document's `lang` attribute.

Translate the main landing-page headings, descriptions, navigation, calls to action, and accessible labels. Preserve working App Store, privacy, and support links. The website and app preferences remain independent; visiting a Japanese page must not change the app's stored language.

Separate privacy/support pages, screenshot pixels, App Store metadata, and social-preview metadata are not automatically translated by this work. Their localization is separate release work. Do not claim the iOS app supports a language solely because its landing page does.

GitHub Pages acceptance includes a successful static export and resolving local styles, scripts, images, and page links under `/StageLight/`.

## Data safety and backwards compatibility

Localization changes presentation and adds resources. It requires no schema migration, data rewrite, or cloud-container change.

Keep bundle identifiers, CloudKit identifiers, model/entity identifiers, record IDs, relationship IDs, photo paths, and existing preference values stable. Do not use translated strings as persistence keys, grouping identifiers, filenames, or sync identifiers.

For upgrade testing, compare an existing library before and after installation and language switching: record count, identifiers, relationships, text fields, dates, ratings, and photo bytes must be unchanged. Include mixed English/Chinese/Japanese user content and repeated visits to the same show. Verify offline access and subsequent sync without duplicated or removed records.

## Acceptance and verification

| Check | Pass condition |
| --- | --- |
| Options and storage | Every language appears; each saved value resolves correctly; missing/invalid values safely use System Default. |
| Resource lookup | Explicit Japanese selection returns Japanese strings from the packaged app, including dynamic errors. Existing language tests continue to pass. |
| Coverage and placeholders | Every reference key has a translation; strings files parse; format arguments match their source. |
| Switching and relaunch | Switch through all four languages and System Default; visible text and formatting update, with the choice retained after relaunch. |
| Core flows | Add, view, edit, rate, search, filter, and share a performance in Japanese; all critical actions remain understandable. |
| Existing data | The upgrade and switching comparison above passes; drafts and user text are preserved. |
| Device language | Test Japanese system language, an explicit override, and an unsupported system language fallback. |
| Permissions and accessibility | Check localized purpose strings on device, VoiceOver labels, Dynamic Type, and Japanese line wrapping. |
| Website | Japanese detection and manual selection work; saved choice wins; links/assets load and document language updates. |

Automate preference resolution and packaged resource lookup in `AppLanguageTests`. Use resource checks for completeness and placeholders. Use simulator/device testing for visible switching, OS prompts, layout, and data-preservation scenarios. Record the tested build, OS, locale, and result rather than treating a green build as proof of all acceptance criteria.

## Release and follow-up

Before release, have a fluent reviewer check terminology and natural phrasing, finish the acceptance matrix, and verify the shipped language list. Mention Japanese support in release notes only when the app build includes it. Publish corresponding App Store text and localized screenshots as separate reviewed assets.

Track defects by language, screen, expected text, and reproduction steps without collecting users' diary content. No new analytics or tracking is required for localization. Translation fixes should update resources without removing an existing stored language value.

Out of scope: automatic translation of user content, Japanese OCR/AI accuracy improvements, new theatre catalogs, region-specific pricing, right-to-left languages, and cloud synchronization of language preferences.
