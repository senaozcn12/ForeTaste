//
//  LoginView.swift
//  MenuMind
//
//  Created by Sena Ozcan on 7/2/26.
//

import SwiftUI
import AVFoundation
import UIKit
import Vision
import Translation
import CoreText

struct HomePageView: View {
    @State private var searchText = ""
    @State private var showNotificationsAlert = false
    @State private var showMenuSheet = false
    @State private var menuSelectionMessage: IdentifiedMessage? = nil
    @State private var forYouMessage: String? = nil
    @State private var showAskAI = false
    @State private var showMenuScanner = false
    @State private var prefersDarkMode = false
    @State private var textScale = 1.0
    @State private var useOpenDyslexic = false
    @State private var selectedTab = 0
    @State private var showNearby = false
    @State private var showFavorites = false
    @State private var showProfile = false

    private let themePink = Color(red: 1.0, green: 0.46, blue: 0.65)
    private let themeOrange = Color(red: 1.0, green: 0.62, blue: 0.26)
    private let themeYellow = Color(red: 1.0, green: 0.86, blue: 0.35)
    private let themeCocoa = Color(red: 0.52, green: 0.18, blue: 0.20)
    private let deepCocoa = Color(red: 0.24, green: 0.16, blue: 0.16)

    private var textColor: Color { prefersDarkMode ? Color(red: 1.0, green: 0.91, blue: 0.76) : deepCocoa }
    private var secondaryTextColor: Color { textColor.opacity(prefersDarkMode ? 0.74 : 0.68) }
    private var accentPink: Color { prefersDarkMode ? Color(red: 1.0, green: 0.48, blue: 0.75) : themePink }
    private var accentOrange: Color { prefersDarkMode ? themeOrange.opacity(0.95) : themeOrange }
    private var neutralFill: Color { prefersDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.44) }
    private var cardFill: Color { prefersDarkMode ? Color.white.opacity(0.09) : Color.white.opacity(0.64) }
    private var cardStroke: Color { prefersDarkMode ? Color.white.opacity(0.12) : Color.white.opacity(0.58) }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: prefersDarkMode
                    ? [Color.black, themeCocoa.opacity(0.62), Color.black]
                    : [themePink.opacity(0.70), themeOrange.opacity(0.58), themeYellow.opacity(0.50)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection
                    searchField
                    quickFilterRow
                    if let forYouMessage {
                        statusBanner(forYouMessage)
                    }
                    HomeAIPicksSection(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        cardFill: cardFill,
                        cardStroke: cardStroke,
                        accentPink: accentPink,
                        accentOrange: accentOrange,
                        deepCocoa: deepCocoa,
                        onOpenRestaurant: { _ in
                            showNearby = true
                        }
                    )
                    recommendationCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 124)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            HStack(spacing: 25) {
                navButton(title: "Home", icon: "house.fill", index: 0)
                navButton(title: "Explore", icon: "location.fill", index: 1)
                Button {
                    selectedTab = 2
                    showMenuScanner = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentOrange, accentPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 65, height: 65)
                            .shadow(color: accentPink.opacity(0.4), radius: 12)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                navButton(title: "Favorites", icon: "heart.fill", index: 3)
                navButton(title: "Profile", icon: "person.fill", index: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(cardStroke, lineWidth: 1)
            }
            .shadow(color: deepCocoa.opacity(prefersDarkMode ? 0.34 : 0.10), radius: 14, y: 6)
            .padding(.bottom)
            .padding()
            .dynamicTypeSize(dynamicTypeFromScale(textScale))
        }
        .font(useOpenDyslexic ? OpenDyslexicFont.font(size: 17 * textScale) : .system(size: 17 * textScale))
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showAskAI) {
            AskAIView()
        }
        .navigationDestination(isPresented: $showMenuScanner) {
            MenuScannerView()
        }
        .navigationDestination(isPresented: $showNearby) {
            RestaurantMapView()
        }
        .navigationDestination(isPresented: $showFavorites) {
            FavoriteRestaurantsView()
        }
        .navigationDestination(isPresented: $showProfile) {
            ProfilePreferencesView()
        }
        .alert("Notifications", isPresented: $showNotificationsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No current notifications")
        }
        .sheet(isPresented: $showMenuSheet) {
            MenuSheet(
                themePink: themePink,
                themeOrange: themeOrange,
                prefersDarkMode: $prefersDarkMode,
                textScale: $textScale,
                useOpenDyslexic: $useOpenDyslexic,
                textColor: textColor,
                accentPink: accentPink,
                accentOrange: accentOrange,
                neutralFill: neutralFill
            ) { action in
                switch action {
                case .favorites:
                    showMenuSheet = false
                    showFavorites = true
                case .logout:
                    menuSelectionMessage = IdentifiedMessage(text: "Logging out...")
                case .askAI:
                    showMenuSheet = false
                    showAskAI = true
                }
            }
            .presentationDetents([.fraction(0.5)])
        }
        .alert(item: $menuSelectionMessage) { message in
            Alert(title: Text(message.text))
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MenuMind")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                Text("Simple tools for eating out.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryTextColor)
            }
            Spacer()
            headerIconButton(systemName: "bell") {
                showNotificationsAlert = true
            }
            .accessibilityLabel("Notifications")
            headerIconButton(systemName: "person.circle.fill") {
                showProfile = true
            }
                .accessibilityLabel("Profile")
            headerIconButton(systemName: "line.3.horizontal") {
                showMenuSheet = true
            }
            .accessibilityLabel("Menu")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline)
                .foregroundStyle(secondaryTextColor)
            TextField("Search restaurants", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardStroke, lineWidth: 1)
        }
    }

    private var quickFilterRow: some View {
        HStack(spacing: 10) {
            quickFilterButton(title: "For You", icon: "sparkle") {
                forYouMessage = "Gathering restaurants tailored to your favorites and accessibility needs..."
            }
            quickFilterButton(title: "Nearby", icon: "location.fill") {
                showNearby = true
            }
        }
    }

    private func statusBanner(_ message: String) -> some View {
        Label(message, systemImage: "wand.and.stars")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFill, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cardStroke, lineWidth: 1)
            }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Tools")
                .font(.headline)
                .foregroundStyle(textColor)
            homeActionRow(title: "Scan a Menu", subtitle: "Translate, summarize, and make text easier to read.", icon: "camera.viewfinder", color: accentPink) {
                showMenuScanner = true
            }
            Divider()
                .opacity(0.45)
            homeActionRow(title: "Ask AI", subtitle: "Get quick suggestions based on your needs.", icon: "sparkles", color: accentOrange) {
                showAskAI = true
            }
            Divider()
                .opacity(0.45)
            homeActionRow(title: "Explore Nearby", subtitle: "Find places around you.", icon: "location.fill", color: themeCocoa) {
                showNearby = true
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: deepCocoa.opacity(prefersDarkMode ? 0.24 : 0.08), radius: 12, y: 5)
    }

    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(textColor)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardStroke, lineWidth: 1)
                }
        }
    }

    private func quickFilterButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(textColor)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(cardStroke, lineWidth: 1)
                }
        }
    }

    private func homeActionRow(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(color, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func navButton(title: String, icon: String, index: Int) -> some View {
        Button {
            selectedTab = index
            if title == "Favorites" {
                showFavorites = true
            }
            if title == "Explore" {
                showNearby = true
            }
            if title == "Profile" {
                showProfile = true
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == index ? accentOrange : textColor.opacity(0.75))
            .frame(maxWidth: .infinity)
        }
    }

    private func dynamicTypeFromScale(_ scale: Double) -> DynamicTypeSize {
        switch scale {
        case ..<0.9:
            return .xSmall
        case 0.9..<1.0:
            return .small
        case 1.0..<1.2:
            return .medium
        case 1.2..<1.4:
            return .xLarge
        default:
            return .accessibility3
        }
    }
}

private enum MenuAction {
    case favorites
    case logout
    case askAI
}

private struct MenuSheet: View {
    let themePink: Color
    let themeOrange: Color
    @Binding var prefersDarkMode: Bool
    @Binding var textScale: Double
    @Binding var useOpenDyslexic: Bool
    let textColor: Color
    let accentPink: Color
    let accentOrange: Color
    let neutralFill: Color
    var onSelect: (MenuAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.black.opacity(0.15))
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Text("Menu")
                .font(.title2.bold())
                .foregroundStyle(textColor)
            Button {
                onSelect(.favorites)
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                    Spacer()
                }
                .foregroundStyle(textColor)
                .padding()
                .background(accentPink.opacity(prefersDarkMode ? 0.3 : 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                onSelect(.askAI)
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Ask AI")
                    Spacer()
                }
                .foregroundStyle(textColor)
                .padding()
                .background(accentOrange.opacity(prefersDarkMode ? 0.3 : 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button(role: .destructive) {
                onSelect(.logout)
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                    Spacer()
                }
                .foregroundStyle(.red)
                .padding()
                .background(prefersDarkMode ? Color.red.opacity(0.2) : Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Divider()
            Text("Accessibility")
                .font(.headline)
                .foregroundStyle(textColor)
            Toggle(isOn: $prefersDarkMode) {
                HStack {
                    Image(systemName: prefersDarkMode ? "moon.fill" : "sun.max.fill")
                    Text("Appearance: \(prefersDarkMode ? "Dark" : "Light")")
                }
                .foregroundStyle(textColor)
            }
            .toggleStyle(.switch)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "textformat.size")
                    Text("Text Size")
                }
                .foregroundStyle(textColor)
                Slider(value: $textScale, in: 0.8...1.6, step: 0.05)
            }
            Toggle(isOn: $useOpenDyslexic) {
                HStack {
                    Image(systemName: "textformat")
                    Text("Use OpenDyslexic Font")
                }
                .foregroundStyle(textColor)
            }
            .toggleStyle(.switch)
            Spacer()
        }
        .padding()
        .background(prefersDarkMode ? Color.black : Color.white)
        .presentationDragIndicator(.visible)
    }
}

