//
//  UserTastePreferences.swift
//  ForeTaste
//

import Foundation

struct UserTastePreferences: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case hasDietaryRestrictions
        case restrictions
        case allergies
        case mealPlans
        case flavors
        case avoidedTextures
        case favoriteFood
        case safeFoodOptions
    }

    var hasDietaryRestrictions: Bool
    var restrictions: [String]
    var allergies: [String]
    var mealPlans: [String]
    var flavors: [String]
    var avoidedTextures: [String]
    var favoriteFood: String
    var safeFoodOptions: [String]

    init(
        hasDietaryRestrictions: Bool,
        restrictions: [String],
        allergies: [String],
        mealPlans: [String],
        flavors: [String],
        avoidedTextures: [String],
        favoriteFood: String,
        safeFoodOptions: [String]
    ) {
        self.hasDietaryRestrictions = hasDietaryRestrictions
        self.restrictions = restrictions
        self.allergies = allergies
        self.mealPlans = mealPlans
        self.flavors = flavors
        self.avoidedTextures = avoidedTextures
        self.favoriteFood = favoriteFood
        self.safeFoodOptions = safeFoodOptions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasDietaryRestrictions = try container.decodeIfPresent(Bool.self, forKey: .hasDietaryRestrictions) ?? false
        restrictions = try container.decodeIfPresent([String].self, forKey: .restrictions) ?? []
        allergies = try container.decodeIfPresent([String].self, forKey: .allergies) ?? []
        mealPlans = try container.decodeIfPresent([String].self, forKey: .mealPlans) ?? []
        flavors = try container.decodeIfPresent([String].self, forKey: .flavors) ?? []
        avoidedTextures = try container.decodeIfPresent([String].self, forKey: .avoidedTextures) ?? []
        favoriteFood = try container.decodeIfPresent(String.self, forKey: .favoriteFood) ?? ""
        safeFoodOptions = try container.decodeIfPresent([String].self, forKey: .safeFoodOptions) ?? []
    }

    static let empty = UserTastePreferences(
        hasDietaryRestrictions: false,
        restrictions: [],
        allergies: [],
        mealPlans: [],
        flavors: [],
        avoidedTextures: [],
        favoriteFood: "",
        safeFoodOptions: []
    )

    var hasSavedAnswers: Bool {
        hasDietaryRestrictions ||
        !restrictions.isEmpty ||
        !allergies.isEmpty ||
        !mealPlans.isEmpty ||
        !flavors.isEmpty ||
        !avoidedTextures.isEmpty ||
        !favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !safeFoodOptions.isEmpty
    }

    var summaryItems: [String] {
        var items: [String] = []

        if hasDietaryRestrictions && !restrictions.isEmpty {
            items.append("Needs: \(restrictions.joined(separator: ", "))")
        }

        if !allergies.isEmpty {
            items.append("Allergies: \(allergies.joined(separator: ", "))")
        }

        if !mealPlans.isEmpty && !mealPlans.contains("None") {
            items.append("Meal plan: \(mealPlans.joined(separator: ", "))")
        }

        if !flavors.isEmpty {
            items.append("Likes: \(flavors.joined(separator: ", "))")
        }

        if !avoidedTextures.isEmpty {
            items.append("Avoids: \(avoidedTextures.joined(separator: ", "))")
        }

        if !safeFoodOptions.isEmpty {
            items.append("Safe foods: \(safeFoodOptions.joined(separator: ", "))")
        }

        let trimmedFavorite = favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFavorite.isEmpty {
            items.append("Favorite: \(trimmedFavorite)")
        }

        return items
    }
}

extension UserDefaults {
    private static let tastePreferencesKey = "menuMindTastePreferences"

    func saveTastePreferences(_ preferences: UserTastePreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        set(data, forKey: Self.tastePreferencesKey)
    }

    func loadTastePreferences() -> UserTastePreferences {
        guard
            let data = data(forKey: Self.tastePreferencesKey),
            let preferences = try? JSONDecoder().decode(UserTastePreferences.self, from: data)
        else {
            return .empty
        }

        return preferences
    }
}
