# StageLight 1.6.0 (8) — Release preparation

Prepared from main merge commit `3d7a9e0` (PR #46). This is a candidate, not a submitted or live release.

## Version verification

On 2026-10-23, the signed-in App Store Connect listing showed 1.5.0 Ready for Distribution and TestFlight showed 1.5.0 build 7 as the latest version. This differs from the owner's earlier confirmation of 1.5.1 documented in RELEASE_1.5.1.md. Historical confirmation is retained; this candidate uses 1.6.0 build 8, above both versions.

## What's New — English
- Navigation now adapts to iPhone Duo, with native tabs and toolbar controls that adjust to the display.
- Add a performance from the toolbar in Collection, Diary, or Profile.
- Edited performance drafts now ask for confirmation before being discarded.
- Mini Theatre reward notices no longer cover navigation controls.
- Your saved performances, photos, notes, iCloud settings, and local Mini Theatre progress are preserved.

## 简体中文
- 导航现已适配 iPhone Duo，原生标签栏和工具栏可随屏幕布局调整。
- 在「收藏」「日记」或「我的」页面，通过工具栏添加演出。
- 放弃已编辑的演出草稿前，会先请你确认。
- 小剧场奖励提示不再遮挡导航按钮。
- 已保存的演出、照片、笔记、iCloud 设置和本机小剧场进度保持不变。

## 繁體中文
- 導覽現已適配 iPhone Duo，原生標籤列和工具列可隨螢幕配置調整。
- 在「收藏」「日記」或「我的」頁面，透過工具列新增演出。
- 放棄已編輯的演出草稿前，會先請你確認。
- 小劇場獎勵提示不再遮擋導覽按鈕。
- 已儲存的演出、照片、筆記、iCloud 設定和本機小劇場進度保持不變。

## 日本語
- iPhone Duo に合わせて、標準のタブとツールバーが画面に応じた配置に変わります。
- コレクション、日記、プロフィールのツールバーから公演を追加できます。
- 編集した公演の下書きを破棄する前に、確認が表示されます。
- 小さな劇場の報酬通知がナビゲーションを覆わなくなりました。
- 保存済みの公演、写真、メモ、iCloud 設定、端末内の小さな劇場の進行状況は保持されます。

## App Review notes
No StageLight account or login is required. This update uses system tabs and toolbar actions for adaptive navigation. The Add (+) action is in the toolbar on Collection, Diary, and Profile. Existing local and private iCloud diary storage is unchanged. Mini Theatre remains optional, with progress stored on the device. No ads, tracking, purchases, or subscriptions are introduced. Unsaved drafts are protected from accidental dismissal but are not recovered after force quit.

## Verification and release gates

- Merged source: PR #46 verified merged into main.
- Focused native-navigation/save/retained-detail, unsaved-draft rotation/discard, and Mini Theatre unlock/equip/share-preview tests passed on Duo iOS 27.1 and regular iPhone iOS 26.5 / 27.0.
- Five migration/repository tests passed, including legacy-library and photo-payload preservation.
- No model, schema, migration, repository, photo storage, or production iCloud changes.
- Physical Duo, camera-active layouts, all accessibility sizes, and every fold/rotation combination are not certified by these simulator checks.
- Verify archive version, build, bundle identity, icons, supported device families, and production iCloud entitlements before upload.
- Distribution export, upload, App Store review, and public availability must be recorded separately when completed.
- Keep website and README live-version messaging unchanged until Apple release availability is confirmed.

## Candidate verification — 2026-10-23

- Release archive succeeded with Xcode 27.1 (27A9275).
- App Store Connect distribution export succeeded with Cloud Managed Apple Distribution signing and `get-task-allow=false`.
- Verified 1.6.0 (8), bundle ID `com.chenyuan.StageLight`, iPhone/iPad families, iOS 18 minimum, DefaultAppIcon primary and all existing alternate icons.
- Verified Production CloudKit container `iCloud.com.chenyuan.StageLight` and unchanged key-value store identifier.
- All 98 app unit tests passed on iPhone 18 Pro / iOS 27.0.
- Archive, signed IPA, export summary, and logs are saved locally in the project workspace's `release-artifacts/1.6.0-8/` directory (outside the repository).
- Candidate has not been uploaded, submitted for review, or released. Apple server-side upload validation remains pending.
