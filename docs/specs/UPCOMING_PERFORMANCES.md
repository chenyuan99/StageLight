# Optional upcoming performances

Status: implemented for local review on `feature/upcoming-reflections`. See `UPCOMING_REFLECTION_QA.md` for verification and remaining release gates.
GitHub: https://github.com/chenyuan99/StageLight/issues/8
Companion reflection specification: https://github.com/chenyuan99/StageLight/issues/50

## Outcome and scope
Save a booking before the show and later turn the same record into an attended performance without retyping or losing anything. Existing diary-only usage remains unchanged. Planning is optional; users explicitly choose Upcoming when adding a record. Default ordinary entry remains Attended. Rating, notes, photos, venue, seat and curtain time remain optional; title and date follow existing validation.

## Experience
- Reuse the existing add/edit flow with an explicit Upcoming / Attended choice. Scanning suggests fields but never infers attendance or saves automatically.
- Add an Upcoming filter/section within Diary, not another navigation tab. Show date, title, venue and an optional curtain time; sort nearest first.
- Exclude upcoming records from attended totals, ratings summaries, anniversaries, theatre passport stamps, annual recaps and Mini Theatre rewards. Collection may display a planned-only show with an Upcoming badge and zero attended visits.
- Provide Mark attended, Reschedule and Cancel booking on detail. Mark attended updates the same record; confirmation can offer an optional reflection afterward.
- Passing the scheduled date never marks attendance. Show a neutral Needs confirmation state derived from the date, not a persistent attendance transition. Allow explicit early attendance confirmation when correcting a date.
- Cancel booking preserves the record and attachments in a Cancelled filter; restoring it returns it to Upcoming. Actual deletion remains a separate existing destructive action with confirmation and synced-deletion wording.
- An optional Show upcoming section setting hides only the section; records remain accessible through filters/search. Turning reminders or section visibility off never deletes records.

## Persistence and compatibility
Proposed additive storage: optional statusRaw string on Performance; known values upcoming, attended and cancelled. Nil means legacy attended. Do not infer legacy status from dates: old future-dated records must retain their previous behavior until explicitly edited. Preserve unknown future values in storage and show an unsupported-status explanation; exclude them from attendance-derived rewards until understood, and never coerce them on unrelated edits.

Extend PerformanceDraft and repository mapping without changing UUIDs, show relationships, createdAt, notes, ratings, photo bytes, filenames or ordering. Status transitions modify only status and updatedAt. Cancellation and attendance never delete/reinsert a Performance or Show. Save failures retain the draft and restore affected in-memory mutations before offering retry; isolate rollback from unrelated edits.

Audit the latest main before implementation: this proposal is based on the current Performance model with no status field. Keep changes additive and compatible with the existing SwiftData/private CloudKit store. Prove the migration using a real prior-schema fixture, not only freshly created models. Never reset the store, delete SQLite files, or fall back to an empty database after migration failure. Preserve the original store and show a recoverable error. Existing unknown fields must survive unrelated saves where supported; specifically test mixed old/new app clients before release rather than promising downgrade compatibility.

Centralize attendance predicates so every collection, stats, passport and reward consumer agrees. Transition processing must be idempotent: double taps, sync replay, and toggling status must not mint repeated rewards. Editing a historical status must follow existing non-destructive reward policy; never confiscate earned props.

## Dates, reminders and calendar
MVP: planning and manual confirmation only. Local reminders and Apple Calendar integration are a separately gated follow-up, preserving the original issue's requested scope.

For follow-up: reminders off by default and permission requested only after the user enables one. Store a stable per-performance notification identifier; rescheduling replaces only that notification, cancellation removes it, and no alert is scheduled in the past. Date-only entries have no invented curtain time. Define venue time zone explicitly for timed bookings and test DST/travel; never silently reinterpret existing dates. Calendar export is a separate explicit action with minimum required access. Do not delete or overwrite user-edited calendar events automatically; record linkage and explain divergence. All features work without permission or network. Notification scheduling failure does not undo a successfully saved booking.

## Tests first / acceptance gates
- [ ] Prior-schema migration and reload preserve every existing field, relationship, UUID and photo byte; legacy future dates remain legacy attended.
- [ ] Nil, known and unknown raw statuses have explicit tested behavior; unrelated edits preserve unknown values.
- [ ] Upcoming -> attended -> upcoming and cancelled -> restored preserve the same record and all content.
- [ ] Repeated confirmation, retries and sync delivery create no duplicate records or rewards.
- [ ] Upcoming/cancelled records are excluded consistently from all attendance-derived features.
- [ ] Save/migration failures do not discard content, destroy the store or display false success.
- [ ] Date boundaries, absent time, DST, time-zone travel and rescheduling do not auto-confirm attendance.
- [ ] Existing photos/notes and drafts survive rotation, Duo open/closed/partial transitions and navigation changes.
- [ ] UI tests cover ordinary attended entry unchanged, planned entry, confirmation, cancellation, restoration and hidden section access.
- [ ] English, Simplified Chinese, Traditional Chinese and Japanese; VoiceOver, Dynamic Type, reduced motion; iPhone, iPad and Duo screenshots.
- [ ] Manual offline/relaunch and two-device iCloud tests, including mixed-version clients and concurrent edits; resolve conflicts without silently replacing an active draft.
- [ ] Follow-up reminder tests: denied permission, reschedule, cancel, duplicate requests, scheduling error and calendar edits.

## Non-goals
Ticket sales, live listings, scraping, public activity feeds, mandatory notifications, automatic attendance, new accounts or server scheduling.
