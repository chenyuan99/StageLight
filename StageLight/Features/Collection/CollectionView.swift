import SwiftUI

struct CollectionView: View {
    @Environment(LibraryStore.self) private var library
    let onAdd: () -> Void
    @State private var searchText = ""
    @State private var selectedYear: Int?
    @State private var minimumRating: Double?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if library.shows.isEmpty {
                emptyState
            } else if filteredShows.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                        ForEach(filteredShows) { show in
                            NavigationLink {
                                ShowDetailView(show: show)
                            } label: {
                                ShowCard(show: show)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 88)
                }
                .background(StageTheme.background)
                .refreshable { library.refresh() }
            }
        }
        .navigationTitle("Collection")
        .searchable(text: $searchText, prompt: "Show or theatre")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your stage is empty.", systemImage: "spotlight.max")
        } description: {
            Text("Every show starts with a moment worth remembering.")
        } actions: {
            Button("Add your first show", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }

    private var filterMenu: some View {
        Menu {
            Section("Year") {
                Button("All Years") { selectedYear = nil }
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                    } label: {
                        if selectedYear == year {
                            Label(year.formatted(.number.grouping(.never)), systemImage: "checkmark")
                        } else {
                            Text(year.formatted(.number.grouping(.never)))
                        }
                    }
                }
            }

            Section("Rating") {
                Button("Any Rating") { minimumRating = nil }
                Button("4 stars & up") { minimumRating = 4 }
                Button("5 stars") { minimumRating = 5 }
            }

            if selectedYear != nil || minimumRating != nil {
                Button("Clear Filters", role: .destructive) {
                    selectedYear = nil
                    minimumRating = nil
                }
            }
        } label: {
            Image(systemName: selectedYear == nil && minimumRating == nil
                ? "line.3.horizontal.decrease"
                : "line.3.horizontal.decrease.circle.fill")
        }
        .accessibilityLabel("Filter Collection")
    }

    private var availableYears: [Int] {
        Array(Set(library.performances.map { Calendar.current.component(.year, from: $0.date) }))
            .sorted(by: >)
    }

    private var filteredShows: [Show] {
        library.shows.filter { show in
            let matchesQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || show.title.localizedStandardContains(searchText)
                || show.performanceList.contains { $0.theatre.localizedStandardContains(searchText) }
            let matchesYear = selectedYear == nil
                || show.performanceList.contains {
                    Calendar.current.component(.year, from: $0.date) == selectedYear
                }
            let matchesRating = minimumRating == nil
                || show.performanceList.contains { ($0.rating ?? 0) >= (minimumRating ?? 0) }
            return matchesQuery && matchesYear && matchesRating
        }
    }
}
