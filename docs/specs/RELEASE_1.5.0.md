# StageLight 1.5.0 (7) — Waiting for Review

Submitted to App Store Review on 2026-10-19 after user authorization. Build 7 is associated with the submission; automatic release after approval is configured. This is not yet a public release. Current live version: 1.4.1.

Scope: optional local Mini Theatre bunny companion, prop collection and sharing; app icon customization; Golden premiere primary icon. Historical theatre feature inherited from main is included. Uncommitted Theatre Passport and workflow edits are excluded.

## What's new — English
- Meet your theatre bunny in the optional Mini Theatre. Collect props as you record past performances and decorate your little stage.
- Share a picture of your bunny and its outfit without including your diary details.
- A new Golden premiere app icon, plus optional Original, Theatre bunny and Cream bunny icons in Profile.
- Your saved performances, photos, notes and existing private iCloud settings remain unchanged. Mini Theatre progress is stored separately on this device.

## 简体中文
- 可选的掌上小剧场上线：认识剧场小兔，记录往日演出，收集道具并装扮你的小舞台。
- 分享小兔与装扮图片，不包含日记详情。
- 全新金色首演默认图标；也可在「我的 → 应用图标」选择原版、剧场小兔或奶油小兔。
- 现有演出、照片、笔记及私密 iCloud 设置保持不变。小剧场进度独立保存在本机。

## 繁體中文
- 可選的掌上小劇場登場：認識劇場小兔，記錄往日演出，收集道具並裝扮你的小舞台。
- 分享小兔與裝扮圖片，不包含日記詳情。
- 全新金色首演預設圖示；亦可在「我的 → 應用程式圖示」選擇原版、劇場小兔或奶油小兔。
- 現有演出、照片、筆記及私密 iCloud 設定保持不變。小劇場進度獨立儲存在本機。

## 日本語
- 任意で使える「小さな劇場」が登場。劇場のうさぎと一緒に、過去の公演を記録して小道具を集め、舞台を飾れます。
- 日記の詳細を含めずに、うさぎと小道具の画像を共有できます。
- 新しい「黄金の初日」が標準アイコンに。プロフィールからオリジナル、劇場のうさぎ、クリームうさぎも選べます。
- 保存済みの公演、写真、メモ、プライベートiCloud設定は変わりません。小さな劇場の進行状況は、この端末に別途保存されます。

## Review notes
No app login is required. In Profile, enable Mini Theatre to inspect the optional companion and its local-only props. App icon options are available independently of this toggle. Selecting an icon uses Apple's public alternate-icon API and its system confirmation. Existing diary data and iCloud storage are not reset or migrated by the icon feature. No ads, tracking, purchases or subscriptions are introduced.

## Release gates
- Verify clean committed source only, all unit tests and targeted icon UI tests.
- Verify primary icon is DefaultAppIcon (Golden premiere); previous icon names remain bundled for upgrades.
- Verify signed Release archive version/build and Production iCloud entitlement.
- PR CI must pass; review and merge before upload.
- Update product screenshots/privacy description if needed for the optional local companion.
- Submission authorization received and completed on 2026-10-19. Verify Apple approval before describing 1.5.0 as publicly available.
