# 剧光灯 StageLight — Product Requirements Document v0.1

## Product Vision

Language-specific requirements and release criteria are defined in the [Localization PRD](LOCALIZATION_PRD.md).

This document retains the original v0.1 MVP baseline; its roadmap version numbers are historical planning labels. The current app supports private iCloud diary synchronization. Later feature requirements are explicitly marked below, including the proposed [Mini Theatre companion](specs/MINI_THEATRE_COMPANION.md).

StageLight is a personal theatre collection and diary for people who watch Broadway, Off-Broadway, West End, touring productions, plays, and musicals.

> 剧光灯不是告诉你有什么剧可以看，而是记住你这一生看过哪些剧。

> StageLight does not tell you what to watch. It remembers what you have seen.

The core unit is a **Performance**, not merely a Show. A Show is the enduring work; a Performance is the particular date, venue, cast, seat, and memory the user experienced. One Show can therefore have many Performances:

**Hamilton**

- August 24, 2026
- December 18, 2025
- May 2, 2024

## Product Differentiation & Apple Journal Positioning

StageLight is **not intended to replace or compete broadly with Apple Journal**.

Apple Journal is a general-purpose tool for remembering moments across a user's life. StageLight is a specialized system for understanding and preserving one specific part of that life: **theatre-going history**.

Our positioning is:

> **Apple Journal remembers moments. StageLight understands your theatre history.**

The distinction is important. A user can save a photo of a Playbill and write about the evening in a general-purpose journal. StageLight goes further by turning that moment into structured theatre data.

After a user photographs a Playbill, ticket, or theatre poster, StageLight should understand that the user **saw a specific performance of a specific show**, rather than merely storing a photograph.

For example:

```text
Hamilton
Richard Rodgers Theatre
September 8, 2026 · 7:00 PM
★★★★★
Orchestra · Row H · Seat 108
```

Over time, individual Performance records form a structured personal theatre history:

```text
YOUR STAGE

63 performances
47 shows
22 theatres

Hamilton
Seen 4 times

2024 · Richard Rodgers Theatre
2025 · Richard Rodgers Theatre
2026 · Richard Rodgers Theatre
2026 · Richard Rodgers Theatre

Favorite theatre
Richard Rodgers Theatre · 7 visits
```

### Core Differentiators

StageLight should provide theatre-specific capabilities that a general-purpose journal cannot naturally provide:

- Show and Performance as first-class entities
- Multiple viewings of the same Show
- Automatic Playbill, ticket, and poster recognition
- Structured theatre, date, time, and seat information
- Performance ratings
- Show-level viewing history
- Theatre visit history
- Personal theatre statistics
- Cast history in a future release
- Broadway Theatre Passport in a future release
- Annual theatre recap in a future release

The long-term value is therefore not the individual diary entry. It is the **structured dataset that emerges from years of theatre-going**.

### Camera-First Advantage

StageLight should minimize the effort required to create this structured history.

The ideal interaction is:

```text
Take Playbill photo
        ↓
Identify show
        ↓
Confirm performance
        ↓
Rate / optional note
        ↓
Add to Stage
```

The user should not need to consciously maintain a database or write a journal entry.

Their collection should emerge naturally from an action theatre-goers already perform: **taking a photo.**

This supports the MVP goal of completing the basic collection flow in approximately 10–15 seconds.

### Product Boundary

StageLight should not attempt to outperform Apple Journal in general-purpose journaling.

The following are explicitly not differentiation priorities:

- General life journaling
- Rich-text journaling
- Mood tracking
- Generic journaling prompts
- General memory suggestions
- General location history
- Generic media organization

When evaluating a new feature, the product team should ask:

> **Would a theatre-goer get something from this that a general-purpose journal cannot naturally provide?**

If the answer is no, the feature should generally not be prioritized.

This principle protects StageLight from becoming a generic diary application.

### Complementary Ecosystem

