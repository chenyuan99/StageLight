import SwiftUI

struct ShowDetailView: View {
    let show: Show

    private var performances: [Performance] {
        show.performanceList.sorted { $0.date > $1.date }
    }

    private var coverPhoto: PerformancePhoto? {
        performances.first?.photoList.min { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PhotoThumbnailView(photo: coverPhoto)
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(show.title)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    HStack(spacing: 12) {
                        Text("Seen \(performances.count) times")
                        if let average = show.averageRating {
                            Text("·")
                            RatingLabel(rating: average)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Performances")
                        .font(.title2.weight(.semibold))
                        .padding(.bottom, 12)
                    ForEach(performances) { performance in
                        NavigationLink {
                            PerformanceDetailView(performance: performance)
                        } label: {
                            PerformanceRow(performance: performance)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("performance-row")
                        if performance.id != performances.last?.id {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(StageTheme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceRow: View {
    let performance: Performance

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 1) {
                Text(performance.date.formatted(.dateTime.day()))
                    .font(.title3.weight(.semibold))
                Text(performance.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 5) {
                Text(performance.date.formatted(date: .long, time: .omitted))
                    .font(.headline)
                if !performance.theatre.isEmpty {
                    Text(performance.theatre)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let rating = performance.rating {
                    RatingLabel(rating: rating)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
