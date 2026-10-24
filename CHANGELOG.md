# Version history

## 1.6.0 (8) — release candidate

- Native adaptive navigation for iPhone Duo and regular iPhone.
- Labeled Add action in the toolbar; navigation remains available as the display changes.
- Confirmation before discarding edited performance drafts.
- Mini Theatre reward notice no longer covers navigation controls.
- No production storage or schema changes.

See [release preparation](docs/specs/RELEASE_1.6.0.md). Not yet submitted or live.

## 1.5.1 — live on the App Store

Confirmed fully live by the app owner on 2026-10-20. This is the confirmation
date, not an inferred release date. Available for iPhone and iPad.

- Optional Mini Theatre bunny companion, prop collection, stage decoration, and bunny sharing.
- Golden Premiere default icon, with Original, Theatre bunny, and Cream bunny alternatives.
- Existing diary records and private iCloud settings are unchanged; Mini Theatre progress remains local to the device.

See [release details](docs/specs/RELEASE_1.5.1.md). No additional patch-specific
changes or build number are claimed without a verified release record.

## 1.5.0 (7) — submitted for review, 2026-10-19

Historical submission snapshot: App Store Connect confirmed **Waiting for Review**
on 2026-10-19, with automatic release configured and 1.4.1 live at that time.
This is not the current release status; 1.5.1 is now live.

- Optional Mini Theatre bunny companion: collect props from past performances and decorate a local stage.
- Share bunny outfit images without nickname or diary details.
- Golden premiere default icon and Original, Theatre bunny, and Cream bunny alternatives in Profile.
- Existing performances, photos, notes, and private iCloud settings remain unchanged.
- Mini Theatre progress is stored separately on the device, not synced through iCloud.
- English, Simplified Chinese, Traditional Chinese, and Japanese release copy.

See [release details](docs/specs/RELEASE_1.5.0.md).

## 1.4.1 — current public release at submission

Verified as Ready for Distribution in App Store Connect on 2026-10-19.
This history starts from the verified release baseline; it does not infer dates
or feature lists for older versions.

## Website maintenance

The landing page release copy is maintained in `website/lib/releases.json`.
When release availability changes, update the status, live version, and all four
localized status/history strings together. Do not mark a submission or confirmation date as a
public release date. The public URL remains https://yuanchen.io/StageLight/.
