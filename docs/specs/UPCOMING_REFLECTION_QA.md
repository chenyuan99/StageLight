# Upcoming performances and reflections — implementation review

Branch: `feature/upcoming-reflections`
Issues: #8 and #50

## Scope delivered
- Optional Upcoming status in the existing add/edit form; ordinary entries remain Attended.
- Diary Overview, Upcoming, Attended, Cancelled and All filters; optional upcoming section visibility in Profile → Settings.
- Explicit Mark attended, cancellation without deletion, restoration and existing editing for rescheduling.
- Private, focused notes editor and opt-in post-attendance reflection offer. No time-based attendance inference, catch-up prompts, notifications or Calendar permission.
- Attendance-only statistics, seen counts, ratings and Mini Theatre visits. Existing earned props remain intact.
- Four-language labels and an adaptive native form/editor.

## Data safety
- Frozen shipped V2 models and additive V3 migration with nullable `statusRaw`.
- Legacy nil status retains attended semantics even for future-dated records. Unknown statuses survive unrelated edits and do not earn attendance credit.
- Status actions preserve the same record, photos and relationships. Notes saves modify only notes and update timestamp; stale note edits are rejected, and the editor retains its draft with an explicit combine flow.
- Failure injection covers focused saves restoring only the fields they changed, not rolling back unrelated work.
- Startup persistence errors show a recovery explanation without deleting/recreating the store. The test reset argument is Debug/UI-test-only.
- Demo fixtures run only in an in-memory, CloudKit-disabled UI-test library.

## Verification
Tests were written before implementation. The initial build failed on missing feature APIs; implementation followed.
- Full app unit suite: 109 tests passed, including V1-to-V3 and V2-to-V3 disk-store migrations.
- Migration fixture assertions include identity, timestamps, future dates, notes, seat fields, rating, show relationship, photo identity/order/filename and exact photo data.
- Focused regressions cover status transitions, stale/deleted record edits, save failures, unknown states, opt-in/one-time prompts and repeat transitions without duplicate bunny rewards.
- iPhone iOS 26.5: all 3 UI tests passed (create booking; cancel/restore and opt-out/dirty-draft protection; attendance/reflection/rotation/save).
- iPad iOS 26.5: booking-to-reflection UI flow passed, including rotation and save.
- Duo iOS 27.1: the same UI flow passed, including rotation and save. This is not a full open/closed/partially-folded transition matrix.
- Actual screenshots exported and visually reviewed under the project workspace `artifacts/upcoming-reflections/{iphone,ipad,duo}/`. Includes booking form, Diary, booking detail, reflection offer/editor and saved memory.
- Results: `/tmp/stagelight-upcoming-verified.xcresult` (109 passing unit tests; earlier UI selector failure), `/tmp/stagelight-upcoming-iphone26.xcresult` (3 passing UI tests), `/tmp/stagelight-upcoming-ipad-review.xcresult` and `/tmp/stagelight-upcoming-duo.xcresult` (one passing UI test each).
- During iteration, fixed the draft-discard dialog to retain an explicit Keep Editing action on popover layouts. Adjusted test selectors for duplicated native accessibility wrappers.
- Xcode's simulator tooling updated during testing; the iOS 27.0 runtime subsequently became unavailable. Unit tests had completed successfully on it. Final regular-device UI review used available iOS 26.5; Duo used 27.1.

## Release limits
- Manual two-device iCloud and mixed-version-client testing remains a release gate. Simulator tests do not establish conflict-free cross-device synchronization; edits arriving after a successful local save still follow the existing SwiftData/CloudKit merge behavior.
- Downgrading an on-disk V3 store to an older app is not guaranteed. Do not reset a store to work around migration failures.
- Apple Calendar integration and scheduled local reminders are explicitly deferred as specified in #8.
- Theatre Passport/recap consumers are not present in this checkout; future implementations must use the same attendance predicate.

## Dedicated Settings follow-up
Application preferences now live under Profile → Settings, grouped into Appearance, Behavior and Data. Language, app icon, Diary, Mini Theatre (including haptics), Theatre history and iCloud status use their original storage keys/defaults. Profile contains statistics and a Settings link; the Mini Theatre content screen no longer hosts the haptics toggle. No data schema change was needed for this relocation.

Verification: build and 3 focused iPhone UI tests passed (Settings navigation/preference persistence across relaunch; Mini Theatre settings route; iCloud status route). Actual screenshots: project workspace `artifacts/settings/`. Existing history/icon UI tests were updated for the new navigation; physical icon-switch testing was not repeated for this navigation-only change.
