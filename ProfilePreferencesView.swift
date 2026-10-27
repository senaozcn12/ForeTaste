//
//  ProfilePreferencesView.swift
//  ForeTaste
//

import SwiftUI

struct ProfilePreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = UserDefaults.standard.loadTastePreferences()
    @State private var newSafeFood = ""
    @State private var newRestriction = ""
    @State private var newAllergy = ""
    @State private var newFlavor = ""
    @State private var newMealPlan = ""
    @State private var newAvoidedTexture = ""

    private let cocoa = Color(red: 0.52, green: 0.18, blue: 0.20)
    private let deepCocoa = Color(red: 0.24, green: 0.16, blue: 0.16)
    private let accentPink = Color(red: 1.0, green: 0.46, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.62, blue: 0.26)
    private let accentYellow = Color(red: 1.0, green: 0.86, blue: 0.35)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                safeFoodsSection
                preferencesSection(title: "Dietary Needs", values: $preferences.restrictions, draft: $newRestriction, placeholder: "Add a dietary need")
                preferencesSection(title: "Allergies", values: $preferences.allergies, draft: $newAllergy, placeholder: "Add an allergy")
                preferencesSection(title: "Meal Plans", values: $preferences.mealPlans, draft: $newMealPlan, placeholder: "Add a meal plan")
                preferencesSection(title: "Flavor Likes", values: $preferences.flavors, draft: $newFlavor, placeholder: "Add a flavor")
                preferencesSection(title: "Avoided Textures", values: $preferences.avoidedTextures, draft: $newAvoidedTexture, placeholder: "Add a texture")
                favoriteFoodSection
            }
            .padding(20)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [accentPink.opacity(0.20), accentOrange.opacity(0.16), accentYellow.opacity(0.18), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    savePreferences()
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(cocoa)
            }
        }
        .onDisappear {
            savePreferences()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your Food Profile", systemImage: "person.crop.circle.fill")
                .font(.title2.bold())
                .foregroundStyle(deepCocoa)

            Text("Edit the foods and preferences MenuMind uses for menu scans and restaurant picks.")
                .font(.subheadline)
                .foregroundStyle(deepCocoa.opacity(0.68))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var safeFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Safe Food Options", icon: "checkmark.seal.fill")

            Text("Add foods you already know work well for you. These get extra weight in AI restaurant picks.")
                .font(.subheadline)
                .foregroundStyle(deepCocoa.opacity(0.62))

            editableChips(values: $preferences.safeFoodOptions)
            addRow(text: $newSafeFood, placeholder: "Add safe food") {
                add(newSafeFood, to: &preferences.safeFoodOptions)
                newSafeFood = ""
            }
        }
        .profileCardStyle()
    }

    private func preferencesSection(title: String, values: Binding<[String]>, draft: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title, icon: "slider.horizontal.3")
            editableChips(values: values)
            addRow(text: draft, placeholder: placeholder) {
                add(draft.wrappedValue, to: &values.wrappedValue)
                draft.wrappedValue = ""
            }
        }
        .profileCardStyle()
    }

    private var favoriteFoodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Favorite Food", icon: "fork.knife")

            TextField("Favorite food", text: $preferences.favoriteFood)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(deepCocoa)
        }
        .profileCardStyle()
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(deepCocoa)
    }

    private func editableChips(values: Binding<[String]>) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(values.wrappedValue, id: \.self) { value in
                Button {
                    values.wrappedValue.removeAll { $0 == value }
                } label: {
                    HStack(spacing: 6) {
                        Text(value)
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(deepCocoa)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.66), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func addRow(text: Binding<String>, placeholder: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 12))

            Button(action: action) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(accentOrange, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func add(_ value: String, to values: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !values.contains(trimmed) else { return }
        values.append(trimmed)
    }

    private func savePreferences() {
        preferences.hasDietaryRestrictions = !preferences.restrictions.isEmpty || !preferences.allergies.isEmpty
        UserDefaults.standard.saveTastePreferences(preferences)
    }
}

private extension View {
    func profileCardStyle() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.58), lineWidth: 1)
            }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePreferencesView()
    }
}
