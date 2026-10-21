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
        XCTAssertEqual(result.confidence, 0.64, accuracy: 0.0001)
    }

    @MainActor
    func test_fallback_prominentTitle_beatsLongerCopy() throws {
        let result = try RecognitionResultProcessor.fallback(from: [
            RecognizedTextLine(text: "Wicked", confidence: 0.9, height: 0.15),
            RecognizedTextLine(text: "The Phantom of the Opera", confidence: 0.9)
        ])

        XCTAssertEqual(result.showTitle, "Wicked")
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
            into: fallback(confidence: 0.61),
            sourceText: "Hadestown Walter Kerr Theatre New York August 29, 2026 7:30 PM"
        )

        XCTAssertEqual(result.showTitle, "Hadestown")
        XCTAssertEqual(result.theatre, "Walter Kerr Theatre")
        XCTAssertEqual(result.city, "New York")
        XCTAssertEqual(components([.year, .month, .day], from: result.date),
                       DateComponents(year: 2026, month: 8, day: 29))
        XCTAssertEqual(components([.hour, .minute], from: result.time),
                       DateComponents(hour: 19, minute: 30))
        XCTAssertEqual(result.confidence, 0.61, accuracy: 0.0001)
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
            into: fallback(confidence: 0.93),
            sourceText: "Hamilton Richard Rodgers Theatre"
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
            into: fallback(),
            sourceText: "Wicked Gershwin Theatre New York 2026-10-31 14:00"
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
            into: fallback(),
            sourceText: "Wicked Gershwin Theatre New York 2026-10-31 14:00"
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

    @MainActor
    func test_fallback_ignoresPlaybillVenueAndSeatLabels() throws {
        let result = try RecognitionResultProcessor.fallback(from: [
            .init(text: "PLAYBILL", confidence: 1, height: 0.2),
            .init(text: "Richard Rodgers Theatre", confidence: 1),
            .init(text: "Row H Seat 108", confidence: 1),
            .init(text: "Hamilton", confidence: 0.85, height: 0.12)
        ])
        XCTAssertEqual(result.showTitle, "Hamilton")
        XCTAssertLessThan(result.confidence, 0.65)
    }

    @MainActor
    func test_fallback_metadataOnly_doesNotInventTitle() throws {
        let result = try RecognitionResultProcessor.fallback(from: [
            .init(text: "PLAYBILL", confidence: 1),
            .init(text: "Gershwin Theatre", confidence: 1),
            .init(text: "19:30", confidence: 1)
        ])
        XCTAssertNil(result.showTitle)
        XCTAssertEqual(result.theatre, "Gershwin Theatre")
    }

    @MainActor
    func test_merging_rejectsDetailsAbsentFromPhoto() {
        let result = RecognitionResultProcessor.merging(
            .init(showTitle: "Wicked", theatre: "Gershwin Theatre", city: "New York", date: "2026-10-31", time: "19:30"),
            into: fallback(confidence: 0.4),
            sourceText: "Hamilton Richard Rodgers Theatre"
        )
        XCTAssertEqual(result.showTitle, "Hamilton")
        XCTAssertEqual(result.theatre, "Richard Rodgers Theatre")
        XCTAssertNil(result.city)
        XCTAssertNil(result.date)
        XCTAssertNil(result.time)
        XCTAssertEqual(result.confidence, 0.4)
    }

    @MainActor
    func test_recognize_cancelledTask_doesNotReturnResult() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { _ in }
        let task = Task { @MainActor in
            return try await LocalOCRRecognitionService().recognize(image: image)
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Cancelled recognition must not return a result")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    @MainActor
    func test_recognize_playbillImage_findsTitleInsteadOfMasthead() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1200)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 900, height: 1200))
            for (text, y, size) in [("PLAYBILL", 60.0, 110.0), ("Hamilton", 400.0, 90.0), ("Richard Rodgers Theatre", 700.0, 40.0)] {
                (text as NSString).draw(at: CGPoint(x: 50, y: y), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: size), .foregroundColor: UIColor.black
                ])
            }
        }
        let result = try await LocalOCRRecognitionService(usesAppleIntelligence: false).recognize(image: image)
        XCTAssertEqual(result.showTitle, "Hamilton")
        XCTAssertEqual(result.theatre, "Richard Rodgers Theatre")
        XCTAssertNil(result.date)
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
