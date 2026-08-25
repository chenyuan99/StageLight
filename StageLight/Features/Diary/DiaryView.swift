import SwiftUI

struct DiaryView: View {
    @Environment(LibraryStore.self) private var library

    var body: some View {
        Group {
            if library.performances.isEmpty {
                ContentUnavailableView(
                    "No memories yet",
                    systemImage: "book.closed",
                    description: Text("Your performances will appear here in time order.")
                )
            } else {
                List {
                    ForEach(groupedYears, id: \.year) { yearGroup in
                        Section {
                            ForEach(yearGroup.months, id: \.month) { monthGroup in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(monthName(monthGroup.month))
                                        .font(.title3.weight(.semibold))
                                        .padding(.vertical, 10)
                                    ForEach(monthGroup.performances) { performance in
                                        NavigationLink {
                                            PerformanceDetailView(performance: performance)
                                        } label: {
                                            DiaryRow(performance: performance)
                                        }
                                        if performance.id != monthGroup.performances.last?.id {
                                            Divider().padding(.leading, 54)
                                        }
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(StageTheme.background)
                            }
                        } header: {
                            Text(yearGroup.year.formatted(.number.grouping(.never)))
                                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(StageTheme.background)
                .refreshable { library.refresh() }
            }
        }
        .navigationTitle("Diary")
    }

    private var groupedYears: [DiaryYear] {
        let calendar = Calendar.current
        let byYear = Dictionary(grouping: library.performances) {
            calendar.component(.year, from: $0.date)
        }
        return byYear.keys.sorted(by: >).map { year in
            let byMonth = Dictionary(grouping: byYear[year] ?? []) {
                calendar.component(.month, from: $0.date)
            }
            let months = byMonth.keys.sorted(by: >).map { month in
                DiaryMonth(
                    month: month,
                    performances: (byMonth[month] ?? []).sorted { $0.date > $1.date }
                )
            }
            return DiaryYear(year: year, months: months)
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }
}

private struct DiaryYear {
    let year: Int
    let months: [DiaryMonth]
}

private struct DiaryMonth {
    let month: Int
    let performances: [Performance]
}

private struct DiaryRow: View {
    let performance: Performance

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(performance.date.formatted(.dateTime.day()))
                .font(.title2.weight(.semibold))
                .frame(width: 40, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.show?.title ?? "Untitled Show")
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
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
