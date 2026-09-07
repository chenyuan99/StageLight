import SwiftUI
import UIKit

struct ShowCard: View {
    let show: Show

    private var coverPhoto: PerformancePhoto? {
        show.latestPerformance?.photoList
            .min { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PhotoThumbnailView(photo: coverPhoto)
                .aspectRatio(0.72, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(show.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text("\(show.performanceList.count) seen")
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
        var parts = [show.title, AppLanguage.localized("\(show.performanceList.count) performances")]
        if let average = show.averageRating {
            parts.append(AppLanguage.localized("average \(average.formatted()) out of 5 stars"))
        }
        return parts.joined(separator: ", ")
    }
}

struct PhotoThumbnailView: View {
    @Environment(LibraryStore.self) private var library
    let filename: String?
    let syncedData: Data?
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?

    init(
        filename: String?,
        syncedData: Data? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.filename = filename
        self.syncedData = syncedData
        self.contentMode = contentMode
    }

    init(photo: PerformancePhoto?, contentMode: ContentMode = .fill) {
        self.init(
            filename: photo?.filename,
            syncedData: photo?.imageData,
            contentMode: contentMode
        )
    }

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
        .task(id: PhotoLoadKey(filename: filename, syncedByteCount: syncedData?.count)) {
            if let syncedData, let syncedImage = UIImage(data: syncedData) {
                image = syncedImage
            } else if let filename {
                image = try? await library.photoStore.load(filename: filename)
            } else {
                image = nil
            }
        }
    }
}

private struct PhotoLoadKey: Equatable {
    let filename: String?
    let syncedByteCount: Int?
}
