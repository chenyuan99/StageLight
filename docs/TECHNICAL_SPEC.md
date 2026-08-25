# 剧光灯 StageLight — Technical Specification v0.1

## Platform and Stack

| Area | Decision |
| --- | --- |
| Platform | iOS 18+ |
| Language | Swift 6 |
| UI | SwiftUI |
| Persistence | SwiftData |
| Architecture | MVVM + lightweight repository/service layer |
| Networking | URLSession |
| Photo input | PhotosUI, AVFoundation |
| Local OCR | Vision |
| Logging | OSLog |
| Photo file storage | FileManager |
| Testing | XCTest |

The MVP should have no third-party dependencies unless a clear, unavoidable requirement emerges.

## Technical Goals

- Remain fully usable offline except for remote recognition.
- Require no login or account lifecycle.
- Preserve all committed data across app restarts.
- Ensure AI failure never blocks manual save.
- Scale smoothly to at least 1,000 performances and 5,000 photos.
- Preserve a practical path to future CloudKit migration.
- Never store photo binary data in SwiftData.

## Architecture

```text
SwiftUI Views
    ↓
ViewModels
    ↓
Repositories / Services
    ↓
SwiftData + File Storage
```

Recognition follows a separate service boundary:

```text
ViewModel
    ↓
RecognitionService
    ↓
RecognitionClient
    ↓
Remote AI API
```

Views render state and send user intent. ViewModels own presentation state and orchestration. Repositories isolate persistence queries and transactions; services isolate photos, recognition, OCR, and other external effects. Protocol boundaries keep these collaborators replaceable in tests and future migrations.

## Project Structure

```text
StageLight/
  App/
  Models/
  Data/
  Services/
  Features/
    Onboarding/
    Collection/
    AddPerformance/
    ShowDetail/
    PerformanceDetail/
    Diary/
    Profile/
  DesignSystem/
  Utilities/
  Resources/
```

Organize by feature for user-facing code and by capability for shared infrastructure. Avoid premature modularization into separate packages during the MVP.

## SwiftData Models

The following code illustrates the intended schema; naming and migration details may evolve during implementation.

```swift
import Foundation
import SwiftData

@Model
final class Show {
    @Attribute(.unique) var id: UUID
    var title: String
    var normalizedTitle: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Performance.show)
    var performances: [Performance]

    init(
        id: UUID = UUID(),
        title: String,
        normalizedTitle: String,
        createdAt: Date = .now,
        performances: [Performance] = []
    ) {
        self.id = id
        self.title = title
        self.normalizedTitle = normalizedTitle
        self.createdAt = createdAt
        self.performances = performances
    }
}

@Model
final class Performance {
    @Attribute(.unique) var id: UUID
    var date: Date
    var time: Date?
    var theatre: String
    var city: String
    var seatSection: String
    var seatRow: String
    var seatNumber: String
    var rating: Double?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var show: Show?

    @Relationship(deleteRule: .cascade, inverse: \PerformancePhoto.performance)
    var photos: [PerformancePhoto]

    init(
        id: UUID = UUID(),
        date: Date,
        time: Date? = nil,
        theatre: String = "",
        city: String = "",
        seatSection: String = "",
        seatRow: String = "",
        seatNumber: String = "",
        rating: Double? = nil,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        show: Show? = nil,
        photos: [PerformancePhoto] = []
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.theatre = theatre
        self.city = city
        self.seatSection = seatSection
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.show = show
        self.photos = photos
    }
}

@Model
final class PerformancePhoto {
    @Attribute(.unique) var id: UUID
    var filename: String
    var sortOrder: Int
    var createdAt: Date
    var performance: Performance?

    init(
        id: UUID = UUID(),
        filename: String,
        sortOrder: Int,
        createdAt: Date = .now,
        performance: Performance? = nil
    ) {
        self.id = id
        self.filename = filename
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.performance = performance
    }
}
```

The parent-side cascade rules express ownership: deleting a Show deletes its Performances, and deleting a Performance deletes its photo metadata. File deletion is an explicit `PhotoStore` operation and must be coordinated before metadata deletion. Avoid adding cascade rules on both sides of the same relationship.

## Photo Storage

Do not store `UIImage` or `Data` blobs in SwiftData. Store image files under:

