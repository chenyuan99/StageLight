# 剧光灯 StageLight — MVP Test Plan v0.1

## Purpose

This plan defines how StageLight's iOS MVP will be verified before TestFlight. It translates the product requirements, UX decisions, and technical specification into observable tests so implementation can proceed against clear behavior rather than informal expectations.

The plan follows a test-first workflow:

1. define expected behavior and acceptance criteria;
2. add the smallest relevant automated test when a test target exists;
3. confirm the new test fails for the intended reason;
4. implement only enough production code to satisfy the behavior;
5. refactor while keeping the suite green;
6. complete device, accessibility, and exploratory checks where automation is insufficient.

## Quality Goals

The MVP is ready for TestFlight when it is trustworthy as a private personal archive. The test strategy prioritizes:

- no loss or corruption of saved performances;
- reliable offline access to all non-recognition features;
- explicit user confirmation before recognized data is saved;
- correct Show 1 → N Performance behavior, including repeat viewings;
- safe photo-file lifecycle management;
- recoverable recognition and network failures;
- responsive browsing at the target collection size;
- accessible core flows with native iOS behaviors.

## Scope

### In Scope

- onboarding and first-launch state
- Collection, Diary, Profile, Show Detail, and Performance Detail
- Scan, Choose from Photos, and Add Manually entry points
- recognition result review and fallback to manual entry
- performance draft validation and persistence
- multiple photos and thumbnail loading
- rating, notes, seat, venue, date, and time
- search and year/rating filters
- edit, cancel, delete, and duplicate warning behavior
- local SwiftData persistence and file storage
- offline behavior
- Dynamic Type, VoiceOver, touch targets, and Reduce Motion
- privacy-sensitive logging and permission timing
- performance at 1,000 performances and 5,000 photos

### Out of Scope

The MVP test suite does not cover social features, accounts, CloudKit, sync, recommendations, ticket purchasing, cast databases, Stage Passport, achievements, widgets, Apple Watch, Android, web, advanced analytics, or yearly wrap-up. Tests for AI-provider model quality beyond the app's request, validation, and fallback behavior belong to a separate service evaluation plan.

## Source of Truth and Requirement Priority

When requirements conflict, resolve them in this order:

1. `PRD.md` defines product behavior and MVP scope.
2. `DESIGN.md` defines UX, copy, visual direction, and accessibility intent.
3. `TECHNICAL_SPEC.md` defines architecture and implementation constraints.
4. This test plan defines verification but does not silently expand product scope.

Any unresolved conflict blocks the affected test from becoming a release gate until the source document is clarified.

## Test Levels

| Level | Purpose | Primary tools | Expected cadence |
| --- | --- | --- | --- |
| Unit | Pure rules, state transitions, validation, ViewModel behavior, and error mapping | XCTest | Every change |
| Integration | SwiftData relationships, repository transactions, file lifecycle, and service boundaries | XCTest with in-memory stores and temporary directories | Every pull request |
| UI | Critical user journeys, navigation, persistence through relaunch, and visible recovery paths | XCUITest | Every pull request for affected flows; full suite before release |
| Accessibility | Semantic labels, reading order, Dynamic Type, Reduce Motion, contrast, and touch targets | Accessibility Inspector, XCUITest, manual device checks | Feature completion and release candidate |
| Performance | Grid scrolling, thumbnail decoding, launch, large datasets, and memory behavior | XCTest metrics, Instruments | Milestones and release candidate |
| Exploratory | Photography variation, interruption recovery, layout polish, and real-device behavior | Manual charters | Feature completion and release candidate |

## Test Environments

### Supported Runtime Matrix

At minimum, verify:

| Environment | Purpose |
| --- | --- |
| Latest available iOS 18 simulator, standard-size iPhone | Primary automated suite |
| iOS 18 simulator, smallest supported screen | Compact layout and Dynamic Type pressure |
| iOS 18 simulator, largest supported iPhone | Gallery and editorial layout |
| Physical iPhone on iOS 18+ | Camera, permission, photo quality, memory, and interruption checks |
| Light and Dark Mode | Semantic color and photo-surface verification |
| Airplane Mode or disabled network | Offline and recognition fallback checks |

