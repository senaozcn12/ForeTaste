//
//  RestaurantModels.swift
//  ForeTaste
//

import Foundation
import CoreLocation

struct RestaurantPlace: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var cuisine: String
    var address: String
    var latitude: Double
    var longitude: Double
    var safeMenuOptions: [String]
    var matchTags: [String]
    var notes: String
    var photoData: [Data]
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        cuisine: String,
        address: String,
        latitude: Double,
        longitude: Double,
        safeMenuOptions: [String],
        matchTags: [String],
        notes: String = "",
        photoData: [Data] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.safeMenuOptions = safeMenuOptions
        self.matchTags = matchTags
        self.notes = notes
        self.photoData = photoData
        self.isFavorite = isFavorite
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static let defaults: [RestaurantPlace] = [
        RestaurantPlace(
            name: "Green Table Kitchen",
            cuisine: "Vegetarian",
            address: "Apple Park Area, Cupertino",
            latitude: 37.3349,
            longitude: -122.0090,
            safeMenuOptions: ["grain bowls", "roasted vegetables", "lentil soup"],
            matchTags: ["vegetarian", "vegan", "gluten-free", "savory", "umami"]
        ),
        RestaurantPlace(
            name: "Citrus & Rice",
            cuisine: "Mediterranean",
            address: "Downtown Cupertino",
            latitude: 37.3230,
            longitude: -122.0322,
            safeMenuOptions: ["rice plates", "grilled chicken", "lemon potatoes"],
            matchTags: ["gluten-free", "dairy-free", "savory", "sour"]
        ),
        RestaurantPlace(
            name: "Noodle Garden",
            cuisine: "Asian",
            address: "Stevens Creek Boulevard",
            latitude: 37.3229,
            longitude: -122.0112,
            safeMenuOptions: ["rice noodles", "tofu bowls", "steamed vegetables"],
            matchTags: ["vegan", "vegetarian", "soy", "umami", "spice"]
        ),
        RestaurantPlace(
            name: "Hearth Bakery Cafe",
            cuisine: "Cafe",
            address: "Main Street Cupertino",
            latitude: 37.3268,
            longitude: -122.0196,
            safeMenuOptions: ["egg plates", "fruit bowls", "salads"],
            matchTags: ["vegetarian", "sweet", "savory"]
        )
    ]
}

enum RestaurantStore {
    private static let restaurantsKey = "menuMindRestaurants"

    static func loadRestaurants() -> [RestaurantPlace] {
        guard
            let data = UserDefaults.standard.data(forKey: restaurantsKey),
            let restaurants = try? JSONDecoder().decode([RestaurantPlace].self, from: data)
        else {
            return []
        }

        return restaurants
    }

    static func saveRestaurants(_ restaurants: [RestaurantPlace]) {
        guard let data = try? JSONEncoder().encode(restaurants) else { return }
        UserDefaults.standard.set(data, forKey: restaurantsKey)
    }

    static func update(_ restaurant: RestaurantPlace, in restaurants: inout [RestaurantPlace]) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index] = restaurant
        } else if let index = restaurants.firstIndex(where: { $0.name == restaurant.name && $0.address == restaurant.address }) {
            restaurants[index] = restaurant
        } else {
            restaurants.append(restaurant)
        }

        saveRestaurants(restaurants)
    }
}
