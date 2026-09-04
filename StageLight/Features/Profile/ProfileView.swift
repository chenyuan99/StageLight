import SwiftUI
import StoreKit

struct ProfileView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.requestReview) private var requestReview
    @AppStorage("lastReviewRequestVersion") private var lastReviewRequestVersion = ""
    @State private var cloudSyncAvailability: CloudSyncAvailability = .checking

    private let cloudSyncStatusProvider = CloudSyncStatusProvider(
        containerIdentifier: "iCloud.com.chenyuan.StageLight"
    )

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

                cloudSyncSection

                Spacer(minLength: 60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(StageTheme.background)
        .navigationTitle("Profile")
        .task {
            await refreshCloudSyncStatus()
            await requestReviewIfAppropriate()
        }
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

    private var cloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iCloud Sync")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityIdentifier("icloud-sync-section-title")

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image(systemName: cloudSyncAvailability == .available
                        ? "icloud.fill"
                        : "icloud")
                        .font(.title2)
                        .foregroundStyle(cloudSyncAvailability == .available
                            ? .blue
                            : .secondary)
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Sync")
                            .font(.headline)
                        Text(cloudSyncAvailability.title)
                            .font(.subheadline)
                            .foregroundStyle(statusColor)
                    }

                    Spacer()

                    if cloudSyncAvailability == .checking {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 9, height: 9)
                            .accessibilityHidden(true)
                    }
                }

                Text(cloudSyncAvailability.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await refreshCloudSyncStatus() }
                } label: {
                    Label("Check Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(cloudSyncAvailability == .checking)
            }
            .padding(18)
            .background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityElement(children: .contain)
    }

    private var statusColor: Color {
        switch cloudSyncAvailability {
        case .available:
            .green
        case .checking, .noAccount, .restricted, .temporarilyUnavailable, .unavailable:
            .secondary
        }
    }

    private func refreshCloudSyncStatus() async {
        cloudSyncAvailability = .checking
        cloudSyncAvailability = await cloudSyncStatusProvider.currentAvailability()
        library.refresh()
    }

    private func requestReviewIfAppropriate() async {
        let arguments = ProcessInfo.processInfo.arguments
        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? ""

        guard ReviewPromptPolicy.shouldRequestReview(
            performanceCount: statistics.performanceCount,
            currentVersion: currentVersion,
            lastRequestedVersion: lastReviewRequestVersion,
            isUITesting: arguments.contains("-ui-testing")
        ) else { return }

        // Profile is a natural pause after someone has built a meaningful
        // collection, so the system prompt does not interrupt data entry.
        try? await Task.sleep(for: .seconds(1.2))
        guard !Task.isCancelled else { return }

        lastReviewRequestVersion = currentVersion
        requestReview()
    }
}