private struct IdentifiedMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

struct AskAIView: View {
    @State private var question = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask AI")
                .font(.largeTitle.bold())
                .foregroundStyle(.black)
            Text("Describe your needs and preferences. We'll help you find places that fit.")
                .foregroundStyle(.black.opacity(0.7))
            TextField("Ask something...", text: $question, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.black)
            Button { } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send")
                }
                .foregroundStyle(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
    }
}

private struct NearbyView: View {
    let prefersDarkMode: Bool
    let textColor: Color
    let accentPink: Color
    let accentOrange: Color
    @State private var isLoading = true
    @State private var statusText = "Searching..."

    var body: some View {
        ZStack {
            LinearGradient(
                colors: prefersDarkMode ? [Color.black, Color.gray.opacity(0.6)] : [Color.white, Color.gray.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                Image(systemName: "map")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.08)
                    .padding(40)
            )
            .ignoresSafeArea()
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .tint(accentOrange)
                    Text(statusText)
                        .font(.headline)
                        .foregroundStyle(textColor)
                } else {
                    Text("Finding restaurants near you...")
                        .font(.title2.bold())
                        .foregroundStyle(textColor)
                }
            }
            .padding()
            .background(prefersDarkMode ? Color.black.opacity(0.4) : Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                statusText = "Locating you..."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isLoading = false
            }
        }
    }
}