```text
Application Support/PerformancePhotos/
```

SwiftData stores only a stable generated filename and metadata.

```swift
protocol PhotoStoreProtocol {
    func save(_ image: UIImage) async throws -> String
    func load(filename: String) async throws -> UIImage
    func delete(filename: String) throws
}
```

Before saving, normalize orientation, resize to a maximum 2,400 px long edge, and encode as JPEG at approximately 0.85 quality. Generate collision-resistant filenames and perform file I/O off the main actor. The store should create its directory on demand and reject unsafe paths.

## Show Matching

Normalize titles by trimming surrounding whitespace and lowercasing with a stable locale-aware strategy. For example, `Hamilton`, ` HAMILTON `, and `hamilton` all become `hamilton`. Do not attempt semantic aliases, punctuation equivalence, translations, or production-level identity resolution in the MVP.

## Duplicate Detection

Compare `normalizedTitle` plus the local calendar day of the proposed performance. Return an explicit result such as:

```swift
enum DuplicateCheckResult {
    case none
    case possible(existing: Performance)
}
```

A possible duplicate triggers a confirmation warning but remains saveable, since matinee and evening visits may share a day.

## Navigation

The root is a `TabView` containing Collection, Diary, and Profile. The centered **+** is a custom action that presents the add sheet; it is not a persistent content tab. Each main tab owns a `NavigationStack` so its history is preserved independently.

## Add Performance State Machine

Model the flow explicitly to prevent contradictory loading, sheet, and error booleans:

```swift
enum AddPerformanceState {
    case sourceSelection
    case camera
    case processing
    case recognitionResult
    case editing
    case saving
    case completed
    case failed(Error)
}
```

Transitions must define cancellation and retry behavior. A recognition failure should retain any selected image and offer manual editing.

## PerformanceDraft

Do not create or mutate SwiftData models while the form is being edited. Use a transient value type:

```swift
struct PerformanceDraft {
    var showTitle = ""
    var date = Date()
    var time: Date?
    var theatre = ""
    var city = ""
    var seatSection = ""
    var seatRow = ""
    var seatNumber = ""
    var rating: Double?
    var notes = ""
    var photoFilenames: [String] = []
}
```

Validate the draft and persist it only when the user taps **Add to Stage**. Coordinate metadata and new photo files so a failed save can clean up orphaned files.

## Recognition Service

```swift
protocol RecognitionServiceProtocol {
    func recognize(image: UIImage) async throws -> RecognitionResult
}

struct RecognitionResult: Sendable {
    let showTitle: String?
    let theatre: String?
    let city: String?
    let date: Date?
    let time: Date?
    let confidence: Double
}
```

The pipeline is:

```text
UIImage
  → ImageProcessor
  → optional Vision OCR
  → RecognitionService
  → JSON validation
  → PerformanceDraft
```

Treat every remote field as untrusted optional input. Validate types and ranges, tolerate incomplete results, and never persist from the service layer.

## Local OCR

Use `VNRecognizeTextRequest` to extract visible show titles, theatre names, and date/time text. OCR can enrich the remote recognition prompt or support future on-device heuristics; it must not be treated as authoritative.

## Network Layer

Use `URLSession`; do not add Alamofire. A `RecognitionClient` actor can serialize mutable client state, construct authenticated requests, enforce timeouts, validate HTTP status and MIME type, cap response size, decode typed responses, and map errors into user-recoverable categories.

## API Key Security

Never hardcode a production AI provider key in the app. Production topology is:

```text
App → stateless backend/proxy → AI provider
```

The backend authenticates requests, protects provider credentials, rate-limits abuse, and must not persist personal collection data. Early local development may use secure, uncommitted local configuration; no secrets belong in source control or shipped resources.

## Offline Behavior

Every feature except AI recognition must work offline. When recognition is unavailable, show:

> Recognition isn't available offline.

Offer **Add Manually** immediately and preserve any usable draft or selected photo.

## Search

Search `Show.title` and `Performance.theatre`. Normalize the query with trim and lowercase, then compare with `localizedStandardContains`. No fuzzy, semantic, or network-backed search is required in the MVP. Debounce only if profiling shows it is necessary.

## Rating

