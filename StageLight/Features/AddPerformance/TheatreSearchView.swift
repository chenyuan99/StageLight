import SwiftUI

@MainActor
struct TheatreSearchView: View {
    @Environment(\.dismiss) private var dismiss

    let cityHint: String
    let onSelect: (TheatreSuggestion) -> Void

    @State private var query: String
    @State private var suggestions: [TheatreSuggestion] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    init(
        currentTheatre: String,
        cityHint: String,
        onSelect: @escaping (TheatreSuggestion) -> Void
    ) {
        self.cityHint = cityHint
        self.onSelect = onSelect
        _query = State(initialValue: currentTheatre)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearching && suggestions.isEmpty {
                    ProgressView("Searching Apple Maps…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, suggestions.isEmpty {
                    ContentUnavailableView {
                        Label("Couldn't search theatres", systemImage: "map")
                    } description: {
                        Text(errorMessage)
                    }
                } else if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    ContentUnavailableView {
                        Label("Find a theatre", systemImage: "building.columns")
                    } description: {
                        Text("Search Apple Maps by theatre name. You can always keep a manually entered theatre instead.")
                    }
                } else if suggestions.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(suggestions) { suggestion in
                        Button {
                            onSelect(suggestion)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if let address = suggestion.address {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Find Theatre")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Theatre name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: query) {
                await search()
            }
        }
    }

    private func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            suggestions = []
            errorMessage = nil
            isSearching = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            isSearching = true
            errorMessage = nil
            let results = try await TheatreSearchService.search(
                query: trimmedQuery,
                cityHint: cityHint
            )
            guard !Task.isCancelled else { return }
            suggestions = results
            isSearching = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            suggestions = []
            errorMessage = String(localized: "Apple Maps is temporarily unavailable. You can continue with manual entry.")
            isSearching = false
        }
    }
}