struct MenuScannerView: View {
    @State private var selectedLanguage = "Spanish"
    @State private var useDyslexicFont = false
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var showCameraPermissionAlert = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var showTranslation = false
    @State private var showTranslationUnavailableAlert = false
    @State private var capturedMenuImage: UIImage? = nil
    @State private var capturedMenuImages: [UIImage] = []
    @State private var recognizedMenuText = ""
    @State private var recognizedMenuLines: [RecognizedMenuLine] = []
    @State private var translatedMenuText = ""
    @State private var isRecognizingText = false
    @State private var textRecognitionError = ""
    @State private var isSummarizing = false
    @State private var summaryText = ""
    @State private var isGeneratingRecommendations = false
    @State private var recommendationError = ""
    @State private var menuRecommendations: [MenuRecommendation] = []
    @State private var selectedMenuItemType: MenuItemType = .any

    private let languages = ["Spanish", "French", "Arabic", "Turkish", "Chinese"]
    private let accentPink = Color(red: 1.0, green: 0.48, blue: 0.65)
    private let accentOrange = Color.orange
    private let accentYellow = Color(red: 1.0, green: 0.86, blue: 0.35)
    private let cocoa = Color(red: 0.52, green: 0.18, blue: 0.20)
    private let deepCocoa = Color(red: 0.24, green: 0.16, blue: 0.16)
    private let softCream = Color(red: 1.0, green: 0.91, blue: 0.76)

    private var readableFont: Font {
        useDyslexicFont ? OpenDyslexicFont.font(size: 17) : .system(size: 17)
    }

