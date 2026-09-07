import SwiftUI
import UIKit

enum MemoryCardBrand {
    static let signature = "Made with StageLight"
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6806575225")!

    @MainActor
    static func activityItems(image: UIImage, includesAppStoreLink: Bool) -> [Any] {
        includesAppStoreLink ? [image, appStoreURL] : [image]
    }
}

enum MemoryCardTemplate: String, CaseIterable, Identifiable {
    case spotlight
    case story

    var id: Self { self }

    var displayName: LocalizedStringKey {
        switch self {
        case .spotlight: "Spotlight"
        case .story: "Story"
        }
    }

    var canvasSize: CGSize {
        switch self {
        case .spotlight: CGSize(width: 360, height: 450)
        case .story: CGSize(width: 360, height: 640)
        }
    }

    var pixelSize: CGSize {
        CGSize(width: canvasSize.width * 3, height: canvasSize.height * 3)
    }
}

struct MemoryCardOptions: Equatable {
    var includesTitle = true
    var includesPhoto = true
    var includesDate = true
    var includesVenue = true
    var includesSeat = true
    var includesRating = true
    var includesNote = true
}

struct MemoryCardSource: Equatable {
    let showTitle: String
    let date: Date
    let theatre: String
    let city: String
    let seat: String?
    let rating: Double?
    let notes: String

    init(
        showTitle: String,
        date: Date,
        theatre: String,
        city: String,
        seat: String?,
        rating: Double?,
        notes: String
    ) {
        self.showTitle = showTitle
        self.date = date
        self.theatre = theatre
        self.city = city
        self.seat = seat
        self.rating = rating
        self.notes = notes
    }

    init(performance: Performance) {
        showTitle = performance.show?.title ?? AppLanguage.localized("Untitled Show")
        date = performance.date
        theatre = performance.theatre
        city = performance.city
        seat = performance.formattedSeat
        rating = performance.rating
        notes = performance.notes
    }
}

struct MemoryCardContent: Equatable {
    let title: String?
    let includesPhoto: Bool
    let date: String?
    let venue: String?
    let seat: String?
    let rating: String?
    let note: String?

    static func make(
        source: MemoryCardSource,
        options: MemoryCardOptions,
        locale: Locale = .autoupdatingCurrent
    ) -> Self {
        let venue = [source.theatre, source.city]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")

        return Self(
            title: options.includesTitle ? source.showTitle : nil,
            includesPhoto: options.includesPhoto,
            date: options.includesDate
                ? source.date.formatted(
                    .dateTime.month(.wide).day().year().locale(locale)
                )
                : nil,
            venue: options.includesVenue && !venue.isEmpty ? venue : nil,
            seat: options.includesSeat ? source.seat : nil,
            rating: options.includesRating
                ? source.rating.map { "★ \($0.formatted(.number.precision(.fractionLength(1)))) / 5" }
                : nil,
            note: options.includesNote ? shortenedNote(source.notes) : nil
        )
    }

    private static func shortenedNote(_ value: String, limit: Int = 180) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit - 1))
            .trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    var accessibilitySummary: String {
        [title, date, venue, seat, rating, note]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

struct MemoryCardView: View {
    let content: MemoryCardContent
    let template: MemoryCardTemplate
    let photo: UIImage?

    var body: some View {
        Group {
            switch template {
            case .spotlight:
                spotlightCard
            case .story:
                storyCard
            }
        }
        .frame(width: template.canvasSize.width, height: template.canvasSize.height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(content.accessibilitySummary), \(MemoryCardBrand.signature)")
    }

    private var spotlightCard: some View {
        ZStack {
            Color(red: 0.96, green: 0.93, blue: 0.86)
            Circle()
                .fill(Color(red: 0.82, green: 0.69, blue: 0.35).opacity(0.18))
                .frame(width: 290, height: 290)
                .blur(radius: 22)
                .offset(x: 150, y: -210)

            VStack(alignment: .leading, spacing: 0) {
                cardPhoto(height: content.includesPhoto ? 225 : 44)

                VStack(alignment: .leading, spacing: 10) {
                    if let title = content.title {
                        Text(title)
                            .font(.system(size: 31, weight: .bold, design: .serif))
                            .foregroundStyle(Color.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)
                    }

                    metadata(foreground: .black.opacity(0.72), accent: Color(red: 0.48, green: 0.34, blue: 0.08))

                    if let note = content.note {
                        Text("“\(note)”")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(Color.black.opacity(0.78))
                            .lineLimit(content.includesPhoto ? 3 : 8)
                    }

                    Spacer(minLength: 4)
                    brand(foreground: .black.opacity(0.72))
                }
                .padding(22)
            }
        }
    }

    private var storyCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.07, blue: 0.06), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.69, blue: 0.35), lineWidth: 1)
                .padding(14)

            VStack(alignment: .leading, spacing: 18) {
                brand(foreground: Color(red: 0.87, green: 0.75, blue: 0.43))

                if let title = content.title {
                    Text(title)
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.64)
                }

                cardPhoto(height: content.includesPhoto ? 290 : 42)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                metadata(foreground: .white.opacity(0.78), accent: Color(red: 0.87, green: 0.75, blue: 0.43))

                if let note = content.note {
                    Text("“\(note)”")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(content.includesPhoto ? 4 : 10)
                }

                Spacer(minLength: 0)
            }
            .padding(30)
        }
    }

    @ViewBuilder
    private func cardPhoto(height: CGFloat) -> some View {
        if content.includesPhoto {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.white.opacity(0.08)
                        Image(systemName: "theatermasks")
                            .font(.system(size: 42, weight: .ultraLight))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
        } else {
            Rectangle()
                .fill(Color(red: 0.82, green: 0.69, blue: 0.35))
                .frame(width: 54, height: 3)
                .frame(height: height, alignment: .bottomLeading)
        }
    }

    @ViewBuilder
    private func metadata(foreground: Color, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let date = content.date {
                Text(date)
            }
            if let venue = content.venue {
                Text(venue)
            }
            if let seat = content.seat {
                Text(seat)
            }
            if let rating = content.rating {
                Text(rating)
                    .foregroundStyle(accent)
            }
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(foreground)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
    }

    private func brand(foreground: Color) -> some View {
        HStack(spacing: 7) {
            Image("MemoryCardAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(MemoryCardBrand.signature)
                .tracking(0.35)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundStyle(foreground)
    }
}

@MainActor
enum MemoryCardRenderer {
    static func render(
        content: MemoryCardContent,
        template: MemoryCardTemplate,
        photo: UIImage?
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: MemoryCardView(content: content, template: template, photo: photo)
        )
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
