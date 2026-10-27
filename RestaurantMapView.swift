//
//  RestaurantMapView.swift
//  ForeTaste
//

import SwiftUI
import MapKit
import PhotosUI

struct RestaurantMapView: View {
    @StateObject private var locationProvider = UserLocationProvider()
    @State private var savedRestaurants = RestaurantStore.loadRestaurants()
    @State private var nearbyRestaurants: [RestaurantPlace] = []
    @State private var selectedRestaurant: RestaurantPlace?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let cocoa = Color(red: 0.52, green: 0.18, blue: 0.20)
    private let deepCocoa = Color(red: 0.24, green: 0.16, blue: 0.16)
    private let accentOrange = Color(red: 1.0, green: 0.62, blue: 0.26)

    private var displayedRestaurants: [RestaurantPlace] {
        var merged = nearbyRestaurants.map { restaurantWithSavedState($0) }

        for favorite in savedRestaurants.filter(\.isFavorite) {
            if !merged.contains(where: { $0.name == favorite.name && $0.address == favorite.address }) {
                merged.append(favorite)
            }
        }

        return merged
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(displayedRestaurants) { restaurant in
                    Marker(restaurant.name, systemImage: restaurant.isFavorite ? "heart.fill" : "fork.knife", coordinate: restaurant.coordinate)
                        .tint(restaurant.isFavorite ? .red : accentOrange)
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding([.horizontal, .top], 16)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("Search nearby restaurants", text: $searchText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await searchNearbyRestaurants() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(cocoa, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    if isSearching {
                        ProgressView()
                    }

                    Text(locationProvider.statusMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(deepCocoa.opacity(0.68))

                    Spacer()

                    Button("Use Location") {
                        locationProvider.requestLocation()
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cocoa)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            List {
                Section("Nearby Restaurants") {
                    if displayedRestaurants.isEmpty {
                        ContentUnavailableView("No Restaurants Yet", systemImage: "location.magnifyingglass", description: Text("Allow location or search manually to find restaurants near you."))
                    } else {
                        ForEach(displayedRestaurants) { restaurant in
                            RestaurantSearchRow(
                                restaurant: restaurant,
                                onOpen: {
                                    selectedRestaurant = restaurant
                                },
                                onFavorite: {
                                    toggleFavorite(restaurant)
                                }
                            )
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color.white, accentOrange.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurantWithSavedState(restaurant)) { updatedRestaurant in
                RestaurantStore.update(updatedRestaurant, in: &savedRestaurants)
                selectedRestaurant = updatedRestaurant
            }
        }
        .onAppear {
            savedRestaurants = RestaurantStore.loadRestaurants()
            locationProvider.requestLocation()
        }
        .onChange(of: locationProvider.location) { _, newLocation in
            guard let newLocation else { return }
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                )
            )
            Task { await searchNearbyRestaurants() }
        }
    }

    private func searchNearbyRestaurants() async {
        let coordinate = locationProvider.location?.coordinate

        if coordinate == nil && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            locationProvider.requestLocation()
            return
        }

        isSearching = true
        let results = await RestaurantSearchService().searchRestaurants(near: coordinate, query: searchText)
        nearbyRestaurants = results
        isSearching = false
    }

    private func restaurantWithSavedState(_ restaurant: RestaurantPlace) -> RestaurantPlace {
        savedRestaurants.first { $0.name == restaurant.name && $0.address == restaurant.address } ?? restaurant
    }

    private func toggleFavorite(_ restaurant: RestaurantPlace) {
        var updatedRestaurant = restaurantWithSavedState(restaurant)
        updatedRestaurant.isFavorite.toggle()
        RestaurantStore.update(updatedRestaurant, in: &savedRestaurants)

        if let index = nearbyRestaurants.firstIndex(where: { $0.name == restaurant.name && $0.address == restaurant.address }) {
            nearbyRestaurants[index] = updatedRestaurant
        }
    }
}

struct FavoriteRestaurantsView: View {
    @State private var restaurants = RestaurantStore.loadRestaurants()
    @State private var selectedRestaurant: RestaurantPlace?

    private var favorites: [RestaurantPlace] {
        restaurants.filter(\.isFavorite)
    }

    var body: some View {
        List {
            if favorites.isEmpty {
                ContentUnavailableView("No Favorites Yet", systemImage: "heart", description: Text("Favorite restaurants from Explore and they will show up here."))
            } else {
                ForEach(favorites) { restaurant in
                    Button {
                        selectedRestaurant = restaurant
                    } label: {
                        RestaurantRow(restaurant: restaurant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Favorites")
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant) { updatedRestaurant in
                RestaurantStore.update(updatedRestaurant, in: &restaurants)
                selectedRestaurant = updatedRestaurant
            }
        }
        .onAppear {
            restaurants = RestaurantStore.loadRestaurants()
        }
    }
}

struct RestaurantDetailHost: View {
    @State private var restaurants = RestaurantStore.loadRestaurants()
    let restaurant: RestaurantPlace

    var body: some View {
        RestaurantDetailView(restaurant: currentRestaurant) { updatedRestaurant in
            RestaurantStore.update(updatedRestaurant, in: &restaurants)
        }
    }

    private var currentRestaurant: RestaurantPlace {
        restaurants.first { $0.id == restaurant.id } ?? restaurant
    }
}

private struct RestaurantSearchRow: View {
    let restaurant: RestaurantPlace
    let onOpen: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                RestaurantRow(restaurant: restaurant)
            }
            .buttonStyle(.plain)

            Button(action: onFavorite) {
                Image(systemName: restaurant.isFavorite ? "heart.fill" : "heart")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(restaurant.isFavorite ? .red : .secondary)
                    .frame(width: 38, height: 38)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(restaurant.isFavorite ? "Remove favorite" : "Favorite restaurant")
        }
        .padding(.vertical, 4)
    }
}

private struct RestaurantRow: View {
    let restaurant: RestaurantPlace

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: restaurant.isFavorite ? "heart.fill" : "fork.knife.circle.fill")
                .font(.title3)
                .foregroundStyle(restaurant.isFavorite ? .red : .orange)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        if restaurant.safeMenuOptions.isEmpty {
            return "\(restaurant.cuisine) • \(restaurant.address)"
        }

        return "\(restaurant.cuisine) • \(restaurant.safeMenuOptions.prefix(2).joined(separator: ", "))"
    }
}

private struct RestaurantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var restaurant: RestaurantPlace
    @State private var selectedPhoto: PhotosPickerItem?
    let onSave: (RestaurantPlace) -> Void

    init(restaurant: RestaurantPlace, onSave: @escaping (RestaurantPlace) -> Void) {
        self._restaurant = State(initialValue: restaurant)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurant.name)
                            .font(.title.bold())

                        Text(restaurant.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            restaurant.isFavorite.toggle()
                            save()
                        } label: {
                            Label(restaurant.isFavorite ? "Favorited" : "Favorite", systemImage: restaurant.isFavorite ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(restaurant.isFavorite ? .red : .orange)

                        Button {
                            openInAppleMaps()
                        } label: {
                            Label("Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    detailSection("Safe Options", icon: "checkmark.seal.fill") {
                        Text(restaurant.safeMenuOptions.joined(separator: ", "))
                            .foregroundStyle(.primary.opacity(0.78))
                    }

                    detailSection("Notes", icon: "note.text") {
                        TextField("Add notes for this restaurant", text: $restaurant.notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(4...8)
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: restaurant.notes) { _, _ in
                                save()
                            }
                    }

                    detailSection("Photos", icon: "photo.on.rectangle") {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Add Photo", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if !restaurant.photoData.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(restaurant.photoData.enumerated()), id: \.offset) { _, data in
                                        if let image = UIImage(data: data) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 92, height: 92)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto, let data = try? await selectedPhoto.loadTransferable(type: Data.self) else { return }
                restaurant.photoData.append(data)
                save()
            }
        }
    }

    private func detailSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }

    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: restaurant.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = restaurant.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func save() {
        onSave(restaurant)
    }
}

#Preview {
    NavigationStack {
        RestaurantMapView()
    }
}
