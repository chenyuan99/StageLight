import UIKit
import XCTest
@testable import StageLight

final class RecognitionServiceTests: XCTestCase {
    @MainActor
    func test_fallback_highestConfidenceLine_becomesShowTitle() throws {
        let result = try RecognitionResultProcessor.fallback(from: [
            RecognizedTextLine(text: "Tonight at 8", confidence: 0.42),
            RecognizedTextLine(text: "Hamilton", confidence: 0.97),
            RecognizedTextLine(text: "Richard Rodgers Theatre", confidence: 0.82)
        ])

        XCTAssertEqual(result.showTitle, "Hamilton")
        XCTAssertEqual(result.confidence, 0.97, accuracy: 0.0001)
    }

    @MainActor
    func test_fallback_equalConfidence_prefersLongerLine() throws {
        let result = try RecognitionResultProcessor.fallback(from: [
            RecognizedTextLine(text: "Wicked", confidence: 0.9),
            RecognizedTextLine(text: "The Phantom of the Opera", confidence: 0.9)
        ])

        XCTAssertEqual(result.showTitle, "The Phantom of the Opera")
    }

    @MainActor
    func test_fallback_detectsTheatreUsingEitherSpelling() throws {
        let british = try RecognitionResultProcessor.fallback(from: [
            RecognizedTextLine(text: "Hadestown", confidence: 0.95),
            RecognizedTextLine(text: "  Walter Kerr Theatre  ", confidence: 0.8)
        ])
        let american = try RecognitionResultProcessor.fallback(from: [
            RecognizedTextLine(text: "Cabaret", confidence: 0.95),
            RecognizedTextLine(text: "August Wilson Theater", confidence: 0.8)
        ])

        XCTAssertEqual(british.theatre, "Walter Kerr Theatre")
        XCTAssertEqual(american.theatre, "August Wilson Theater")
    }

    @MainActor
    func test_fallback_emptyLines_throwsNoTextFound() {
        XCTAssertThrowsError(
            try RecognitionResultProcessor.fallback(from: [
                RecognizedTextLine(text: "  \n ", confidence: 1)
            ])
        ) { error in
            guard case RecognitionError.noTextFound = error else {
                return XCTFail("Expected noTextFound, got \(error)")
            }
        }
    }

    @MainActor
    func test_merging_completeFields_replacesFallbackAndParsesDateAndTime() {
        let result = RecognitionResultProcessor.merging(
            ExtractedPerformanceFields(
                showTitle: "Hadestown",
                theatre: "Walter Kerr Theatre",
                city: "New York",
                date: "2026-08-29",
                time: "19:30"
            ),
            into: fallback(confidence: 0.61)
        )

        XCTAssertEqual(result.showTitle, "Hadestown")
        XCTAssertEqual(result.theatre, "Walter Kerr Theatre")
        XCTAssertEqual(result.city, "New York")
        XCTAssertEqual(components([.year, .month, .day], from: result.date),
                       DateComponents(year: 2026, month: 8, day: 29))
        XCTAssertEqual(components([.hour, .minute], from: result.time),
                       DateComponents(hour: 19, minute: 30))
        XCTAssertEqual(result.confidence, 0.85, accuracy: 0.0001)
    }

    @MainActor
    func test_merging_blankGeneratedFields_preservesFallbackTitleAndTheatre() {
        let result = RecognitionResultProcessor.merging(
            ExtractedPerformanceFields(
                showTitle: "  ",
                theatre: "\n",
                city: "",
                date: "",
                time: ""
            ),
            into: fallback(confidence: 0.93)
        )

        XCTAssertEqual(result.showTitle, "Hamilton")
        XCTAssertEqual(result.theatre, "Richard Rodgers Theatre")
        XCTAssertNil(result.city)
        XCTAssertNil(result.date)
        XCTAssertNil(result.time)
        XCTAssertEqual(result.confidence, 0.93, accuracy: 0.0001)
    }

    @MainActor
    func test_merging_trimsGeneratedTextFields() {
        let result = RecognitionResultProcessor.merging(
            ExtractedPerformanceFields(
                showTitle: "  Wicked  ",
                theatre: " Gershwin Theatre\n",
                city: " New York ",
                date: " 2026-10-31 ",
                time: " 14:00 "
            ),
            into: fallback()
        )

        XCTAssertEqual(result.showTitle, "Wicked")
        XCTAssertEqual(result.theatre, "Gershwin Theatre")
        XCTAssertEqual(result.city, "New York")
        XCTAssertNotNil(result.date)
        XCTAssertNotNil(result.time)
    }

    @MainActor
    func test_merging_invalidDateAndTime_returnsNilTemporalFields() {
        let result = RecognitionResultProcessor.merging(
            ExtractedPerformanceFields(
                showTitle: "Wicked",
                theatre: "",
                city: "",
                date: "August 29",
                time: "7:30 PM"
            ),
            into: fallback()
        )

        XCTAssertNil(result.date)
        XCTAssertNil(result.time)
    }

    @MainActor
    func test_recognize_imageWithoutCGImage_throwsInvalidImage() async {
        let service = LocalOCRRecognitionService()

        do {
            _ = try await service.recognize(image: UIImage())
            XCTFail("Expected invalidImage")
        } catch {
            guard case RecognitionError.invalidImage = error else {
                return XCTFail("Expected invalidImage, got \(error)")
            }
        }
    }

    private func fallback(confidence: Double = 0.7) -> RecognitionResult {
        RecognitionResult(
            showTitle: "Hamilton",
            theatre: "Richard Rodgers Theatre",
            city: nil,
            date: nil,
            time: nil,
            confidence: confidence
        )
    }

    private func components(
        _ components: Set<Calendar.Component>,
        from date: Date?
    ) -> DateComponents? {
        guard let date else { return nil }
        return Calendar.current.dateComponents(components, from: date)
    }
}