Run release-candidate smoke tests against the Xcode and iOS SDK versions intended for TestFlight submission. Record exact versions in the test report rather than freezing them in this plan.

### Test Configurations

- in-memory SwiftData for isolated unit and repository tests;
- disk-backed temporary SwiftData for restart and migration-oriented tests;
- temporary `PhotoStore` root for file tests;
- deterministic clock, calendar, locale, and UUID providers where dates or identifiers affect behavior;
- mock recognition service for success, partial, low-confidence, malformed, timeout, offline, and cancellation results;
- generated image fixtures with known orientation and dimensions;
- UI-test launch arguments for empty, seeded, offline, permission, and large-library states.

Production credentials and live personal theatre data must never be required for automated tests.

## Test Data

Use synthetic fixtures that exercise real product behavior:

- one Show with one Performance;
- one Show with repeat Performances across several years;
- two performances of the same show on the same day at matinee and evening times;
- similar but non-identical show titles;
- missing time, theatre, seat, rating, notes, and photos;
- ratings at `0.5`, `5.0`, and unrated;
- multiline notes and non-Latin text;
- long show and theatre names;
- multiple photos with portrait, landscape, rotated, and high-resolution sources;
- records around midnight, month boundaries, year boundaries, daylight-saving transitions, and locale changes;
- a scale library of 1,000 performances and 5,000 photo metadata entries.

Fixtures must not contain real tickets, API keys, private notes, or copyrighted promotional images unless explicitly licensed for testing.

## Automation Design Rules

- Test behavior through public feature boundaries rather than private implementation details.
- Give each test one primary reason to fail.
- Use descriptive names in the form `test_action_condition_expectedResult`.
- Avoid arbitrary sleeps; wait for observable state or accessibility identifiers.
- Keep unit tests deterministic and free of network, camera, and shared file-system dependencies.
- Reset isolated stores between tests and delete temporary photo directories in teardown.
- Do not weaken assertions to accommodate flaky behavior; remove the source of nondeterminism.
- Assign stable accessibility identifiers only where XCUITest cannot select semantically.
- A failing release-gate test cannot be ignored without a documented owner, reason, and expiry.

## Unit Test Coverage

### Title Normalization and Show Matching

- `Hamilton`, ` HAMILTON `, and `hamilton` normalize to `hamilton`.
- Leading and trailing whitespace is removed.
- Case differences do not create separate Shows.
- Different normalized strings remain separate; semantic aliases are not inferred.
- Empty or whitespace-only titles fail draft validation.

### Duplicate Detection

- Matching normalized title and local calendar day returns `possible(existing:)`.
- Different titles on the same day return `none`.
- The same title on different calendar days returns `none`.
- Matinee and evening times on the same day still produce a warning.
- Calendar and time-zone injection make day comparisons deterministic.
- Choosing save anyway proceeds without modifying the existing Performance.

### PerformanceDraft

- A valid manual draft can be converted into persistable values.
- Required-field errors are field-specific and recoverable.
- Optional time, theatre, city, seat, rating, notes, and photos remain optional as defined by the product flow.
- Rating rejects values outside 0.5–5.0 and unsupported increments.
- Editing a draft does not mutate its source Performance.
- Cancel discards draft changes.
- Save updates `updatedAt` once and preserves `createdAt`.

### Add Performance State Machine

- Source selection enters camera, photo picker, or manual editing through valid transitions.
- Captured or selected images enter processing.
- Successful recognition enters result review and never saving directly.
- Editing a recognized result preserves recognized fields and user corrections.
- Recognition failure enters a recoverable failure state with manual entry available.
- Cancellation cannot leave the state machine stuck in processing or saving.
- Repeated completion actions cannot save the same draft twice.