Build a reusable `StageRatingView` supporting 0.5–5.0 stars. It must expose a clear VoiceOver label and value, support accessible increment/decrement actions, and provide a way to clear an optional rating without relying on color alone.

## Thumbnail Caching

Use `NSCache<NSString, UIImage>` for decoded thumbnails. Generate appropriately sized thumbnails off the main actor and request them according to display scale. The Collection grid must not synchronously decode original 2,400 px images.

## Delete Semantics

Deleting a Performance is an intentional operation:

1. Confirm with the user.
2. Delete all associated photo files.
3. Delete `PerformancePhoto` metadata.
4. Delete the Performance.
5. Delete the parent Show if it now has zero performances.
6. Save the model context and refresh affected views.

Design the repository operation to report partial file failures and remain safely retryable. Do not silently leave broken metadata references.

## Edit Semantics

Convert the selected Performance into a `PerformanceDraft`. The user edits the draft; Save validates and commits once, while Cancel discards it and leaves the original model untouched. Track newly added and removed photos separately until the commit succeeds.

## First Launch

Track completion with:

```swift
@AppStorage("hasCompletedOnboarding")
private var hasCompletedOnboarding = false
```

The onboarding state is local and does not require an account.

## Permissions

Provide a purpose-specific `NSCameraUsageDescription` and request camera authorization only when Scan is chosen. Prefer `PhotosPicker`, which gives scoped selection without requesting broad photo-library access. Do not request location permission in the MVP.

## Localization

Use `Localizable.xcstrings` from day one. Initial UI may be English-first, but user-visible strings must not be scattered as assumptions throughout business logic. Support natural date, time, plural, and number formatting.

## Logging

Use OSLog `Logger` categories:

- `persistence`
- `photo`
- `recognition`
- `navigation`
- `general`

Use appropriate privacy annotations and never log images, notes, seats, API keys, or complete recognition payloads. Avoid excessive `print()` in production.

## Testing Architecture

The architecture must support in-memory SwiftData, a mock recognition service, and a temporary-directory `PhotoStore`. Configure persistence tests with:

```swift
ModelConfiguration(isStoredInMemoryOnly: true)
```

Testing layers include:

- unit tests for normalization, duplicate detection, drafts, ViewModels, and error mapping
- integration tests for repository relationships, file lifecycle, save/edit/delete, and restart persistence
- UI tests for onboarding, manual add, recognition fallback, navigation, edit, and delete

XCTest is sufficient for the MVP.

## Accessibility

All screens must support Dynamic Type, VoiceOver, and Reduce Motion. Accessibility belongs in reusable controls and screen acceptance criteria, not in a final remediation pass.

## Future Migration

Current storage is:

```text
SwiftData + local File Storage
```

Potential future paths are:

```text
SwiftData + CloudKit
```

or:

```text
Repository → Sync Engine → Backend
```

Stable identifiers, repository boundaries, filenames rather than absolute paths, and explicit conflict-ready timestamps preserve both options. No sync behavior is included in v0.1.

## Technical Definition of Done

- [ ] The app builds for iOS 18+ with Swift 6 and no unnecessary third-party dependencies.
- [ ] SwiftUI screens depend on ViewModels rather than directly orchestrating persistence or networking.
- [ ] SwiftData correctly models Show 1 → N Performance and Performance 1 → N PerformancePhoto.
- [ ] Photos are processed and stored as files; SwiftData contains metadata only.
- [ ] Manual add, browse, detail, edit, delete, rating, notes, and photo viewing work offline.
- [ ] Recognition uses the protocol-based service path, validates responses, and never auto-saves.
- [ ] Recognition and network failures retain a path to manual save.
- [ ] Duplicate detection warns on normalized title plus calendar day and allows override.
- [ ] Search, thumbnail caching, and collection rendering remain responsive at the target scale.
- [ ] Deleting a Performance cleans up its files and deletes an empty parent Show.
- [ ] No production API key or personal content appears in source control or logs.
- [ ] User-facing strings use the string catalog and permissions are requested contextually.
- [ ] Dynamic Type, VoiceOver, 44 pt targets, and Reduce Motion are verified.
- [ ] Unit, integration, and UI test seams are present for the planned XCTest suites.
- [ ] Committed records survive app restart and the end-to-end build is ready for TestFlight validation.
