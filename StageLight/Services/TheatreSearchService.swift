import CoreLocation
import MapKit

struct TheatreSuggestion: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let city: String?
    let address: String?
}

@MainActor
enum TheatreSearchService {
    private static let broadwayRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    static func search(query: String, cityHint: String) async throws -> [TheatreSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return [] }

        let trimmedCity = cityHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = [trimmedQuery, trimmedCity, "theatre"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.theater])
        if trimmedCity.isEmpty || trimmedCity.localizedStandardContains("New York") {
            request.region = broadwayRegion
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap(suggestion(from:))
    }

    private static func suggestion(from mapItem: MKMapItem) -> TheatreSuggestion? {
        guard let name = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return nil
        }

        let placemark = mapItem.placemark
        let city = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let addressParts = [street, city, placemark.administrativeArea]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let coordinate = placemark.coordinate
        return TheatreSuggestion(
            id: "\(name)|\(coordinate.latitude)|\(coordinate.longitude)",
            name: name,
            city: city?.isEmpty == false ? city : nil,
            address: addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")
        )
    }
}
