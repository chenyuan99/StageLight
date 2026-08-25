import Foundation
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
            return String(localized: "This image could not be read.")
        case .noTextFound:
            return String(localized: "We couldn't identify this show. You can add it manually.")
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
        guard let strongest = lines.max(by: { lhs, rhs in
            lhs.confidence == rhs.confidence
                ? lhs.string.count < rhs.string.count
                : lhs.confidence < rhs.confidence
        }) else {
            throw RecognitionError.noTextFound
        }

        let theatre = lines
            .map(\.string)
            .first { line in
                let lowered = line.lowercased()
                return lowered.contains("theatre") || lowered.contains("theater")
            }

        return RecognitionResult(
            showTitle: strongest.string.trimmingCharacters(in: .whitespacesAndNewlines),
            theatre: theatre,
            city: nil,
            date: nil,
            time: nil,
            confidence: Double(strongest.confidence)
        )
    }
}
