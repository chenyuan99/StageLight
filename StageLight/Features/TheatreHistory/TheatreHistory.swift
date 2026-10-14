import Foundation

enum HistoryLanguage {
    static func code(for identifier: String) -> String {
        let value = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        if value.hasPrefix("zh") {
            if value.contains("hans") { return "zh-Hans" }
            if value.contains("hant") { return "zh-Hant" }
            return value.contains("-tw") || value.contains("-hk") || value.contains("-mo")
                ? "zh-Hant" : "zh-Hans"
        }
        return value.hasPrefix("ja") ? "ja" : "en"
    }
}

struct TheatreHistoryText: Codable, Equatable, Sendable {
    let heading: String
    let summary: String
}

struct TheatreHistoryEvent: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let year: Int
    let month: Int
    let day: Int
    let title: String
    let venue: String
    let sourceName: String
    let sourceURL: URL
    var translations: [String: TheatreHistoryText]

    func localized(for language: String) -> (text: TheatreHistoryText, isFallback: Bool) {
        let code = HistoryLanguage.code(for: language)
        if let text = translations[code] { return (text, false) }
        return (translations["en"] ?? .init(heading: "", summary: ""), code != "en")
    }

    var historicalDate: Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    func dateLabel(language: String) -> String {
        guard let date = historicalDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: HistoryLanguage.code(for: language))
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct TheatreHistoryCatalog: Codable, Sendable {
    let schemaVersion: Int
    let revision: Int
    let events: [TheatreHistoryEvent]

    enum ValidationError: Error { case invalidCatalog, missingResource }

    func validated() throws -> Self {
        guard schemaVersion == 1, revision > 0, events.count <= 5000,
              Set(events.map(\.id)).count == events.count else { throw ValidationError.invalidCatalog }
        func valid(_ text: String, limit: Int) -> Bool {
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= limit
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for event in events {
            guard valid(event.id, limit: 100), valid(event.title, limit: 120),
                  valid(event.venue, limit: 140), valid(event.sourceName, limit: 80),
                  (1...9999).contains(event.year), let date = event.historicalDate,
                  calendar.component(.year, from: date) == event.year,
                  calendar.component(.month, from: date) == event.month,
                  calendar.component(.day, from: date) == event.day,
                  event.sourceURL.scheme == "https", event.sourceURL.host?.isEmpty == false,
                  event.sourceURL.user == nil, event.sourceURL.password == nil,
                  event.translations["en"] != nil,
                  Set(event.translations.keys).isSubset(of: ["en", "zh-Hans", "zh-Hant", "ja"]),
                  event.translations.values.allSatisfy({ valid($0.heading, limit: 80) && valid($0.summary, limit: 600) })
            else { throw ValidationError.invalidCatalog }
        }
        return self
    }

    static func decode(_ data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data).validated()
    }

    static func bundled() throws -> Self {
        guard let url = Bundle.main.url(forResource: "theatre-history", withExtension: "json") else {
            throw ValidationError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    var chronologicalEvents: [TheatreHistoryEvent] {
        events.sorted { ($0.year, $0.month, $0.day, $0.id) < ($1.year, $1.month, $1.day, $1.id) }
    }

    func events(on date: Date, timeZone: TimeZone = .current) -> [TheatreHistoryEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return chronologicalEvents.filter {
            $0.month == parts.month && $0.day == parts.day && $0.year < (parts.year ?? 0)
        }
    }
}