    private var scannedDisplayItems: [ScannedMenuDisplayItem] {
        parseScannedMenuItems(from: recognizedMenuText)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accentPink.opacity(0.72),
                    accentOrange.opacity(0.54),
                    accentYellow.opacity(0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    scannerHeader
                    scannerPreview
                    primaryToolRow
                    localRecommendationCard
                    recommendationResults
                    menuTranslationCard
                    menuList
                    featureControls
                    aiSummaryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Menu Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .font(readableFont)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedMenuImage, sourceType: imagePickerSourceType)
                .ignoresSafeArea()
        }
        .onChange(of: capturedMenuImage) { _, newImage in
            guard let newImage else { return }
            recognizeMenuText(from: newImage)
        }
        .translationPresentation(isPresented: $showTranslation, text: recognizedMenuText) { translatedText in
            translatedMenuText = translatedText
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device or simulator does not have an available camera.")
        }
        .alert("No Menu Text Found", isPresented: $showTranslationUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Take a clear photo of the menu first. MenuMind will read the text before opening translation.")
        }
        .alert("Camera Permission Needed", isPresented: $showCameraPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow MenuMind to access your camera so you can scan restaurant menus.")
        }
    }

    private var scannerHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(softCream.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .shadow(color: cocoa.opacity(0.18), radius: 12, y: 8)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(cocoa)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Menu Scanner")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(deepCocoa)
                Text("Scan, translate, and find food that fits.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(deepCocoa.opacity(0.68))
            }
        }
        .padding(.top, 4)
    }

    private var scannerPreview: some View {
        VStack(spacing: 14) {
            if !capturedMenuImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(capturedMenuImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 118, height: 154)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                    }

                                Text("Page \(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                                    .background(cocoa.opacity(0.82), in: Capsule())
                                    .padding(8)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Text("\(capturedMenuImages.count) menu page\(capturedMenuImages.count == 1 ? "" : "s") scanned")
                    .font(.headline)
                    .foregroundStyle(deepCocoa)
                if isRecognizingText {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Reading menu text...")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(deepCocoa.opacity(0.7))
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [accentOrange, accentPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 210)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        }
                        .shadow(color: cocoa.opacity(0.18), radius: 18, y: 10)

                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 58, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Point at a menu")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                Text("Use your camera to scan a menu")
                    .font(.headline)
                    .foregroundStyle(deepCocoa)
                Text("Take clear photos of every menu page. MenuMind will combine the pages before creating free on-device recommendations.")
                    .font(.subheadline)
                    .foregroundStyle(deepCocoa.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            Button {
                openCamera()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(capturedMenuImages.isEmpty ? "Scan First Page" : "Add Another Page")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(cocoa, in: Capsule())
                .shadow(color: cocoa.opacity(0.22), radius: 12, y: 7)
            }
            if !capturedMenuImages.isEmpty {
                Button {
                    clearScannedMenu()
                } label: {
                    Label("Clear scanned pages", systemImage: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(cocoa)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private var primaryToolRow: some View {
        HStack(spacing: 10) {
            scannerToolButton(title: "Translate", icon: "translate", tint: accentPink) {
                guard !recognizedMenuText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    showTranslationUnavailableAlert = true
                    return
                }
                showTranslation = true
            }

            scannerToolButton(title: "Readable", icon: "textformat", tint: accentOrange) {
                useDyslexicFont.toggle()
            }

        }
    }

    private func scannerToolButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12))
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(deepCocoa)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var localRecommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Menu Recommendations", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(deepCocoa)

            Text("Uses Apple Intelligence on supported devices, with a free local fallback. No paid API key is needed.")
                .font(.subheadline)
                .foregroundStyle(deepCocoa.opacity(0.68))

            itemTypeSelector

            if !recommendationError.isEmpty {
                Text(recommendationError)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }

            Button {
                Task { await generateMenuRecommendations() }
            } label: {
                HStack {
                    if isGeneratingRecommendations {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGeneratingRecommendations ? "Reading menu..." : "Recommend Items")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(cocoa, in: Capsule())
                .shadow(color: cocoa.opacity(0.18), radius: 10, y: 6)
            }
            .disabled(isGeneratingRecommendations || recognizedMenuText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(isGeneratingRecommendations || recognizedMenuText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private var itemTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you looking for?")
                .font(.caption.weight(.bold))
                .foregroundStyle(deepCocoa.opacity(0.72))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MenuItemType.allCases) { itemType in
                        Button {
                            selectedMenuItemType = itemType
                            menuRecommendations = []
                            recommendationError = ""
                        } label: {
                            Text(itemType.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedMenuItemType == itemType ? .white : deepCocoa)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 12)
                                .background(selectedMenuItemType == itemType ? cocoa : Color.white.opacity(0.58), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recommendationResults: some View {
        if !menuRecommendations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Best Matches", systemImage: "fork.knife.circle.fill")
                    .font(.headline)
                    .foregroundStyle(deepCocoa)

                ForEach(menuRecommendations) { recommendation in
                    recommendationCard(recommendation)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
        }
    }

    private func recommendationCard(_ recommendation: MenuRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(deepCocoa)
                    Text(recommendation.whyChosen)
                        .font(.subheadline)
                        .foregroundStyle(deepCocoa.opacity(0.72))
                }

                Spacer()

                Text("\(recommendation.matchScore)%")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(scoreColor(recommendation.matchScore), in: Capsule())
            }

            if !recommendation.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Ingredients")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(deepCocoa.opacity(0.65))
                    Text(recommendation.ingredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(deepCocoa.opacity(0.72))
                }
            }

            if !recommendation.cautions.isEmpty {
                Label(recommendation.cautions.joined(separator: " "), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 85...100:
            return .green
        case 65..<85:
            return accentOrange
        default:
            return accentPink
        }
    }

    private func parseScannedMenuItems(from text: String) -> [ScannedMenuDisplayItem] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("page ") }

        var items: [ScannedMenuDisplayItem] = []
        var currentName: String?
        var currentPrice: String?
        var currentDetails: [String] = []

        for line in lines {
            let price = priceInLine(line)
            if isStandalonePriceLine(line), currentName != nil {
                currentPrice = price
                continue
            }

            if looksLikeReadableMenuItem(line) {
                let cleanedName = cleanedReadableMenuName(line)
                guard !cleanedName.isEmpty else { continue }
                if let currentName {
                    items.append(ScannedMenuDisplayItem(name: currentName, price: currentPrice, detail: currentDetails.joined(separator: " ")))
                }
                currentName = cleanedName
                currentPrice = price
                currentDetails = []
            } else if currentName != nil {
                currentDetails.append(line)
                if currentPrice == nil {
                    currentPrice = price
                }
            }
        }

        if let currentName {
            items.append(ScannedMenuDisplayItem(name: currentName, price: currentPrice, detail: currentDetails.joined(separator: " ")))
        }

        if items.isEmpty {
            return lines.prefix(12).map { line in
                ScannedMenuDisplayItem(name: cleanedReadableMenuName(line), price: priceInLine(line), detail: "")
            }
        }

        return items
    }

    private func looksLikeReadableMenuItem(_ line: String) -> Bool {
        guard line.count >= 3, line.count <= 80 else { return false }
        if priceInLine(line) != nil { return true }
        let words = line.split(separator: " ")
        guard words.count <= 8 else { return false }
        let letters = line.filter(\.isLetter).count
        let uppercase = line.filter { $0.isLetter && $0.isUppercase }.count
        return letters > 0 && Double(uppercase) / Double(max(letters, 1)) > 0.40
    }

    private func priceInLine(_ line: String) -> String? {
        let pattern = #"(\$\s?\d+(\.\d{2})?|\b\d{1,3}\.\d{2}\b)"#
        guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
        let price = String(line[range]).replacingOccurrences(of: " ", with: "")
        return price.hasPrefix("$") ? price : "$\(price)"
    }

    private func isStandalonePriceLine(_ line: String) -> Bool {
        guard priceInLine(line) != nil else { return false }
        let withoutPrice = cleanedReadableMenuName(line)
        return withoutPrice.isEmpty || withoutPrice.count <= 2
    }

    private func cleanedReadableMenuName(_ line: String) -> String {
        line
            .replacingOccurrences(of: #"(\$\s?\d+(\.\d{2})?|\b\d{1,3}\.\d{2}\b)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " .-•|"))
    }

    private var menuTranslationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Camera Translation", systemImage: "character.bubble.fill")
                .font(.headline)
                .foregroundStyle(deepCocoa)
            if recognizedMenuText.isEmpty {
                Text(textRecognitionError.isEmpty ? "After you take a photo, MenuMind will read the menu text and let you translate it with Apple translation." : textRecognitionError)
                    .font(.subheadline)
                    .foregroundStyle(deepCocoa.opacity(0.65))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized menu text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(deepCocoa.opacity(0.7))
                    Text(recognizedMenuText)
                        .font(readableFont)
                        .foregroundStyle(deepCocoa)
                        .lineLimit(8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 14))
            }
            if !translatedMenuText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translated menu")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(deepCocoa.opacity(0.7))
                    Text(translatedMenuText)
                        .font(readableFont)
                        .foregroundStyle(deepCocoa)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(softCream.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
            }
            Button {
                guard !recognizedMenuText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    showTranslationUnavailableAlert = true
                    return
                }
                showTranslation = true
            } label: {
                HStack {
                    Image(systemName: "translate")
                    Text("Translate Menu")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(accentPink, in: Capsule())
            }
            .disabled(isRecognizingText)
            .opacity(isRecognizingText ? 0.65 : 1)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private var featureControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scanner Features", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(deepCocoa)
            Picker("Translation", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                }
            }
            .pickerStyle(.menu)
            Toggle("Use OpenDyslexic font", isOn: $useDyslexicFont)
        }
        .padding()
        .foregroundStyle(deepCocoa)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }


    private var menuList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Readable Menu", systemImage: "list.bullet.clipboard.fill")
                .font(.headline)
                .foregroundStyle(deepCocoa)

            if scannedDisplayItems.isEmpty {
                Text("Scan a menu page to show a large-text item list here.")
                    .font(.subheadline)
                    .foregroundStyle(deepCocoa.opacity(0.65))
            } else {
                ForEach(scannedDisplayItems) { item in
                    readableMenuRow(for: item)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private func readableMenuRow(for item: ScannedMenuDisplayItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(readableFont.weight(.bold))
                    .foregroundStyle(deepCocoa)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(readableFont)
                        .foregroundStyle(deepCocoa.opacity(0.72))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.price ?? "")
                .font(readableFont.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(cocoa)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 76, alignment: .trailing)
                .accessibilityHidden(item.price == nil)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
    }

    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Menu Summary", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(deepCocoa)
            if summaryText.isEmpty {
                Text("Get a quick summary of the menu and the safest options based on your selected needs.")
                    .font(.subheadline)
                    .foregroundStyle(deepCocoa.opacity(0.65))
            } else {
                Text(summaryText)
                    .font(readableFont)
                    .foregroundStyle(deepCocoa.opacity(0.78))
            }
            Button {
                summarizeMenu()
            } label: {
                HStack {
                    Image(systemName: isSummarizing ? "hourglass" : "sparkles")
                    Text(isSummarizing ? "Summarizing..." : "Summarize Menu")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(accentPink, in: Capsule())
            }
            .disabled(isSummarizing)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            openPhotoLibraryFallback()
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            imagePickerSourceType = .camera
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        imagePickerSourceType = .camera
                        showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
    }

    private func openPhotoLibraryFallback() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showCameraUnavailable = true
            return
        }
        imagePickerSourceType = .photoLibrary
        showCamera = true
    }

    private func summarizeMenu() {
        isSummarizing = true
        summaryText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let itemNames = scannedDisplayItems.prefix(6).map(\.name).joined(separator: ", ")
            let preferences = UserDefaults.standard.loadTastePreferences()
            let preferenceSummary = preferences.summaryItems.prefix(3).joined(separator: "; ")
            let preferenceText = preferenceSummary.isEmpty ? "your saved preferences" : preferenceSummary
            summaryText = "MenuMind found \(scannedDisplayItems.count) readable menu item(s). Based on \(preferenceText), start with: \(itemNames.isEmpty ? "scan a clearer menu page first" : itemNames). Ask staff to confirm ingredients before ordering."
            isSummarizing = false
        }
    }

    private func clearScannedMenu() {
        capturedMenuImage = nil
        capturedMenuImages = []
        recognizedMenuText = ""
        recognizedMenuLines = []
        translatedMenuText = ""
        textRecognitionError = ""
        menuRecommendations = []
        recommendationError = ""
    }

    private func generateMenuRecommendations() async {
        recommendationError = ""
        menuRecommendations = []
        isGeneratingRecommendations = true
        defer { isGeneratingRecommendations = false }

        let preferences = UserDefaults.standard.loadTastePreferences()
        let recommendations = await MenuRecommendationService().recommendItems(
            menuText: recognizedMenuText,
            preferences: preferences,
            itemType: selectedMenuItemType
        )
        menuRecommendations = recommendations

        if recommendations.isEmpty {
            recommendationError = "MenuMind could not find enough readable menu items. Try scanning a clearer photo."
        }
    }

    private func recognizeMenuText(from image: UIImage) {
        capturedMenuImages.append(image)
        let pageNumber = capturedMenuImages.count
        recognizedMenuLines = []
        translatedMenuText = ""
        textRecognitionError = ""
        recommendationError = ""
        menuRecommendations = []
        isRecognizingText = true
        guard let cgImage = image.cgImage else {
            textRecognitionError = "MenuMind could not read this photo. Try retaking it with the menu in frame."
            isRecognizingText = false
            return
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
            do {
                try handler.perform([request])
                let recognizedLines = request.results?.compactMap { observation -> RecognizedMenuLine? in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return RecognizedMenuLine(text: text, boundingBox: observation.boundingBox)
                } ?? []
                let recognizedText = recognizedLines.map(\.text).joined(separator: "\n")
                await MainActor.run {
                    if !recognizedText.isEmpty {
                        let pageText = "Page \(pageNumber)\n\(recognizedText)"
                        recognizedMenuText = recognizedMenuText.isEmpty ? pageText : "\(recognizedMenuText)\n\n\(pageText)"
                    }
                    recognizedMenuLines = recognizedLines
                    textRecognitionError = recognizedText.isEmpty ? "MenuMind did not find readable text. Try a brighter, closer photo." : ""
                    isRecognizingText = false
                    capturedMenuImage = nil
                }
            } catch {
                await MainActor.run {
                    textRecognitionError = "MenuMind could not read this menu photo. Try retaking it with better lighting."
                    isRecognizingText = false
                    capturedMenuImage = nil
                }
            }
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding private var image: UIImage?
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self._image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            image = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private struct MenuPhotoPreview: View {
    let image: UIImage
    let recognizedLines: [RecognizedMenuLine]
    let useDyslexicFont: Bool

    private var imageAspectRatio: CGFloat {
        guard image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(useDyslexicFont && !recognizedLines.isEmpty ? 0.28 : 1)
            if useDyslexicFont && !recognizedLines.isEmpty {
                GeometryReader { geometry in
                    let imageFrame = fittedImageFrame(in: geometry.size)
                    ForEach(recognizedLines) { line in
                        let rect = displayRect(for: line.boundingBox, in: imageFrame)
                        Text(line.text)
                            .font(OpenDyslexicFont.font(size: fontSize(for: rect)))
                            .foregroundStyle(.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.45)
                            .padding(.horizontal, 3)
                            .frame(width: max(rect.width, 24), height: max(rect.height, 16), alignment: .leading)
                            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 4))
                            .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
        }
        .aspectRatio(imageAspectRatio, contentMode: .fit)
    }

    private func fittedImageFrame(in containerSize: CGSize) -> CGRect {
        let containerAspectRatio = containerSize.width / max(containerSize.height, 1)
        if containerAspectRatio > imageAspectRatio {
            let height = containerSize.height
            let width = height * imageAspectRatio
            return CGRect(
                x: (containerSize.width - width) / 2,
                y: 0,
                width: width,
                height: height
            )
        } else {
            let width = containerSize.width
            let height = width / imageAspectRatio
            return CGRect(
                x: 0,
                y: (containerSize.height - height) / 2,
                width: width,
                height: height
            )
        }
    }

    private func displayRect(for normalizedRect: CGRect, in imageFrame: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + normalizedRect.minX * imageFrame.width,
            y: imageFrame.minY + (1 - normalizedRect.maxY) * imageFrame.height,
            width: normalizedRect.width * imageFrame.width,
            height: normalizedRect.height * imageFrame.height
        )
    }

    private func fontSize(for rect: CGRect) -> CGFloat {
        min(max(rect.height * 0.72, 9), 22)
    }
}

private struct RecognizedMenuLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
}

private struct ScannedMenuDisplayItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let price: String?
    let detail: String
}

private enum OpenDyslexicFont {
    private static let fileName = "OpenDyslexic-Regular"
    private static let fileExtension = "otf"
    private static let postScriptName = "OpenDyslexic-Regular"
    private static var hasRegistered = false

    static func font(size: CGFloat) -> Font {
        registerIfNeeded()
        return .custom(postScriptName, size: size)
    }

    private static func registerIfNeeded() {
        guard !hasRegistered else { return }
        hasRegistered = true
        guard let fontURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            return
        }
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiImageOrientation: UIImage.Orientation) {
        switch uiImageOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}


#Preview {
    HomePageView()
}