StageLight may eventually complement Apple Journal rather than replace it.

A future **Share to Journal** capability could generate a formatted theatre memory containing:

```text
Hamilton
Richard Rodgers Theatre
September 8, 2026
★★★★★
Orchestra · Row H · Seat 108
```

along with the user's selected photograph and personal note.

In this model:

**Apple Journal remains the user's life journal.**

**StageLight becomes the system of record for their theatre life.**

### Product Positioning

Avoid positioning StageLight primarily as a "theatre journal."

Preferred positioning:

> **StageLight — Your theatre collection.**

Supporting message:

> **Photograph a Playbill. Remember every performance.**

The core product distinction can be summarized as:

> **Apple Journal stores a photo of Hamilton. StageLight knows you saw Hamilton.**

This distinction should guide recognition, data modeling, collection design, statistics, and future product development.

## Product Principles

1. **Performance First.** Model and present each visit as a distinct experience. Repeat viewings are valuable history, not duplicates to collapse.
2. **Camera First.** Make a Playbill, marquee, ticket, or theatre photo the quickest starting point for adding a performance.
3. **Personal First.** Optimize for private memory-keeping rather than discovery, popularity, or social engagement.
4. **Visual First.** Let the user's photography carry the collection; use restrained interface chrome and editorial typography around it.
5. **AI Assists, User Confirms.** Recognition may prepare a draft, but the user reviews and explicitly saves every result. AI failure must never prevent manual entry.

## Target Users

### Primary: Frequent Theatre Goer

Typically sees 5–50+ performances per year, photographs Playbills, marquees, tickets, or theatres, cares about cast differences, may see the same show repeatedly, and wants a durable personal theatre history.

### Secondary: Casual Theatre Goer

Sees performances occasionally and wants an effortless, attractive record without maintaining a complex database.

## Core MVP User Stories

| Story | Acceptance criteria |
| --- | --- |
| Scan a performance | The user can capture a Playbill, ticket, or poster and start recognition from the resulting image. |
| Confirm AI recognition | Recognized fields appear in an editable draft; nothing persists until the user taps **Add to Stage**. |
| Add manually | The user can create a complete performance without AI or network access. |
| Add rating | The user can add or clear a rating from 0.5 to 5 stars in half-star increments. |
| Add notes | The user can save optional free-form notes with a performance. |
| Add multiple photos | The user can attach, reorder, view, and remove multiple local photos. |
| Browse Collection | The user sees a photo-led grid of shows, sorted by latest performance first. |
| View Show Detail | The user can see a show's count, average rating, and all of its performances. |
| View Performance Detail | The user can see every saved field and all photos for one performance. |
| Diary timeline | The user can browse performances newest first, grouped by year and month. |
| Search | The user can find records by show title or theatre. |
| Filter by year/rating | The user can narrow the collection or diary by year and rating and clear filters. |
| Profile stats | The user can view the defined lightweight collection statistics, including sensible empty states. |
| Edit | The user can edit an existing performance and either commit or cancel without partial changes. |
| Delete | The user can confirm deletion of a performance and its locally stored photos. |
| Duplicate warning | A same-title, same-day match produces a warning with choices to review or save anyway. |

## Main Navigation

The primary navigation is:

**Collection | Diary | + | Profile**

The centered **+** is an action rather than a content tab. It opens:

- Scan
- Choose from Photos
- Add Manually

Discover is not included in the MVP.

## Collection

Collection is the default home screen. It is a grid-based visual library in which each show item displays a cover photo, title, performance count, and the latest or representative rating. Shows sort by latest performance first by default.

## Show Detail

Show Detail aggregates every Performance belonging to one Show. It displays the show title, total performance count, average rating, and a chronological or reverse-chronological performance list. Repeat viewings remain visibly distinct.

## Performance Detail

Performance Detail displays the show, date, time, theatre, city, seat, rating, notes, and photos for one visit. The user can enter edit mode or delete the performance.

