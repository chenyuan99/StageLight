import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
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

struct RecognizedTextLine: Equatable {
    let text: String
    let confidence: Float
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
    func recognize(image: UIImage) async throws -> RecognitionResult {
        guard let cgImage = image.cgImage else {
            throw RecognitionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        let lines = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first }
            .map { RecognizedTextLine(text: $0.string, confidence: $0.confidence) }
        let fallback = try RecognitionResultProcessor.fallback(from: lines)

#if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            return (try? await recognizeWithAppleIntelligence(
                text: lines.map(\.text).joined(separator: "\n"),
                fallback: fallback
            )) ?? fallback
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
            into: fallback
        )
    }
#endif
}

@MainActor
enum RecognitionResultProcessor {
    static func fallback(from lines: [RecognizedTextLine]) throws -> RecognitionResult {
        let meaningfulLines = lines.filter { $0.text.nilIfEmpty != nil }
        guard let strongest = meaningfulLines.max(by: { lhs, rhs in
            lhs.confidence == rhs.confidence
                ? lhs.text.count < rhs.text.count
                : lhs.confidence < rhs.confidence
        }) else {
            throw RecognitionError.noTextFound
        }

        let theatre = meaningfulLines
            .map(\.text)
            .first { line in
                let lowered = line.lowercased()
                return lowered.contains("theatre") || lowered.contains("theater")
            }?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return RecognitionResult(
            showTitle: strongest.text.nilIfEmpty,
            theatre: theatre,
            city: nil,
            date: nil,
            time: nil,
            confidence: Double(strongest.confidence)
        )
    }

    static func merging(
        _ fields: ExtractedPerformanceFields,
        into fallback: RecognitionResult
    ) -> RecognitionResult {
        RecognitionResult(
            showTitle: fields.showTitle.nilIfEmpty ?? fallback.showTitle,
            theatre: fields.theatre.nilIfEmpty ?? fallback.theatre,
            city: fields.city.nilIfEmpty,
            date: dateFormatter.date(from: fields.date.trimmingCharacters(in: .whitespacesAndNewlines)),
            time: timeFormatter.date(from: fields.time.trimmingCharacters(in: .whitespacesAndNewlines)),
            confidence: max(fallback.confidence, 0.85)
        )
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
