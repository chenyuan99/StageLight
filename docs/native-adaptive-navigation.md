# Native adaptive navigation

## Scope

Restore the system tab bar for Collection, Diary, and Profile. Let the operating system choose horizontal or vertical placement from the available environment, without device-name checks or fixed side insets. Keep the three navigation stacks and tab selection stable across resizing. Add remains a sheet owned by MainTabView and is available as a labeled primary toolbar action on each destination's root screen. Collection's empty-state Add action remains available.

The former custom gold Add button and manually drawn bottom navigation are removed. Collection no longer reserves 88 points for that bar. The filter control supplies both its title and symbol for accessibility and system overflow. Mini Theatre's pending-reward notice now lives inside Collection content rather than overlaying the app's navigation bars. Rewards still reconcile globally; the notice is shown when visiting Collection.

This change does not introduce a collection/detail split view or redesign Mini Theatre's content.

## Data safety

No model, schema, migration, repository, photo-storage, iCloud configuration, or Mini Theatre persistence changes. Navigation state and the existing editor sheet remain in SwiftUI state; dirty-draft dismissal protection remains active. This is not disk-backed draft recovery after force quit.

Debug UI-test runs use isolated in-memory data. Profile skips its CloudKit account query only in DEBUG with `-ui-testing`, matching the existing test storage isolation; release account checks are unchanged.

## Regression coverage

- Visit all three native tabs and verify Add is available.
- Create a performance, view it in Diary, and return to the retained Collection detail screen.
- Rotate an unsaved editor, choose Keep Editing, then explicitly discard.
- Existing legacy-store migration and repository/photo tests.
- Mini Theatre unlock, equip, and share-preview smoke test.

Screenshot review includes ordinary iPhone and Duo closed/open/partially folded layouts. Simulator checks do not certify physical hardware or every accessibility size.

## Verified October 23, 2026

- Native tab navigation / save / retained detail UI test passed on Duo iOS 27.1 and iPhone 17 Pro iOS 26.5.
- Unsaved draft rotation and cancelled-discard UI test passed on both devices.
- Final Mini Theatre unlock/equip/share-preview regression passed on both devices after fixing the reward sheet lifetime.
- Five migration/repository tests passed on iPhone 17 Pro, including preservation of the version-1 library and photo payload persistence.
- Manual Duo screenshots captured closed, open, and partially open. Regular iPhone screenshot captured with standard bottom tabs. Test fixtures deliberately contain no photos.
- Review images: `/tmp/stagelight-native-navigation/` (`duo-closed.png`, `duo-open.png`, `duo-partial.png`, `iphone.png`).

No live user library was used or modified. Physical-device testing, accessibility coverage, and fold-aware collection content layout remain separate follow-ups.

### Regular iPhone on iOS 27

The iPhone 18 Pro simulator on iOS 27.0 passed all three focused UI tests: native tabs/save/retained detail, unsaved draft rotation and cancelled discard, and Mini Theatre unlock/equip/share preview. Result bundle: `/tmp/stagelight-duo-check/Logs/Test/Test-StageLight-2026.10.23_22-23-57--0400.xcresult`.

The installed iOS 27.1 runtime rejected creation of an iPhone 18 Pro simulator as incompatible, so this comparison uses iOS 27.0 for the regular iPhone and 27.1 for Duo, not identical runtime builds.