## Diary

Diary is the user's chronological theatre history. It groups performances by year and month and presents the newest entries first.

## Profile

Profile provides a restrained summary rather than a heavy analytics dashboard:

- show count
- performance count
- theatre count
- average rating
- performances this year
- most watched show
- favorite theatre

## First Launch

The onboarding sequence is:

1. **Your life on stage.** Introduce the private theatre diary.
2. **Scan your Playbill.** Demonstrate the fastest capture flow.
3. **Permissions.** Explain that camera and photo access are requested only when needed.

The initial empty state reads:

> Your stage is empty.

Primary CTA: **Add your first show**

## Data Model

The core relationship is **Show 1 → N Performance**.

### Show

- `id`
- `title`
- `normalizedTitle`
- `createdAt`

### Performance

- `id`
- `showId`
- `date`
- `time`
- `theatre`
- `city`
- `seat`
- `rating`
- `notes`
- `createdAt`
- `updatedAt`

### PerformancePhoto

- `id`
- `performanceId`
- `localIdentifier` or `filename`
- `sortOrder`
- `createdAt`

Photo files live in application storage; SwiftData stores only their metadata.

## Duplicate Handling

Before saving, check for the same normalized show title on the same calendar day. A match produces a warning but does not block saving because matinee and evening performances can legitimately occur on the same day.

## AI Recognition

Recognition accepts an image. Device date may optionally help contextualize a request; location may be considered in future versions. A result has a validated structure such as:

```json
{
  "showTitle": "Hamilton",
  "theatre": "Richard Rodgers Theatre",
  "date": "2026-08-24",
  "time": "19:00",
  "confidence": 0.96
}
```

AI results always become editable drafts. AI never auto-saves.

## Privacy

The MVP is private by default. It has no public profile, social feed, or follower graph, and theatre history is never sold. Camera and photo permissions are requested only at the moment their features require them.

## Offline Behavior

Offline use must support Collection, Diary, Profile, Show Detail, Performance Detail, Manual Add, edit, delete, rating, notes, and photo viewing. AI recognition may require a network connection; its absence must lead cleanly to manual entry.

## Persistence

StageLight v0.1 is local-first and uses SwiftData for metadata. It has no CloudKit synchronization and no user account.

## Out of Scope for MVP

- social feed
- followers
- likes
- comments
- public profiles
- recommendations
- ticket purchasing
- Ticketmaster integration
- TodayTix integration
- full cast database
- actor profiles
- Stage Passport
- achievements
- widgets
- Apple Watch
- Android
- web app
- advanced analytics
- yearly wrapped

## Post-MVP Roadmap

- **v0.2 — Metadata:** richer production, venue, and artwork metadata
- **v0.3 — Cast history:** record and compare casts across performances
- **v0.4 — Stage Passport:** place-based theatre history and venue collection
- **v0.5 — Sharing:** deliberate, user-controlled sharing of selected memories
- **v1.0 — Yearly theatre wrap-up:** an editorial retrospective of the user's year

## Success Metrics

The optional Mini Theatre experiment does not authorize adding remote behavioral analytics to collect these metrics.

- **Activation:** percentage of new users who save their first Performance
- **Collection depth:** performances saved per activated user
- **Scan success:** scans that yield a useful draft and proceed to save
- **Time to save:** median time from starting Add to completing a Performance
- **Return behavior:** users who return to view or add to their history

**North Star: Performances Collected**

## Optional Mini Theatre Companion

Status: implemented on the feature branch, October 18, 2026; not approved for release. Separate from Theatre Passport. Uses the selected cream-and-gold lop-eared bunny and six original props. See the feature spec and QA notes for verification status.

### Purpose and scope

Let theatre memories gradually furnish a small, original theatre scene with a companion, provisionally named 小剧灯. Gentle companionship may make revisiting memories more enjoyable; improved retention is a hypothesis to validate through voluntary feedback, not a promise or a reason to introduce tracking.

