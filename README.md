# StageLight / 剧光灯

StageLight is a private, local-first iOS theatre diary for collecting the performances you have seen.

> Your life on stage.

## MVP

Users can:

- scan a Playbill, ticket, or theatre poster
- identify a show
- confirm and save a performance
- rate it
- add notes and photos
- browse Collection and Diary
- view personal theatre stats

## Product Docs

- [PRD](docs/PRD.md)
- [Design](docs/DESIGN.md)
- [Technical Specification](docs/TECHNICAL_SPEC.md)
- [Test Plan](docs/TEST_PLAN.md)

## MVP Stack

Swift 6 · SwiftUI · SwiftData · PhotosUI · AVFoundation · Vision · URLSession · OSLog · FileManager · XCTest

## Development

Open `StageLight.xcodeproj` in Xcode 16 or later. The app targets iOS 18+ and has no third-party runtime dependencies.

- Run the `StageLight` scheme on an iOS 18+ simulator or device.
- Run unit and UI tests with **Product → Test** (`⌘U`).
- Camera capture requires a physical iPhone; manual entry and PhotosPicker work in Simulator.

## Principles

Local-first. Private by default. No account required. AI assists, user confirms.