### Recognition Mapping and Validation

- Complete valid JSON maps to the expected draft fields.
- Partial results leave absent fields editable and do not invent values.
- Invalid dates, times, confidence values, and unexpected types are rejected safely.
- Low confidence changes presentation copy but does not expose a numeric percentage.
- Service timeout, cancellation, offline, server, and decoding errors map to distinct recoverable states.
- Recognition output never invokes persistence without explicit user intent.

### Search and Filters

- Search matches show title and theatre using trimmed, lowercased `localizedStandardContains` behavior.
- Empty search returns the unfiltered result set.
- Year and rating filters return only matching performances.
- Combined search and filters use the defined intersection behavior.
- Clearing filters restores default results and latest-performance sorting.
- Long and non-Latin queries do not crash or corrupt state.

### Collection and Profile Derivations

- Collection sorts Shows by their latest Performance descending.
- Show count counts unique Shows; Performance count counts visits.
- Theatre count handles empty names and normalized duplicates consistently.
- Average rating excludes unrated performances.
- Performances this year uses the injected calendar.
- Most watched show and favorite theatre handle ties deterministically.
- Empty data produces zero/empty-state values without division errors.

### Rating Accessibility

- Increment and decrement actions move in 0.5-star steps.
- Values clamp to the supported range.
- Clear returns to unrated.
- Accessibility labels and values describe the current rating without relying on color.

## Integration Test Coverage

### SwiftData Relationships

- Saving the first Performance creates one Show and links both sides of the relationship.
- Saving a repeat viewing reuses the normalized Show and increases its Performance count.
- Fetching after a new model context reproduces all committed metadata.
- Show Detail returns every related Performance in the requested order.
- Deleting a Show cascades to its Performance and photo metadata only when explicitly requested by supported repository behavior.
- No orphan Performance or PerformancePhoto metadata remains after supported operations.

Use `ModelConfiguration(isStoredInMemoryOnly: true)` for most relationship tests and a temporary disk-backed store for relaunch persistence tests.

### PhotoStore

- Save normalizes orientation.
- Images larger than 2,400 px on the long edge are resized; smaller images are not upscaled.
- Saved output is a readable JPEG at approximately the configured quality.
- Generated filenames are unique and contain no unsafe path traversal.
- Load returns the correct image for a valid filename.
- Missing and corrupt files produce typed errors rather than crashes.
- Delete removes only the requested file and is safely handled when the file is absent.
- Concurrent saves do not collide or corrupt output.

### Save Transaction

- A successful save commits metadata and all photo references once.
- A model save failure cleans up newly written files.
- A photo processing failure leaves no persisted Performance.
- Retrying after a recoverable failure produces one Performance, not duplicates.
- AI failure does not affect manual draft persistence.

### Edit Transaction

- Saving edited metadata commits all changes together.
- Cancel leaves model and photo files untouched.
- Newly added photos become durable only after commit.
- Removed photos are deleted after a successful commit.
- A failed edit preserves the original record and recoverable photo state.

### Delete Transaction

- Deleting a Performance removes its photo files, photo metadata, and Performance.
- Its parent Show remains when another Performance exists.
- Its parent Show is deleted when no Performances remain.
- Partial file-deletion failure is surfaced and can be retried without deleting unrelated files.
- Collection, Diary, Profile, and navigation state refresh after deletion.

### Thumbnail Cache

- A cache miss loads and decodes a display-sized thumbnail off the main actor.
- A cache hit avoids repeated full-image decoding.
- Cache eviction does not affect original files.
- Reused grid cells cannot display a stale thumbnail from another Show.
- Corrupt or missing photos produce a stable placeholder.

## Critical UI Journeys

Each critical journey must pass on the primary simulator and be smoke-tested on a physical iPhone.

### UI-01 — First Launch and Manual Add

**Given** a fresh install<br>
**When** the user completes the three onboarding screens and taps **Add your first show** → **Add Manually**<br>
**Then** the user can enter a show title and date, save once, and see the new Show in Collection and Performance in Diary.

