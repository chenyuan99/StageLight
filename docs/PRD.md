# 剧光灯 StageLight — Product Requirements Document v0.1

## Product Vision

StageLight is a personal theatre collection and diary for people who watch Broadway, Off-Broadway, West End, touring productions, plays, and musicals.

> 剧光灯不是告诉你有什么剧可以看，而是记住你这一生看过哪些剧。

> StageLight does not tell you what to watch. It remembers what you have seen.

The core unit is a **Performance**, not merely a Show. A Show is the enduring work; a Performance is the particular date, venue, cast, seat, and memory the user experienced. One Show can therefore have many Performances:

**Hamilton**

- August 24, 2026
- December 18, 2025
- May 2, 2024

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

- **Activation:** percentage of new users who save their first Performance
- **Collection depth:** performances saved per activated user
- **Scan success:** scans that yield a useful draft and proceed to save
- **Time to save:** median time from starting Add to completing a Performance
- **Return behavior:** users who return to view or add to their history

**North Star: Performances Collected**

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
