# Mini Theatre Companion Specification

Status: implemented on the feature branch, not released. Earlier device/UI runs passed; the isolated PR snapshot has one unresolved English UI timeout. See MINI_THEATRE_QA.md for current evidence and merge/release gates. Updated October 18, 2026.

Product requirements: [PRD](../PRD.md#optional-mini-theatre-companion). This feature is separate from the implemented Theatre Passport projection. It must not change the diary schema, migrations, photos, identifiers, or CloudKit configuration.

## First release contract

Selected character: the original cream-and-gold lop-eared bunny (小剧灯). The cat is not part of v1. Four static states are base, idle, curious, and celebrate. Keep all six props independent of the character so ownership controls the visible outfit. Asset sources and prompts are in `design/mini-theatre/v1/`.

Provide an opt-in original companion, six props, three equipment slots, an optional theatre reflection prompt, and a share card. No AI classification, random drawing, currency, shop, streak, notifications, widgets, or server dependency. Reveal animation is presentation of a durable award, never the mechanism that determines ownership.

The companion is not a mental-health service and does not infer emotions. Personality copy should welcome users back without suggesting the character suffered during their absence. General mood tracking remains outside the product boundary.

## Ownership and persistence

| Component | Proposed representation | Ownership |
| --- | --- | --- |
| Catalog | Bundled JSON with schemaVersion, revision, and PropDefinition values | Read-only app resource, never seeded as mutable SwiftData rows |
| PropDefinition | id, assetName, slot, milestoneID, ruleVersion, rule | Stable ASCII identifiers; id and milestoneID resolve localized names and unlock hints |
| PropUnlock | awardKey, propID, ruleVersion, grantedAt, revealedAt optional | Separate local SwiftData store |
| TheatreStage | id, nickname, backgroundPropID, handheldPropID, decorationPropID | Separate local SwiftData store; fixed singleton id `main` |
| Preferences | miniTheatreEnabled, showsMiniTheatreShortcut, miniTheatreHapticsEnabled | Namespaced local settings; first two default false |
| EligibilitySnapshot | Distinct eligible performance IDs and venue keys | Ephemeral values derived read-only from LibraryStore |

Proposed types are contracts, not compiled schemas. Use stable enum raw values `background`, `handheld`, and `decoration`, not translated strings. Initial character artwork is separate from props; costume support is deferred.

Create a dedicated versioned CompanionSchemaV1 and an explicit separate store URL, such as Application Support/MiniTheatre/companion.store, with `cloudKitDatabase: .none`. Its schema contains only companion models. Never register them in StageLightSchemaV2 or open the diary store with this schema. No SwiftData relationships cross the containers.

Local-only unique constraints may enforce awardKey and the stage singleton id; they must never be copied into the CloudKit-backed diary schema. Revisit compatibility before any future companion sync. Apple documents the CloudKit constraint differences in [Syncing model data](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).

Stage and unlock storage failures disable only companion operations. Display a recoverable error and preserve the original store files. Never silently delete/recreate a corrupt store, fall back to a fresh store, or call a diary reset. No `try?` around important persistence operations.

## Milestones and eligibility

These are the proposed initial content and rules; artwork must be original and reviewed before implementation release.

| Stable milestone ID | Condition | Prop ID and provisional name | Slot |
| --- | --- | --- | --- |
| welcome | Explicit activation | welcome_pennant, 欢迎小旗 | handheld |
| visits_1 | One eligible performance | keepsake_ticket, 纪念票根 | decoration |
| visits_3 | Three eligible performances | golden_spotlight, 金色追光灯 | decoration |
| visits_5 | Five eligible performances | velvet_curtain, 丝绒幕布 | background |
| visits_10 | Ten eligible performances | memory_bouquet, 纪念花束 | handheld |
| venues_3 | Three distinct eligible venues | theatre_suitcase, 剧院旅行箱 | decoration |

An eligible performance has a persisted UUID and a date before the start of today in an injected local Gregorian calendar/time zone. Count distinct UUIDs; repeated viewings with distinct IDs remain valid, including same-day matinee/evening records. No attendance verification or anti-cheating claim is made. Today/future bookings do not count, even if the user has already attended today; disclose this conservative rule.

Unlike the passport venue list, a performance without a theatre still counts toward visit milestones. Venue milestones exclude blank theatre names and use the passport's structured `(trimmed theatre, trimmed city)` key. Do not merge case variants, aliases, or unknown cities with known ones. Photos, note length, ratings, ticket prices, entry method, and genre do not affect eligibility.

Evaluate on activation, after successful diary save/edit, after a library refresh from iCloud, on foreground entry, and on local-day change while active. Clock/time-zone changes may change current eligibility but never revoke committed awards. There is no background task requirement. Disabled mode performs no reconciliation; re-enable catches up in one batch.

## Award engine and transaction boundaries

The pure engine accepts a snapshot, injected date/time zone, validated rules, and owned award keys; it returns missing awards in catalog order. No model objects or note/photo content enter the engine.

Use stable milestone IDs as awardKey. ruleVersion records the rule used, but is not part of the key: upgrading a rule cannot accidentally grant the same milestone again. Released milestone semantics should remain stable; new milestones get new IDs.

1. The existing diary transaction completes independently and presents its normal success state.
2. A serialized companion coordinator snapshots eligible records and rechecks existing awards in its own context.
3. Insert all missing awards and initialize the stage if necessary in one companion transaction. The implementation must guard actor reentrancy and uniqueness races; do not share a ModelContext across executors.
4. Commit before showing an award notice. On failure roll back only the companion context and allow explicit or next-reconciliation retry.
5. Opening the notice shows the awarded props. Persist revealedAt after reveal acknowledgment. A crash may repeat a presentation, but never creates another ownership grant.

Reconciliation is the recovery mechanism if the app terminates after diary commit but before award commit. An award not yet committed may no longer qualify if its supporting diary record was subsequently deleted; do not reconstruct deleted content to award it. Once committed, ownership is permanent even when supporting records are removed. Store no source note, photo, venue name, or record relationship in the grant.

First activation and cloud-import catch-up show one summary regardless of award count. Do not interrupt the user once per imported record. Exhausting the catalog is a normal completed state, not an error or a duplicate reward.

## Catalog lifecycle and equipment

Validate unique IDs and milestone mappings, known slots/rule types, localization keys, existing image assets, supported schema version, and nonnegative thresholds before applying rules. Unsupported or invalid catalogs disable new grants with a recoverable state, without resetting ownership.

Bundled catalog updates are additive by stable ID, not `fetchCount == 0` seeding. Preserve unknown/retired prop IDs in storage; show a safe placeholder if their asset is missing and allow unequipping. Never delete historic grants just because a resource disappeared. New IDs reconcile against existing history.

Equip only an owned prop that matches the selected slot, replace the prior slot selection atomically, and allow each slot to be empty. Save failures keep the last persisted outfit. Keep exactly one stage using its fixed ID, never arbitrary `pets.first` selection. Nickname defaults to the localized 小剧灯 equivalent, accepts at most 24 grapheme clusters, and is never used as an identity key or logged.

## Interaction and accessibility

### Bunny and prop visual contract

Use base for the normal stage, idle while calmly waiting, curious for an optional reflection invitation, and celebrate after a durable award commit. No sad, hungry, injured, or guilt-based states. Reduce Motion uses a static state. Do not treat the four drawings as aligned animation frames: normalize their visible scale and foot baseline before swapping poses.

Render the curtain behind the bunny, the decoration beside it, and a handheld prop above the appropriate paw. Store normalized placement anchors separately per pose; never bake ownership-specific props into the bunny. Missing resources use a safe generic placeholder, not a crash or grant deletion. Source illustrations need edge review against dark/light backgrounds, 48-point inventory review, and iPhone/iPad layout review before release. Never stretch PNGs or rasterize localized labels into them.

For asset integration, verify six catalog-to-image mappings and all four character images, alpha transparency, no clipping, adequate contrast, and no UI labels in the artwork. These are asset/UI gates, not covered by the pure rule tests.

Profile offers activation with a concise privacy/durability explanation. Once enabled it opens the full stage and catalog; the Collection shortcut is separately opt-in and collapsible. Disabling retains awards and outfit and stops evaluation and companion prompts. No destructive reset action is included in the first release.

After saving, a nonblocking notice offers opening the gift or continuing. Never add a required step to the diary flow. A single optional prompt such as “今晚有什么瞬间想留住？” opens the existing note editor only on tap. Show the original note unchanged; the user controls edits and saving. Skip/cancel changes nothing and earns no penalty. No additional private conversation history is stored.

Use brief animations only while the scene is visible and active; honor Reduce Motion with a static reveal or restrained fade. Haptics are optional and nonessential. VoiceOver must announce award names and equipment state without reading decorative layers repeatedly. All actions have 44-point minimum targets, readable contrast, and accessible large-text layouts. Localize the full UI and catalog in English, Simplified Chinese, Traditional Chinese, and Japanese; IDs and counts remain semantically stable across language changes.

## Sharing and privacy

Render a portrait 1080 by 1350 image on MainActor from a dedicated share snapshot containing only original character/asset IDs and localized generic labels. Include app icon and Made with StageLight. First release excludes nickname, notes, photos, show/venue names, seats, dates, and precise location entirely; there is no hidden metadata payload containing them. An App Store link is a separate optional share item.

Show the exact preview before invoking the existing memory-card share sheet/Photos activity. No automatic upload or permission prompt. Temporary exports use non-sensitive filenames, no private metadata, and cleanup after use. Inspect both the pixels and shared item payloads in tests.

Diary responses may sync through private iCloud; companion state does not. Device-local does not mean excluded from device backup. Do not promise that state never leaves a device through backup, nor guarantee reinstall restoration. Remaining synced diary data can regenerate eligible milestones after activation, but cannot restore outfit choices or grants earned from deleted records. Preserve the distinction in all four languages.

## Deferred extensions

Timed exploration may later store startedAt, completesAt, and a preselected reward ID and resolve completion on next open, without a running background timer. Widgets, Live Activities, notifications, cross-device state, costume slots, and AI/show-specific content require separate specifications. Lock-screen views must default to generic artwork without attendance/location details. No claim of permanent or continuously animated Live Activities is part of this release; consult [ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) when scoping that work.

## Verification and release gates

The independent package `Packages/MiniTheatreCore` contains the pure rules used directly by the app via its local package dependency. All 31 XCTest contracts passed after implementation, following a verified failing-stub run. Run the package suite locally; its proposed CI step remains uncommitted because the current GitHub authorization lacks workflow scope. Existing app-unit CI covers integration tests. No test-only copy of the algorithm is used.

`StageLightTests/MiniTheatreTests.swift` covers catalog resources, disabled operation, batch idempotency, injected save failures, equipment rollback, history deletion, disk reopen, corrupt-store preservation, diary-value isolation and card rendering. `StageLightUITests/MiniTheatreUITests.swift` covers unlock → equip → share preview with screenshot attachments. These do not replace physical-device, VoiceOver, native-language or backup/restore checks. Use isolated temporary stores and original fixtures only.

### Pure core API and edge cases

- `plan(enabled:visits:now:timeZone:catalog:ownedKeys:)` returns only new grants. Disabled mode returns an empty plan before catalog validation. Callers supply value snapshots, not SwiftData objects. Duplicate identical UUID snapshots are deduplicated; conflicting copies must be resolved by the library adapter before calling the core.
- Catalog v1 rejects unsupported schema versions, duplicate prop IDs, duplicate milestone IDs, negative thresholds, and unavailable assets. Production JSON decoding must separately reject unknown slots/rules and missing localization keys; typed fixtures cannot test those decoder cases yet.
- Eligibility uses the injected Gregorian local-day boundary, including both DST transitions. Welcome does not need a visit. Plan ordering follows catalog order; no grant revocation operation exists.
- `equip(_:in:ownedPropIDs:catalog:outfit:)` returns a new outfit. A nil prop removes that slot, including retired IDs. A nonnil unknown prop throws `unknownProp`, a known unowned prop throws `unownedProp`, and an owned prop in the wrong slot throws `slotMismatch`. Unrelated slots remain unchanged.
- `validateNickname(_:)` trims surrounding whitespace, then accepts 1–24 Swift Character grapheme clusters, including composed emoji; blank or longer input throws `invalidNickname`. An untouched empty stored nickname displays the current locale's default; explicit rename cannot be blank.
- The 1,000-record unit case checks bounded results and value immutability, not device timing or real diary safety. Those require MT11/MT18 integration verification.

| ID | Layer | Acceptance scenario |
| --- | --- | --- |
| MT01 | Unit | Disabled feature produces no grants, prompts, or diary effects; welcome requires explicit activation. |
| MT02 | Unit | Each threshold grants once; duplicate UUIDs do not inflate counts, but separate repeat viewings do. |
| MT03 | Unit | Today/future, midnight, DST, and time-zone changes follow the eligibility policy. |
| MT04 | Unit | Blank theatre counts for visits but not venues; exact structured keys keep cities and aliases distinct. |
| MT05 | Unit | Edits, extra photos, repeated callbacks, and rule-version changes cannot regrant an owned milestone. |
| MT06 | Unit | Invalid catalog, missing asset, unknown retired ID, exhausted pool, and added milestones have defined safe outcomes. |
| MT07 | Integration | Companion context/store failure cannot modify or roll back a successful diary save. |
| MT08 | Integration | Process interruption at each transaction boundary converges to one durable grant on retry. |
| MT09 | Integration | Concurrent reconciliations produce one stage and one grant per milestone; equipment changes survive reopen. |
| MT10 | Integration | Deleting supporting diary records retains committed awards and never recreates deleted data. |
| MT11 | Integration | Capture diary IDs, relationships, notes, timestamps, and photo checksums before activation/reconciliation/disable; all remain unchanged. |
| MT12 | Integration | Existing diary/iCloud migrations remain unchanged; companion upgrade and corrupt-store errors never erase either store. |
| MT13 | UI | Fresh activation and old-library backfill, one summary, reveal/skip, equip/unequip, disable/re-enable, and relaunch. |
| MT14 | UI | Reflection skip/cancel preserves notes; saving uses existing editor semantics and never changes rewards. |
| MT15 | Privacy | Share preview, export pixels/metadata/items, temporary filenames, and logs contain no excluded diary or nickname data. |
| MT16 | Accessibility | VoiceOver, Reduce Motion, haptics off, large text, dark/light, iPhone compact and iPad portrait/landscape. |
| MT17 | Localization | Four locales, long labels, nickname graphemes, number formatting, and unchanged ownership after switching language. |
| MT18 | Scale | Reconcile 1,000 performances without loading full photos, duplicate popups, or blocking diary save; record device timing. |

Release requires passing unit/integration/UI suites, original-asset review, native-language copy review, iPhone/iPad screenshots, and physical-device offline/save-to-Photos smoke tests. Confirm that reward failure leaves normal diary use available. No release or implementation is authorized by the documentation update itself.