Additional checks:

- onboarding does not reappear after relaunch;
- permission prompts are not shown before the related feature is chosen;
- empty-state and CTA copy match the design document.

### UI-02 — Scan, Confirm, and Save

**Given** camera permission and a mock successful recognition result<br>
**When** the user scans an image<br>
**Then** loading reads **Finding your show…**, the editable result reads **We found your show**, and no record exists before **Add to Stage** is tapped.

Additional checks:

- recognized fields match the mock result;
- the user can correct every recognized field;
- raw confidence is never visible;
- exactly one record is saved after confirmation.

### UI-03 — Recognition Failure Fallback

**Given** recognition is offline or fails<br>
**When** the user attempts a scan or photo recognition<br>
**Then** the app explains that recognition is unavailable and offers **Add Manually** while retaining useful draft/photo context.

### UI-04 — Choose from Photos

**Given** the user opens the add sheet<br>
**When** the user chooses one or more photos through `PhotosPicker`<br>
**Then** only selected items are imported, the user can review or edit the draft, and broad photo-library permission is not unnecessarily requested.

### UI-05 — Repeat Viewing and Duplicate Warning

**Given** Hamilton already has a saved performance on a date<br>
**When** another Hamilton performance is added on the same date<br>
**Then** the app warns without blocking, and **Save Anyway** adds a second Performance under the same Show.

### UI-06 — Browse Collection and Show Detail

**Given** several Shows and repeat Performances<br>
**When** Collection opens<br>
**Then** its two-column grid sorts by latest Performance, displays photo/title/count/rating, and opens a Show Detail containing all related visits.

### UI-07 — Performance Detail, Edit, and Cancel

**Given** a saved Performance<br>
**When** the user edits fields and cancels<br>
**Then** the detail remains unchanged; when the user repeats the edit and saves, all intended changes appear together after relaunch.

### UI-08 — Delete

**Given** a Show with one Performance and photos<br>
**When** the user chooses delete and confirms<br>
**Then** the app returns to a valid destination, the Show disappears, counts update, and the deleted item stays absent after relaunch.

Cancellation must leave the record untouched.

### UI-09 — Diary

**Given** Performances across multiple years and months<br>
**When** Diary opens<br>
**Then** entries are newest first, grouped by year and month, and each row opens the correct Performance Detail.

### UI-10 — Search and Filters

**Given** a seeded library<br>
**When** the user searches by show or theatre and applies year/rating filters<br>
**Then** only matching results remain, empty results are helpful, and clearing restores the default collection.

### UI-11 — Profile

**Given** a known seeded library<br>
**When** Profile opens<br>
**Then** show, performance, theatre, average rating, current-year, most-watched-show, and favorite-theatre values exactly match the fixture.

The screen must remain editorial rather than presenting a dense dashboard.

### UI-12 — Offline Relaunch

**Given** previously saved records and no network<br>
**When** the app launches<br>
**Then** Collection, Diary, Profile, Show Detail, Performance Detail, Manual Add, edit, delete, rating, notes, and photo viewing remain usable.

## Permission and Interruption Tests

Verify each authorization state: not determined, allowed, denied, and restricted where the system supports it.

- Camera permission is requested only after choosing Scan.
- Denial produces useful guidance and manual/photo alternatives.
- PhotosPicker remains the preferred scoped path.
- Location is never requested in the MVP.
- Returning from Settings refreshes relevant state.
- Incoming call/backgrounding, app suspension, memory pressure, and camera cancellation do not create partial records.
- Relaunch during an uncommitted draft does not fabricate saved data.

## Accessibility Test Plan

### Dynamic Type

Test default, a large accessibility size, and the largest accessibility size on the smallest supported screen. Essential text and actions must remain available without clipping or horizontal scrolling. Layouts may reflow from columns to stacks.

### VoiceOver

Verify:

