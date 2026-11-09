# Optional post-show reflection

Status: implemented for local review on `feature/upcoming-reflections`. See `UPCOMING_REFLECTION_QA.md` for verification and remaining release gates.
GitHub: https://github.com/chenyuan99/StageLight/issues/50
Depends on upcoming-performance transitions in #8 for the planned-to-attended entry point; manual reflection works independently. Reuses notes work in #24 and draft protection in #36.

## Outcome
Help users remember a performance with one optional sentence, a rating or photos. Nothing is required to mark a performance attended. Reflection is a private diary action, not a public review or a task needed to keep the bunny happy.

## Experience
- After a successful explicit Mark attended save, offer a non-modal Add a memory action with Not now. The attendance save is already complete; dismissing the prompt does not undo it.
- Performance Detail always offers Add/Edit notes, so users can return whenever they choose, including for older performances.
- Optional prompts: What stayed with you? / A moment you want to remember? Use bundled localized copy. Do not insert prompt text into the user's saved notes.
- A setting Offer post-show reflection defaults off until explicitly enabled. Even when off, manual Add/Edit notes remains available. No notification permission request or background reminders in MVP.
- If enabled, show at most one offer per explicitly confirmed performance on that device. Persist dismissal/completion locally by performance UUID and prompt version; no catch-up prompts for an imported or existing library, sync replay, or app launch. Do not prompt merely because time passed.
- When Mini Theatre is enabled, the bunny can accompany the same prompt; otherwise use a neutral presentation. No guilt, streak loss, countdown, required response or rewards for repeated edits.
- Reuse the focused notes editor; show existing text before editing. Optional rating/photos use existing fields and controls. Never automatically publish a reflection or include it in a memory card; keep explicit sharing choices.

## Data and save contract
Performance.notes remains the single source of truth. Do not create a competing reflection text field or replace notes with an AI summary. Existing multiline text, whitespace, emoji and all languages survive opening and cancelling the editor. Only an explicit Save can change content; clearing nonempty notes is an intentional edit protected by unsaved-change handling.

Use a value-type draft bound to the performance UUID. Cancel leaves persisted data unchanged, and swipe dismissal/navigation prompts to keep editing or discard when dirty. Keep drafts through resize, rotation and Duo folding. Failed saves keep the editor and draft available and show retry; do not advance completion state until success. Attendance success must survive a later reflection failure.

A focused notes update must not round-trip a stale whole-performance snapshot that overwrites newer photos, venue, status or rating. Compare the original note revision/content with the latest record before saving. If changed, retain both the current stored note and the user's draft and ask which to keep or combine; do not silently overwrite. If the performance was deleted elsewhere, preserve the draft for copying/recovery and explain the missing record rather than recreating it automatically. Test the actual persistence path, including rollback scope.

Prompt bookkeeping is local UI preference state, separate from the diary and private iCloud content. Turning prompts off never deletes notes, photos, ratings, attendance or props. Notes continue through the existing private iCloud path when available; do not claim they never leave the device. No analytics, network AI, public posting or new account requirement.

## Tests first / acceptance gates
- [ ] Manual reflection works with prompts disabled and Mini Theatre disabled.
- [ ] Enabled prompt appears only after a successful explicit attendance confirmation; cancelled/failed confirmation produces none.
- [ ] Not now, successful save, repeated taps, app restart and sync replay do not repeatedly prompt; enabling the setting does not prompt the existing library.
- [ ] One performance's prompt state and notes do not affect repeat visits to the same show.
- [ ] Existing notes open intact; save/update/explicit clear persist; cancel leaves content and unrelated fields unchanged.
- [ ] Multiline text, emoji, whitespace and all four supported languages round-trip accurately.
- [ ] Save failure retains draft and persisted original; retry is idempotent and attendance remains saved.
- [ ] Concurrent note edits preserve the draft and expose conflict resolution; unrelated concurrent edits survive a notes save.
- [ ] Deletion during editing never silently recreates a record or loses the active draft.
- [ ] No extra Mini Theatre rewards from reopening, editing or repeated saves.
- [ ] Shared cards exclude notes unless explicitly selected by the user.
- [ ] UI coverage for disabled/enabled prompts, Not now, manual editor, dirty dismissal, errors and text keyboard on compact iPhone, iPad and Duo.
- [ ] Simulator screenshots: post-attendance offer, populated editor, opt-out setting; verify folding/rotation keeps unsaved text, VoiceOver and large type.
- [ ] Manual offline/relaunch and two-device iCloud regression before release. Use isolated fixtures, not personal diary data.

## Delivery order
1. Review specs and latest model/repository behavior.
2. Write failing unit and persistence regression tests.
3. Implement the smallest manual reflection flow and opt-in prompt policy.
4. Run regression/UI tests and inspect actual simulator screenshots.
5. Release only after migration and preservation gates pass; keep release gated on the documented data-preservation checks.
