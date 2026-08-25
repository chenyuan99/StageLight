import SwiftUI

struct ProfileView: View {
    @Environment(LibraryStore.self) private var library

    private var statistics: LibraryStatistics { library.statistics }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 44) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(statistics.performanceCount.formatted())
                        .font(.system(size: 68, weight: .semibold, design: .serif))
                        .contentTransition(.numericText())
                    Text("performances")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("\(statistics.showCount) shows · \(statistics.theatreCount) theatres")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                }

                HStack(alignment: .top, spacing: 30) {
                    profileStatistic(
                        value: statistics.averageRating?.formatted(
                            .number.precision(.fractionLength(1))
                        ) ?? "—",
                        label: "average rating"
                    )
                    profileStatistic(
                        value: statistics.performancesThisYear.formatted(),
                        label: "this year"
                    )
                }

                if let mostWatched = statistics.mostWatchedShow {
                    editorialFact(label: "Most watched show", value: mostWatched)
                }
                if let favoriteTheatre = statistics.favoriteTheatre {
                    editorialFact(label: "Favorite theatre", value: favoriteTheatre)
                }

                Spacer(minLength: 60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(StageTheme.background)
        .navigationTitle("Profile")
    }

    private func profileStatistic(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(.title, design: .serif, weight: .semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func editorialFact(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(.title2, design: .serif, weight: .medium))
        }
    }
}
