# Mini Theatre implementation QA

Date: October 18, 2026. Feature branch: `feature/mini-theatre-visual-assets`.
This is an implementation verification record, not release approval.

## Merge-request snapshot verification

Mini Theatre's DEBUG-only preview fixtures have been separated from the uncommitted Theatre Passport feature. The PR excludes all Passport UI and models. Testing the exact staged snapshot passed 31 core tests, 10 integration tests and 3 of 4 iPad UI cases (Chinese portrait, Chinese landscape, disabled). English failed waiting for `mini-acknowledge`; an isolated retry was blocked by disk exhaustion before launch. This newer failure supersedes the earlier all-green UI result as a merge gate. Create as draft until the English case is reverified. Logs: `/private/tmp/mini-mr-validation.log` and `/private/tmp/mini-mr-core.log`. Result finalization was interrupted under disk pressure; use logs rather than assuming the bundle is complete.

## Scope delivered

- Opt-in Profile setting; a separate optional Collection shortcut. Both default off.
- Original bunny and six milestone props; batch welcome/backfill acknowledgement, equip/remove, nickname and optional haptics.
- Local-only versioned companion SwiftData container, separate from the existing diary/iCloud schema. Failure preserves stores; no delete-and-recreate recovery.
- Deterministic reward rules in the local MiniTheatreCore Swift package, used by the app and CI.
- English, Simplified Chinese, Traditional Chinese and Japanese copy and 1080×1350 share-card rendering. Cards accept outfit IDs only, not diary models or nicknames. Optional App Store link defaults off.
- Optional reflection opens the existing performance editor; no automatic notes or AI classification.

## Automated evidence

- 31 pure-rule XCTest cases passed. The preceding test-first run failed against explicit stubs; production rules now replace those stubs.
- All 103 app unit tests passed on iOS 26.5, including 10 new companion integration tests. Evidence: `/private/tmp/mini-theatre-ios26-final.xcresult`.
- Integration cases cover opt-out, idempotency, rollback, unchanged diary values, retained awards after history deletion, disk reopen, corrupt-store byte preservation, bundled assets and four-language card rendering.
- An initial share-preview UI assertion failed because the preview had no grouped accessibility element; fixed and both original iPhone UI cases subsequently passed (`/private/tmp/mini-theatre-ui-fixed.xcresult`).
- Final three-case iPhone UI matrix (English flow, Chinese flow, disabled) passed: `/private/tmp/mini-iphone-final.xcresult`. Exported screenshots were visually inspected; button contrast and pennant placement were improved before this run.
- iPad verification completed after disk cleanup: all 10 companion integration tests and 3 UI tests (English, Simplified Chinese, disabled) passed on iPadOS 26.5, device E516644F-6140-42B4-93A8-043EF136D8D1. Evidence: `/private/tmp/mini-ipad-verification.xcresult`. A separate Chinese landscape unlock/equip/share test also passed: `/private/tmp/mini-ipad-landscape.xcresult`.
- The earlier Chinese iPad failure was resolved by small bidirectional scroll gestures in the test helper rather than long swipes that could skip short localized rows. No application logic or diary-storage changes were needed in this verification task. Portrait screenshots were inspected for readable labels, three-column props, centered modal and share preview.
- Landscape screenshot capture was changed from the rotated app-window rectangle to `XCUIScreen.main.screenshot()` to avoid black/cropped output. The landscape flow passed again (`/private/tmp/mini-ipad-landscape-screen.xcresult`); full-display screenshots were visually checked with centered sheets, three-column props and complete share preview. Review PNGs are saved in the task's `artifacts/mini-theatre-review/ipad/` directory.

## Remaining release gates

- Physical-device offline use and system share → Save Image; photo permission denied/granted paths.
- The updated scroll helper has now been compiled and verified on iPad; rerun on iPhone before release (the preceding iPhone three-case run passed with the earlier helper).
- VoiceOver, maximum accessibility text, dark appearance, Reduce Motion and iPad window resizing.
- Native-language copy review and final visual approval of layered prop placement.
- Process-kill-at-commit, backup/restore and low-disk testing. Injected pre-save failure and reopen tests do not establish all crash/backup guarantees.
- No App Store submission performed. A separate merge-request task packages this implementation for review.

The iOS 27 simulator initially stalled before application code in the system loader. Verification used iOS 26.5; iOS 27 remains a separate environment/release check. Existing simulator and diary data were not erased.