- meaningful labels for show photos, ratings, counts, and buttons;
- logical reading order across Collection cards, timelines, forms, and details;
- correct traits for headings, buttons, selected filters, and adjustable ratings;
- no duplicate reading of decorative content;
- recognition loading and error changes are announced appropriately;
- destructive confirmation clearly names the affected Performance.

### Interaction and Visual Access

- Interactive targets are at least 44 × 44 pt.
- Focus does not become trapped in sheets or camera overlays.
- State and validation are not communicated by color alone.
- Text and controls retain sufficient contrast in Light and Dark Mode and over images.
- Reduce Motion substitutes restrained fades for spotlight/reveal movement without losing meaning.

## Performance and Scale Tests

Seed 1,000 Performances and metadata for 5,000 photos. Use generated local fixtures and thumbnails rather than downloading external assets.

Measure and record:

- cold and warm launch to usable Collection;
- Collection initial render and sustained scroll responsiveness;
- Diary grouping and scroll behavior;
- search/filter response time;
- Show Detail load for the most-watched Show;
- thumbnail cache hit/miss behavior;
- peak memory while rapidly scrolling photo grids;
- save/edit/delete duration with multiple photos;
- absence of synchronous original-image decoding on the main thread.

Exact numeric release thresholds should be baselined on the oldest supported physical device once implementation exists. Until then, regressions, hangs, out-of-memory termination, and visibly dropped interaction responsiveness are release blockers.

## Privacy and Security Checks

- No API keys exist in source, built resources, screenshots, or logs.
- Production recognition requests route through the approved stateless backend/proxy.
- Logs do not contain images, notes, seat details, full recognition payloads, or personal collection data.
- File access is contained within the configured photo directory.
- Unsafe or malformed filenames cannot escape that directory.
- Recognition response data is treated as untrusted and validated before presentation.
- No account, public profile, analytics sale, follower graph, or social upload exists in the MVP.
- Deleting a Performance removes its associated local photo files as specified.

## Localization Checks

- User-visible strings are sourced from `Localizable.xcstrings`.
- Dates, times, numbers, plurals, and ratings use locale-aware formatting.
- English-first UI tolerates Chinese show titles, theatre names, city names, and notes.
- Long translated strings do not break essential layouts.
- Title normalization behavior is deterministic for the supported input set.

## Exploratory Charters

### Real Theatre Artifacts

Try varied Playbills, tickets, posters, marquees, glare, low light, rotation, cropping, typography, handwritten details, and partial obstruction. Evaluate whether failure recovery remains understandable, not merely recognition accuracy.

### Memory Revisit

Seed a visually rich multi-year library and navigate it as a returning user. Look for incorrect grouping, stale counts, visual monotony, lost scroll context, unclear repeat viewings, and interactions that feel like database maintenance rather than a personal archive.

### Failure and Recovery

Interrupt capture, cancel pickers, background during processing, simulate timeouts, corrupt a test photo, exhaust temporary disk space, and retry saves/deletes. Confirm that the user never sees a false success or loses an already committed record.

### Visual Polish

Compare Light/Dark Mode, image aspect ratios, empty/loading/error/content states, keyboard presentation, sheets, navigation transitions, and Reduce Motion. Check adherence to the quiet editorial direction and prohibited visual clichés.

## Test Case Traceability

