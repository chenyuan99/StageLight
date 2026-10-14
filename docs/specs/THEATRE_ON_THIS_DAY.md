# Theatre on This Day / 剧场的今天

Status: implementation specification, 2026-10-13. Branch: feature/theatre-on-this-day.

## Purpose

Give theatre fans a small, trustworthy reason to revisit StageLight and share theatre history even when they have not attended a new performance. This is optional editorial content, not part of the user's attendance record.

## First usable version

- Collection shows a compact “Theatre on This Day” entry, including for an empty library. A Profile switch hides the Collection entry; a Profile link keeps the archive accessible. The preference is local and defaults on.
- The history screen shows the user's current local Gregorian date and events matching its month/day. It refreshes when the app becomes active and across midnight. Dates with no verified entry explicitly say so; unrelated events are never labeled as today's history.
- A separate “Browse history” section lists the complete starter catalog. This makes sparse editorial coverage transparent and useful. Entries identify the event as a Broadway opening, not a world premiere.
- An event detail shows the original show title, localized event label and short original summary, full date, venue, and a tappable source. English, Simplified Chinese, Traditional Chinese and Japanese are supported. Missing editorial translations fall back to English with a visible notice.
- Share opens a card preview with portrait (1080×1350) and story (1080×1920) formats. The original typographic card includes show, historical date, event type, venue, source credit, the app icon and “Made with StageLight”. A toggle includes the App Store URL in the system share payload. Reuse the existing image-sharing and Save to Photos activity; do not introduce another Photos callback implementation.
- iPhone and iPad use bounded, scrollable content, multiline titles and accessible controls. Cards use fixed export geometry independently of preview size.

## Editorial scope and safeguards

Start with five sourced examples: Wicked, Hamilton, The Phantom of the Opera, Death of a Salesman, A Raisin in the Sun. Sources are IBDB / The Broadway League. Store exact opening dates and original, concise factual summaries; no copied article text, posters, logos, production photographs or lyrics. Source links are not permission to reuse artwork.

The starter catalog is a reviewable feature, not a claim of daily coverage. Before marketing it as a daily destination, expand to 60–100 independently checked events, including non-Broadway and Asian theatre. Review translations and source links editorially. No AI-generated fact may publish automatically.

Source checks performed 2026-10-13 (dates below are Broadway openings, not necessarily world premieres):

| Work | Opening | Source |
| --- | --- | --- |
| Wicked | 2003-10-30 | https://www.ibdb.com/broadway-production/wicked-13485 |
| The Phantom of the Opera | 1988-01-26 | https://www.ibdb.com/broadway-production/the-phantom-of-the-opera-4491 |
| Hamilton | 2015-08-06 | https://www.ibdb.com/broadway-production/hamilton-499521 |
| Death of a Salesman | 1949-02-10 | https://www.ibdb.com/broadway-production/death-of-a-salesman-2111 |
| A Raisin in the Sun | 1959-03-11 | https://www.ibdb.com/broadway-production/a-raisin-in-the-sun-2083 |

## Data and architecture

Bundled `theatre-history.json`: schemaVersion, revision, and events. Each event has a stable id, year/month/day, original title, venue, HTTPS source URL, source name, and localized heading/summary in en, zh-Hans, zh-Hant, ja. Content is an immutable Codable value, separate from SwiftData.

`TheatreHistoryCatalog` validates the entire document: supported schema, positive revision, unique/nonempty IDs, real Gregorian dates (including leap days), nonempty English fallback, allowed translation keys, bounded text lengths, and HTTPS sources. Invalid input fails closed. Loading errors show a recoverable content-unavailable message, not a crash or fake empty day.

Date matching receives an injected Date and TimeZone. Compare Gregorian local month/day and exclude events whose year is not earlier than the current year. Stable sort by historical date then ID. February 29 does not silently move to February 28. Calendar calculations do not depend on the user's preferred non-Gregorian calendar.

Views depend only on public catalog values. No migration, delete, rewrite, record creation, personal-library upload, network request, or CloudKit mutation is required. Existing performances, notes and photos remain untouched. The toggle uses a new preference key only.

No remote publishing backend in this iteration. Corrections ship through an app update. A later remote feed must validate before atomic cache replacement, reject downgrades, retain last-known-good content and support withdrawn IDs. Do not silently activate a draft URL. This keeps first-version behaviour deterministic and offline.

## Tests first

Write and run unit tests before production types exist, record the expected red build, then implement and iterate. Cover bundled data, invalid schema/revision/IDs/dates/URLs/translations, exact date matches, time-zone boundaries, future events, leap day, deterministic ordering, locale mapping and fallback, four-language content, and card output dimensions/branding. Test data must be synthetic where edge cases are artificial.

UI checks: Collection entry with empty diary; browse/detail/source; card preview and share activity; optional entry hidden without affecting diary; English and Chinese flows; iPhone and iPad screenshots. Existing unit suite must remain green. Review screenshots for clipped titles, oversized images, low contrast and inaccessible actions.

## Acceptance and review

- [x] Issue and spec created before implementation
- [x] New tests observed red, then green
- [x] All five events have exact dates, source URLs and four-language summaries
- [x] No-event day is honest and archive remains accessible
- [x] Optional entry setting works without changing user data
- [x] Exported cards have correct dimensions, sources and branding
- [x] Simulator screenshots captured for owner review
- [x] Existing unit regression suite passes
- [ ] Owner design/content review before release

Out of scope: notifications, advertisements, analytics/tracking, personal-history matching, favorites sync, generated historical facts, arbitrary web scraping, remote feed, QR/deep-link pages, automatic release. No public release or App Store changes are part of this task.
