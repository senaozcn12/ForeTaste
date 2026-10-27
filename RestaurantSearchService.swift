//
//  RestaurantSearchService.swift
//  ForeTaste
//

import CoreLocation
import MapKit

struct RestaurantSearchService {
    func searchRestaurants(near coordinate: CLLocationCoordinate2D?, query: String = "restaurants") async -> [RestaurantPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "restaurants" : query
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])

        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.prefix(15).map { RestaurantPlace(mapItem: $0) }
        } catch {
            return []
        }
    }
}

extension RestaurantPlace {
    init(mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        let category = mapItem.pointOfInterestCategory?.rawValue
            .replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "_", with: " ") ?? "Restaurant"

        self.init(
            name: mapItem.name ?? "Restaurant",
            cuisine: category.isEmpty ? "Restaurant" : category.capitalized,
            address: mapItem.placemark.title ?? "Nearby",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            safeMenuOptions: [],
            matchTags: [category.lowercased()],
            notes: "",
            photoData: [],
            isFavorite: false
        )
    }
}
