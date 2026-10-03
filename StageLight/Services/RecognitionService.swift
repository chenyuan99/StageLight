import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import ImageIO
import UIKit
import Vision

struct RecognitionResult: Equatable {
    var showTitle: String?
    var theatre: String?
    var city: String?
    var date: Date?
    var time: Date?
    var confidence: Double
}

struct RecognizedTextLine: Equatable, Sendable {
    let text: String
    let confidence: Float
    var height: Double = 0
}

struct ExtractedPerformanceFields: Equatable {
    var showTitle: String
    var theatre: String
    var city: String
    var date: String
    var time: String
}

@MainActor
protocol RecognitionServiceProtocol {
    func recognize(image: UIImage) async throws -> RecognitionResult
}

enum RecognitionError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return AppLanguage.localized("This image could not be read.")
        case .noTextFound:
            return AppLanguage.localized("We couldn't identify this show. You can add it manually.")
        }
    }
}

@MainActor
final class LocalOCRRecognitionService: RecognitionServiceProtocol {
    private let usesAppleIntelligence: Bool

    init(usesAppleIntelligence: Bool = true) {
        self.usesAppleIntelligence = usesAppleIntelligence
    }

    func recognize(image: UIImage) async throws -> RecognitionResult {
        guard let cgImage = image.cgImage else {
            throw RecognitionError.invalidImage
        }

        let orientation: CGImagePropertyOrientation
        switch image.imageOrientation {
        case .up: orientation = .up
        case .down: orientation = .down
        case .left: orientation = .left
        case .right: orientation = .right
        case .upMirrored: orientation = .upMirrored
        case .downMirrored: orientation = .downMirrored
        case .leftMirrored: orientation = .leftMirrored
        case .rightMirrored: orientation = .rightMirrored
        @unknown default: orientation = .up
        }
        try Task.checkCancellation()
        // Vision performs synchronously; keep image analysis away from the UI actor.
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            try handler.perform([request])
            try Task.checkCancellation()
            return (request.results ?? []).compactMap { observation -> RecognizedTextLine? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return RecognizedTextLine(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    height: observation.boundingBox.height
                )
            }
        }
        let lines = try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
        try Task.checkCancellation()
        let fallback = try RecognitionResultProcessor.fallback(from: lines)

#if canImport(FoundationModels)
        if #available(iOS 26.0, *), usesAppleIntelligence, SystemLanguageModel.default.isAvailable {
            let result = (try? await recognizeWithAppleIntelligence(
                text: lines.map(\.text).joined(separator: "\n"),
                fallback: fallback
            )) ?? fallback
            try Task.checkCancellation()
            return result
        }
#endif

        return fallback
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func recognizeWithAppleIntelligence(
        text: String,
        fallback: RecognitionResult
    ) async throws -> RecognitionResult {
        let session = LanguageModelSession(instructions: """
            Extract factual performance details from OCR text from a Playbill, theatre poster, or ticket.
            Never invent missing information. Return an empty string for any detail that is not explicit.
            Dates must use YYYY-MM-DD and times must use HH:mm in 24-hour time.
            """)
        let response = try await session.respond(
            to: "Extract the performance details from this OCR text:\n\n\(text)",
            generating: ExtractedPerformanceDetails.self
        )
        let details = response.content

        return RecognitionResultProcessor.merging(
            ExtractedPerformanceFields(
                showTitle: details.showTitle,
                theatre: details.theatre,
                city: details.city,
                date: details.date,
                time: details.time
            ),
            into: fallback,
            sourceText: text
        )
    }
#endif
}

@MainActor
enum RecognitionResultProcessor {
    static func fallback(from lines: [RecognizedTextLine]) throws -> RecognitionResult {
        let meaningfulLines = lines.filter { $0.text.nilIfEmpty != nil }
        guard !meaningfulLines.isEmpty else { throw RecognitionError.noTextFound }
        let candidates = meaningfulLines.filter { isTitleCandidate($0.text) }
        let maxHeight = candidates.map(\.height).max() ?? 0
        func score(_ line: RecognizedTextLine) -> Double {
            Double(line.confidence) + (maxHeight > 0 ? 0.4 * line.height / maxHeight : 0)
        }
        let strongest = candidates.max { score($0) < score($1) }

        let theatre = meaningfulLines
            .map(\.text)
            .first { line in
                let lowered = line.lowercased()
                return lowered.contains("theatre") || lowered.contains("theater")
            }?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return RecognitionResult(
            showTitle: strongest?.text.nilIfEmpty,
            theatre: theatre,
            city: nil,
            date: nil,
            time: nil,
            // OCR certainty measures legibility, not whether this is the show title.
            confidence: strongest.map { min(Double($0.confidence), 0.64) } ?? 0
        )
    }

    static func merging(
        _ fields: ExtractedPerformanceFields,
        into fallback: RecognitionResult,
        sourceText: String
    ) -> RecognitionResult {
        func supported(_ value: String) -> String? {
            guard let value = value.nilIfEmpty,
                  contains(value, in: sourceText) else { return nil }
            return value
        }
        return RecognitionResult(
            showTitle: supported(fields.showTitle) ?? fallback.showTitle,
            theatre: supported(fields.theatre) ?? fallback.theatre,
            city: supported(fields.city),
            date: supportedDate(fields.date, sourceText: sourceText),
            time: supportedTime(fields.time, sourceText: sourceText),
            confidence: fallback.confidence
        )
    }

    private static func supportedDate(_ value: String, sourceText: String) -> Date? {
        guard let date = dateFormatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return appears(date, formats: ["yyyy-MM-dd", "MMMM d, yyyy", "MMM d, yyyy", "d MMMM yyyy", "d MMM yyyy"], in: sourceText) ? date : nil
    }

    private static func supportedTime(_ value: String, sourceText: String) -> Date? {
        guard let time = timeFormatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return appears(time, formats: ["HH:mm", "H:mm", "h:mm a", "h:mma"], in: sourceText) ? time : nil
    }

    private static func appears(_ date: Date, formats: [String], in source: String) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formats.contains { format in
            formatter.dateFormat = format
            return contains(formatter.string(from: date), in: source)
        }
    }

    private static func contains(_ value: String, in source: String) -> Bool {
        let pattern = "(?<![a-z0-9])" + NSRegularExpression.escapedPattern(for: normalize(value)) + "(?![a-z0-9])"
        return normalize(source).range(of: pattern, options: .regularExpression) != nil
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func isTitleCandidate(_ text: String) -> Bool {
        let value = normalize(text)
        guard value.rangeOfCharacter(from: .letters) != nil else { return false }
        let labels = ["playbill", "www.playbill.com", "a new musical", "the musical", "a musical", "broadway", "ticketmaster", "telecharge"]
        guard !labels.contains(value) else { return false }
        let metadata = #"\b(theatre|theater|row|seat|section|admit|order|www|https?)\b|\b\d{1,2}:\d{2}\b|\b\d{4}-\d{2}-\d{2}\b"#
        return value.range(of: metadata, options: .regularExpression) == nil
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        formatter.isLenient = false
        return formatter
    }()
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct ExtractedPerformanceDetails {
    @Guide(description: "The title of the theatrical show or performance, or an empty string")
    var showTitle: String

    @Guide(description: "The theatre or venue name, or an empty string")
    var theatre: String

    @Guide(description: "The city where the performance takes place, or an empty string")
    var city: String

    @Guide(description: "The performance date in YYYY-MM-DD format, or an empty string")
    var date: String

    @Guide(description: "The performance time in HH:mm 24-hour format, or an empty string")
    var time: String
}
#endif

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
