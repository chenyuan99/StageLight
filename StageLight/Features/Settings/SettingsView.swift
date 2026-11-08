import SwiftUI

/// Preference keys and defaults stay in their existing controls; navigation does not migrate data.
struct SettingsView: View {
    var body: some View {
        List {
            Section("Appearance") {
                NavigationLink {
                    SettingsPage(title: "Language") { LanguageSettings() }
                } label: { Label("Language", systemImage: "globe") }
                .accessibilityIdentifier("settings-language")
                NavigationLink {
                    SettingsPage(title: "App icon") { AppIconSettings() }
                } label: { Label("App icon", systemImage: "app") }
                .accessibilityIdentifier("settings-icon")
            }
            Section("Behavior") {
                NavigationLink {
                    SettingsPage(title: "Diary preferences") { ReflectionSettings() }
                } label: { Label("Diary preferences", systemImage: "book") }
                .accessibilityIdentifier("settings-diary")
                NavigationLink {
                    SettingsPage(title: "Mini Theatre") { MiniTheatreSettings() }
                } label: { Label("Mini Theatre", systemImage: "theatermasks") }
                .accessibilityIdentifier("settings-mini")
                NavigationLink {
                    SettingsPage(title: "Theatre history") { TheatreHistorySettings() }
                } label: { Label("Theatre history", systemImage: "clock.arrow.circlepath") }
                .accessibilityIdentifier("settings-history")
            }
            Section("Data") {
                NavigationLink {
                    SettingsPage(title: "iCloud Sync") { CloudSyncSettings() }
                } label: { Label("iCloud Sync", systemImage: "icloud") }
                .accessibilityIdentifier("settings-sync")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings-list")
    }
}

private struct SettingsPage<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content
    var body: some View {
        ScrollView {
            content().padding(24).frame(maxWidth: .infinity, alignment: .leading)
                .readableStageContent()
        }
        .background(StageTheme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LanguageSettings: View {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.system.rawValue
    var body: some View { languageSection }
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 14) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text("App Language")
                        .font(.headline)
                    Text("Change the language without restarting StageLight.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("App Language", selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(verbatim: language.displayName)
                            .tag(language.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .accessibilityIdentifier("app-language-picker")
            }
            .padding(18)
            .background(StageTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityElement(children: .contain)
    }

}

private struct CloudSyncSettings: View {
    @Environment(LibraryStore.self) private var library
    @State private var cloudSyncAvailability: CloudSyncAvailability = .checking
    private let cloudSyncStatusProvider = CloudSyncStatusProvider(containerIdentifier: "iCloud.com.chenyuan.StageLight")
    var body: some View { cloudSyncSection.task { await refreshCloudSyncStatus() } }
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
        #if DEBUG
        // UI tests use an isolated local store and an unsigned simulator build.
        // Do not ask CloudKit for entitlements or account state in that mode.
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            cloudSyncAvailability = .noAccount
            library.refresh()
            return
        }
        #endif
        cloudSyncAvailability = .checking
        cloudSyncAvailability = await cloudSyncStatusProvider.currentAvailability()
        library.refresh()
    }

}