| Product capability | Primary automated coverage | Manual or specialized coverage |
| --- | --- | --- |
| Onboarding / first launch | UI-01, `@AppStorage` state tests | fresh-install device check |
| Scan and recognition | state-machine and mapping unit tests, UI-02 | real camera and artifacts |
| Recognition fallback | error-mapping unit tests, UI-03 | airplane mode and interruption |
| Manual/photo add | draft and transaction tests, UI-01/UI-04 | picker permission behavior |
| Repeat viewing / duplicates | normalization and duplicate unit tests, UI-05 | matinee/evening copy review |
| Collection / Show Detail | derivation tests, UI-06 | grid polish and scale |
| Performance Detail / edit | edit transaction tests, UI-07 | keyboard and long-note layout |
| Delete | delete integration tests, UI-08 | partial file-failure recovery |
| Diary | grouping tests, UI-09 | timeline visual review |
| Search / filter | query unit tests, UI-10 | locale and large-data checks |
| Profile | statistics unit tests, UI-11 | editorial layout review |
| Offline | mock service tests, UI-12 | physical-device airplane mode |
| Photos | PhotoStore/cache integration tests | image quality and memory |
| Accessibility | semantic UI assertions where practical | VoiceOver, Dynamic Type, contrast, Reduce Motion |
| Privacy/security | validation and path-safety tests | source, build, and log audit |

## CI Gates

Once the Xcode project exists, continuous integration should:

1. build the app and test targets with warnings visible;
2. run deterministic unit tests;
3. run integration tests with isolated storage;
4. run the critical UI smoke suite on one supported iOS 18 simulator;
5. collect `.xcresult` artifacts and screenshots for failures;
6. fail on any test failure, crash, build error, or committed secret finding.

The broader device, accessibility, performance, and exploratory matrix remains a release-candidate gate rather than an every-commit CI burden.

## Defect Severity

| Severity | Definition | Examples |
| --- | --- | --- |
| S0 — Critical | Security/privacy breach or widespread irreversible data loss | exposed production key, saved library destroyed |
| S1 — High | Core journey blocked, committed data lost, or app crashes in normal use | cannot save manually, delete removes wrong photos |
| S2 — Medium | Important behavior incorrect with a reasonable workaround | wrong sort order, filter combination error |
| S3 — Low | Localized polish or minor inconsistency | nonessential spacing or copy mismatch |

S0 and S1 defects block all distribution. S2 blocks the release candidate unless explicitly triaged with a bounded fix plan. S3 may be deferred when it does not undermine accessibility or trust.

## Entry Criteria

A feature enters formal verification when:

- its relevant PRD acceptance criteria are stable;
- UX states and copy are defined;
- dependencies can be injected or mocked;
- test fixtures and accessibility identifiers are available;
- the app builds without unrelated failures.

For test-first implementation, unit-level examples may be authored before production types exist and are expected to fail to compile or fail assertions until the smallest implementation slice is introduced.

## Exit Criteria

The MVP can be proposed for TestFlight when:

- all core user stories have passing acceptance coverage;
- all automated unit, integration, and critical UI tests pass;
- the offline relaunch journey passes on a physical device;
- no open S0 or S1 defects remain;
- no unapproved S2 defects remain;
- accessibility checks pass for every core flow;
- scale testing shows no crash, hang, or unacceptable interaction regression;
- camera, photo, and denial/recovery paths pass on a physical device;
- privacy, logging, file-path, and secret audits pass;
- a release-candidate exploratory session is complete;
- the build distributed to internal TestFlight matches the tested commit.

## MVP Test Definition of Done

- [ ] Test targets use XCTest/XCUITest and run independently of live services.
- [ ] In-memory SwiftData, mock recognition, deterministic time/calendar, and temporary PhotoStore helpers are available.
- [ ] Normalization, duplicate detection, draft validation, statistics, search/filter, state transitions, and error mapping have unit coverage.
- [ ] Save, edit, delete, relationship, restart persistence, photo lifecycle, and thumbnail behavior have integration coverage.
- [ ] UI-01 through UI-12 pass on the primary simulator.
- [ ] Critical camera, permission, offline, interruption, and relaunch paths pass on a physical iPhone.
- [ ] Dynamic Type, VoiceOver, 44 pt targets, contrast, and Reduce Motion are verified.
- [ ] The 1,000-performance / 5,000-photo scale library is exercised without crashes or main-thread image decoding.
- [ ] No committed secrets or private content appear in source, resources, fixtures, or logs.
- [ ] All release-blocking defects are resolved and results are recorded against the release commit.
