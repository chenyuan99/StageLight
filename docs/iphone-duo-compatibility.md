# iPhone Duo compatibility smoke test

Tested October 23, 2026, on `feature/duo-compatibility`, based on main `93d88b7`.

## Environment

- Xcode 27.1; iOS 27.1 simulator runtime 24A94425.
- Dedicated iPhone Duo simulator; debug UI testing uses an in-memory SwiftData store with CloudKit disabled.
- No production data/schema migration is introduced.

## Results

- 10 layout, photo-layout, and draft unit tests passed on the existing iPhone test simulator.
- 2 UI tests passed on Duo: manual performance creation and draft retention through rotation, Keep Editing, and explicit discard.
- Manual Device Hub checks: entered `Duo folding draft` on the open inner display, switched to partially open, fully open, and closed. The title remained intact and the editor adapted between inner and outer displays.
- Screenshots exported to `/tmp/stagelight-duo-screenshots` (local review artifacts, not committed).

## Changes

- Dirty forms require confirmation before Cancel discards edits; swipe dismissal is disabled while dirty or saving.
- Initial draft comparison is held in SwiftUI state to remain stable across view reconstruction.
- Discard prompts localized for Simplified Chinese, Traditional Chinese, and Japanese.
- Debug UI tests are isolated from CloudKit and persistent diary data. Release storage behavior is unchanged.

## Remaining validation

### Mini Theatre follow-up

- All 4 `MiniTheatreUITests` passed on Duo (80.2 seconds, zero failures): English and Simplified Chinese unlock/equip/share-preview flows, Chinese landscape, and disabled-feature visibility.
- Manually kept Mini Theatre open while changing from open to partially open to closed. The sheet and prop controls adapted to each display; the same screen and nickname remained visible, with no crash observed. This did not verify unsaved nickname edits or equipped-state persistence across relaunch.
- Screenshots: `/tmp/stagelight-duo-mini-screenshots`; automated screenshot attachments are in its `test-attachments` directory. Log: `/tmp/stagelight-duo-mini-tests.log`.
- System share-sheet delivery, Photos saving, accessibility sizes, and rotation in every fold pose remain untested in this follow-up.

This is not comprehensive compatibility certification. Still test physical hardware, camera capture, Photos and share sheets, Dynamic Type/VoiceOver, all languages, populated collections, and rotation in every fold pose. The native-navigation follow-up restores system tab and toolbar placement; see `native-adaptive-navigation.md`. Unsaved drafts remain session-only; force-quitting the app is not covered by the discard guard.

The first simulator reboot reported a simulator data-migration failure; a subsequent app launch and manual fold checks succeeded. This is an environment observation, not evidence of production diary data loss.