First release: one original character, an optional nickname, six original props, three equipment slots, one skippable theatre-specific reflection prompt, and one preview-first share card. Support English, Simplified Chinese, Traditional Chinese, Japanese, iPhone, and iPad.

Default off. Explicit activation lives in Profile; a collapsible Collection shortcut is separately optional. Preserve existing navigation and the fast diary save flow. Do not reserve a third of the home screen for the companion.

### User stories and acceptance

| Story | Required behavior |
| --- | --- |
| Ignore the companion | No evaluation, prompts, notification permissions, or extra save step while disabled. |
| Activate with an existing diary | Reconcile past records and show one reward summary, not a chain of popups. |
| Earn a keepsake | Deterministic milestones; manual entry, scanning, and backfilled memories have equal eligibility. AI genre classification is not required. |
| Avoid repeated rewards | One permanent grant per milestone, regardless of edits, extra photos, callbacks, or relaunch. |
| Keep control of records | Deleting or editing a diary never revokes earned props. Rewards cannot restore deleted diary data. |
| Recover from an error | Reward-store failure cannot fail or roll back diary saving; retry without resetting either store. |
| Decorate | Equip only unlocked, slot-compatible props and persist the selection locally. |
| Reflect | A skippable theatre-specific prompt opens the existing note editor; no overwriting, minimum length, sentiment analysis, or note-based reward. |
| Take a break | No hunger, sadness penalty, broken streak, expiry, or guilt-based language. |
| Share | Preview only the original character and equipped stage with app icon and Made with StageLight; exclude nickname and all diary content by default. |
| Disable | Hide companion UI and stop evaluation, retain progress, and reconcile on re-enabling. |

### Privacy and durability

Keep the existing diary schema and private iCloud configuration unchanged. Companion state lives in a separate device-local store, without cross-store relationships. Local-first does not mean the diary never syncs.

Reflection disclosure: “内容保存在你的设备上，并可能通过你的私人 iCloud 同步。不会用于公开展示。” Never claim existing notes stay off cloud. Explain that first-release companion progress and equipment do not sync between devices. Reinstall recovery is not guaranteed: remaining diary records can reconstruct eligible milestones, but grants based on deleted records and equipment choices may not be recoverable.

### Boundaries and validation

No coins, shop, purchases, random reward pool, leaderboards, viewing streaks, or pressure to buy tickets. Use original artwork rather than copying another product's mascot, UI, or production-specific assets. Timed exploration, widgets, Live Activities, show-specific rewards, venue aliases, and cross-device companion sync are deferred.

Reduce Motion, VoiceOver, Dynamic Type, and optional haptics are release requirements. Validate enjoyment, discoverability, and comfort through voluntary feedback without a telemetry SDK or automatic diary activity export. The [technical and test specification](specs/MINI_THEATRE_COMPANION.md) defines release gates; this proposal is not evidence that implementation or testing is complete.

## MVP Definition of Done

- [ ] Onboarding and the first empty state are complete.
- [ ] Users can scan, choose a photo, or add manually.
- [ ] Recognition creates an editable draft and never auto-saves.
- [ ] AI and network failure offer manual entry without data loss.
- [ ] Users can save a Performance with its Show, date, venue, seat, rating, notes, and multiple photos.
- [ ] Duplicate detection warns without blocking.
- [ ] Collection, Show Detail, Performance Detail, Diary, search, and filters work with persisted data.
- [ ] Profile displays all MVP statistics and appropriate empty states.
- [ ] Edit commits atomically; cancel preserves the original.
- [ ] Delete removes the Performance and associated photo files after confirmation.
- [ ] All non-recognition flows work offline and survive app restarts.
- [ ] Accessibility, permission messaging, and error states meet the design specification.
- [ ] The end-to-end build is stable enough for TestFlight distribution.
