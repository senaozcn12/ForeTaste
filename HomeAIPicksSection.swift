//
//  HomeAIPicksSection.swift
//  ForeTaste
//

import SwiftUI
import CoreLocation

struct HomeAIPicksSection: View {
    let textColor: Color
    let secondaryTextColor: Color
    let cardFill: Color
    let cardStroke: Color
    let accentPink: Color
    let accentOrange: Color
    let deepCocoa: Color
    let onOpenRestaurant: (RestaurantPlace) -> Void

    @StateObject private var locationProvider = UserLocationProvider()
    @State private var preferences = UserDefaults.standard.loadTastePreferences()
    @State private var restaurants = RestaurantStore.loadRestaurants()
    @State private var isLoadingRestaurants = false

    private var picks: [RestaurantMatch] {
        restaurants
            .map { restaurant in
                RestaurantMatch(restaurant: restaurant, score: matchScore(for: restaurant), reason: matchReason(for: restaurant))
            }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Picks", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(textColor)

                Spacer()

                Text("Based on safe foods")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
            }

            if preferences.safeFoodOptions.isEmpty && !preferences.hasSavedAnswers {
                Text("Open your profile to add safe foods and preferences. MenuMind will use them for restaurant picks here.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFill, in: RoundedRectangle(cornerRadius: 14))
            } else if isLoadingRestaurants {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Finding real restaurants near you...")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFill, in: RoundedRectangle(cornerRadius: 14))
            } else if picks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No nearby restaurant picks yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                    Text("Allow location access or open Explore to search real restaurants from Maps.")
                        .font(.caption)
                        .foregroundStyle(secondaryTextColor)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFill, in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 10) {
                    ForEach(picks) { pick in
                        Button {
                            onOpenRestaurant(pick.restaurant)
                        } label: {
                            restaurantPickRow(pick)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: deepCocoa.opacity(0.08), radius: 12, y: 5)
        .onAppear {
            preferences = UserDefaults.standard.loadTastePreferences()
            restaurants = RestaurantStore.loadRestaurants()
            locationProvider.requestLocation()
            Task { await refreshRealRestaurantPicks() }
        }
        .onChange(of: locationProvider.location) { _, _ in
            Task { await refreshRealRestaurantPicks() }
        }
    }

    private func restaurantPickRow(_ pick: RestaurantMatch) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(accentOrange, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(pick.restaurant.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(textColor)
                        .lineLimit(1)

                    Spacer()

                    Text("\(pick.score)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accentPink)
                }

                Text(pick.reason)
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(2)

                if pick.restaurant.safeMenuOptions.isEmpty {
                    Text(pick.restaurant.cuisine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(deepCocoa.opacity(0.58))
                        .lineLimit(1)
                } else {
                    Text(pick.restaurant.safeMenuOptions.prefix(3).joined(separator: " | "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(deepCocoa.opacity(0.58))
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 14))
    }

    private func matchScore(for restaurant: RestaurantPlace) -> Int {
        let profileTerms = normalizedProfileTerms()
        guard !profileTerms.isEmpty else { return restaurant.isFavorite ? 76 : 68 }

        let restaurantTerms = (restaurant.safeMenuOptions + restaurant.matchTags + [restaurant.cuisine, restaurant.name, restaurant.address])
            .map { $0.lowercased() }
            .joined(separator: " ")

        let matches = profileTerms.filter { restaurantTerms.contains($0) }
        let base = 62 + min(matches.count * 8, 30)
        return min(base + (restaurant.isFavorite ? 6 : 0), 98)
    }

    private func matchReason(for restaurant: RestaurantPlace) -> String {
        let profileTerms = normalizedProfileTerms()
        let restaurantTerms = (restaurant.safeMenuOptions + restaurant.matchTags + [restaurant.cuisine, restaurant.name, restaurant.address])
            .map { $0.lowercased() }
            .joined(separator: " ")
        let matches = profileTerms.filter { restaurantTerms.contains($0) }

        if let firstMatch = matches.first {
            if restaurant.safeMenuOptions.isEmpty {
                return "A real nearby restaurant from Maps that matches your \(firstMatch) profile term."
            }
            return "Matches your \(firstMatch) preference with options like \(restaurant.safeMenuOptions.prefix(2).joined(separator: " and "))."
        }

        return "A real nearby restaurant from Maps that may fit your saved food profile."
    }

    private func normalizedProfileTerms() -> [String] {
        (preferences.safeFoodOptions + preferences.restrictions + preferences.flavors + [preferences.favoriteFood])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .removingDuplicates()
    }

    private func refreshRealRestaurantPicks() async {
        guard preferences.hasSavedAnswers else { return }
        guard let coordinate = locationProvider.location?.coordinate else { return }

        isLoadingRestaurants = true
        let results = await RestaurantSearchService().searchRestaurants(near: coordinate, query: restaurantSearchQuery())
        let savedFavorites = RestaurantStore.loadRestaurants().filter(\.isFavorite)
        restaurants = merge(results, with: savedFavorites)
        isLoadingRestaurants = false
    }

    private func restaurantSearchQuery() -> String {
        let terms = normalizedProfileTerms()
        if let preferredTerm = terms.first(where: { !$0.contains("allerg") && !$0.contains("free") }) {
            return "\(preferredTerm) restaurants"
        }

        if preferences.restrictions.contains(where: { $0.localizedCaseInsensitiveContains("vegetarian") }) {
            return "vegetarian restaurants"
        }

        if preferences.restrictions.contains(where: { $0.localizedCaseInsensitiveContains("vegan") }) {
            return "vegan restaurants"
        }

        return "restaurants"
    }

    private func merge(_ nearby: [RestaurantPlace], with favorites: [RestaurantPlace]) -> [RestaurantPlace] {
        var merged = nearby
        for favorite in favorites where !merged.contains(where: { $0.name == favorite.name && $0.address == favorite.address }) {
            merged.append(favorite)
        }
        return merged
    }
}

private struct RestaurantMatch: Identifiable {
    let id = UUID()
    let restaurant: RestaurantPlace
    let score: Int
    let reason: String
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    HomeAIPicksSection(
        textColor: .black,
        secondaryTextColor: .black.opacity(0.6),
        cardFill: .white.opacity(0.6),
        cardStroke: .white,
        accentPink: .pink,
        accentOrange: .orange,
        deepCocoa: .brown,
        onOpenRestaurant: { _ in }
    )
    .padding()
}
