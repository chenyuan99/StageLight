import SwiftUI
import UIKit

struct ShowCard: View {
    let show: Show

    private var coverFilename: String? {
        show.latestPerformance?.photos
            .sorted { $0.sortOrder < $1.sortOrder }
            .first?.filename
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PhotoThumbnailView(filename: coverFilename)
                .aspectRatio(0.72, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(show.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text("\(show.performances.count) seen")
                if let rating = show.latestPerformance?.rating ?? show.averageRating {
                    Text("·")
                    RatingLabel(rating: rating)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [show.title, String(localized: "\(show.performances.count) performances")]
        if let average = show.averageRating {
            parts.append(String(localized: "average \(average.formatted()) out of 5 stars"))
        }
        return parts.joined(separator: ", ")
    }
}

struct PhotoThumbnailView: View {
    @Environment(LibraryStore.self) private var library
    let filename: String?
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(StageTheme.surface)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(.secondary.opacity(0.45))
                    .accessibilityHidden(true)
            }
        }
        .clipped()
        .task(id: filename) {
            guard let filename else {
                image = nil
                return
            }
            image = try? await library.photoStore.load(filename: filename)
        }
    }
}
