//
//  MenuRecommendationService.swift
//  ForeTaste
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct MenuRecommendation: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let matchScore: Int
    let whyChosen: String
    let ingredients: [String]
    let cautions: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case matchScore
        case whyChosen
        case ingredients
        case cautions
    }
}

struct MenuRecommendationService {
    func recommendItems(menuText: String, preferences: UserTastePreferences, itemType: MenuItemType) async -> [MenuRecommendation] {
        let trimmedMenu = menuText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMenu.isEmpty else { return [] }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let appleRecommendations = try? await AppleIntelligenceMenuRecommender().recommendItems(menuText: trimmedMenu, preferences: preferences, itemType: itemType), !appleRecommendations.isEmpty {
                return appleRecommendations
            }
        }
        #endif

        return LocalMenuRecommender().recommendItems(menuText: trimmedMenu, preferences: preferences, itemType: itemType)
    }
}

enum MenuItemType: String, CaseIterable, Identifiable {
    case any
    case meal
    case appetizer
    case snack
    case drink
    case dessert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: return "Any"
        case .meal: return "Meal"
        case .appetizer: return "Appetizer"
        case .snack: return "Snack"
        case .drink: return "Drink"
        case .dessert: return "Dessert"
        }
    }

    var promptDescription: String {
        switch self {
        case .any: return "any suitable menu item"
        case .meal: return "a full meal or entree, not appetizers, snacks, drinks, or desserts"
        case .appetizer: return "an appetizer or starter, not a full meal, drink, or dessert"
        case .snack: return "a light snack or small bite, not a full meal or drink"
        case .drink: return "a beverage or drink only"
        case .dessert: return "a dessert or sweet item only"
        }
    }

    var positiveTerms: [String] {
        switch self {
        case .any: return []
        case .meal: return ["entree", "entrée", "main", "plate", "bowl", "burger", "sandwich", "pasta", "pizza", "chicken", "steak", "fish", "salmon", "rice", "tacos", "wrap"] 
        case .appetizer: return ["appetizer", "starter", "small plate", "share", "dip", "wings", "fries", "nachos", "bruschetta", "dumpling", "soup", "salad"]
        case .snack: return ["snack", "side", "small", "bites", "fries", "chips", "fruit", "cup", "mini"]
        case .drink: return ["drink", "beverage", "coffee", "tea", "juice", "smoothie", "soda", "lemonade", "water", "latte", "cocktail", "mocktail"]
        case .dessert: return ["dessert", "cake", "pie", "cookie", "brownie", "ice cream", "gelato", "pudding", "chocolate", "sweet", "cheesecake"]
        }
    }

    var negativeTerms: [String] {
        switch self {
        case .any: return []
        case .meal: return MenuItemType.appetizer.positiveTerms + MenuItemType.drink.positiveTerms + MenuItemType.dessert.positiveTerms
        case .appetizer: return MenuItemType.drink.positiveTerms + MenuItemType.dessert.positiveTerms + ["entree", "entrée", "main"]
        case .snack: return MenuItemType.drink.positiveTerms + ["entree", "entrée", "main", "plate"]
        case .drink: return MenuItemType.meal.positiveTerms + MenuItemType.appetizer.positiveTerms + MenuItemType.dessert.positiveTerms
        case .dessert: return MenuItemType.meal.positiveTerms + MenuItemType.appetizer.positiveTerms + MenuItemType.drink.positiveTerms
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private struct AppleIntelligenceMenuRecommender {
    func recommendItems(menuText: String, preferences: UserTastePreferences, itemType: MenuItemType) async throws -> [MenuRecommendation] {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return []
        }

        let session = LanguageModelSession(instructions: """
        You are MenuMind. Recommend menu items using only the scanned menu text and the user's food profile. Return compact JSON only.
        """)

        let response = try await session.respond(to: prompt(menuText: menuText, preferences: preferences, itemType: itemType))
        guard let data = response.content.trimmingCodeFence().data(using: .utf8) else { return [] }
        let payload = try JSONDecoder().decode(MenuRecommendationPayload.self, from: data)
        return payload.recommendations.map { item in
            MenuRecommendation(
                name: item.name,
                matchScore: min(max(item.matchScore, 0), 100),
                whyChosen: item.whyChosen,
                ingredients: item.ingredients,
                cautions: item.cautions
            )
        }
    }

    private func prompt(menuText: String, preferences: UserTastePreferences, itemType: MenuItemType) -> String {
        """
        User profile:
        Restrictions: \(preferences.restrictions.joined(separator: ", "))
        Allergies: \(preferences.allergies.joined(separator: ", "))
        Meal plans: \(preferences.mealPlans.joined(separator: ", "))
        Likes: \(preferences.flavors.joined(separator: ", "))
        Avoided textures: \(preferences.avoidedTextures.joined(separator: ", "))
        Favorite food: \(preferences.favoriteFood)
        Safe foods: \(preferences.safeFoodOptions.joined(separator: ", "))
        User wants: \(itemType.promptDescription)

        Scanned menu:
        \(menuText.prefix(6000))

        Return JSON exactly like:
        {"recommendations":[{"name":"item","matchScore":90,"whyChosen":"reason","ingredients":["ingredient"],"cautions":["verify with staff"]}]}
        Return 3 to 5 items matching "User wants". Do not use markdown. Do not invent items not in the menu.
        """
    }
}
#endif

private struct LocalMenuRecommender {
    func recommendItems(menuText: String, preferences: UserTastePreferences, itemType: MenuItemType) -> [MenuRecommendation] {
        let items = parsedMenuItems(from: menuText)
        let profileTerms = normalizedTerms(from: preferences)
        let allergyTerms = preferences.allergies.map { $0.lowercased() }
        let avoidedTerms = (preferences.avoidedTextures + preferences.restrictions).map { $0.lowercased() }

        let scored = items.map { item -> MenuRecommendation in
            let searchable = item.searchableText.lowercased()
            let matches = profileTerms.filter { searchable.contains($0) }
            let allergyHits = allergyTerms.filter { searchable.contains($0) }
            let avoidedHits = avoidedTerms.filter { searchable.contains($0) }
            let categoryBonus = categoryScore(for: searchable, itemType: itemType)
            let score = max(25, min(96, 62 + matches.count * 8 + categoryBonus - allergyHits.count * 18 - avoidedHits.count * 6))

            let reason: String
            if matches.isEmpty {
                reason = "This looks like a flexible \(itemType.title.lowercased()) option based on the scanned text. Confirm details with staff before ordering."
            } else {
                reason = "Chosen as a \(itemType.title.lowercased()) option because it matches your profile terms: \(matches.prefix(3).joined(separator: ", "))."
            }

            let cautions = allergyHits.isEmpty
                ? ["Menu scans can miss ingredients. Verify allergens and preparation with staff."]
                : ["Possible allergy concern: \(allergyHits.joined(separator: ", ")). Verify before ordering."]

            return MenuRecommendation(
                name: item.name,
                matchScore: score,
                whyChosen: reason,
                ingredients: item.ingredients,
                cautions: cautions
            )
        }

        return scored
            .sorted { $0.matchScore > $1.matchScore }
            .prefix(5)
            .map { $0 }
    }

    private func parsedMenuItems(from menuText: String) -> [ParsedMenuItem] {
        let lines = menuText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("page ") }

        var items: [ParsedMenuItem] = []
        var currentName: String?
        var currentDetails: [String] = []

        for line in lines {
            if looksLikeMenuItemName(line) {
                if let currentName {
                    items.append(ParsedMenuItem(name: currentName, details: currentDetails))
                }
                currentName = cleanedName(line)
                currentDetails = []
            } else if currentName != nil {
                currentDetails.append(line)
            }
        }

        if let currentName {
            items.append(ParsedMenuItem(name: currentName, details: currentDetails))
        }

        if items.isEmpty {
            return lines.prefix(8).map { ParsedMenuItem(name: cleanedName($0), details: []) }
        }

        return items
    }

    private func looksLikeMenuItemName(_ line: String) -> Bool {
        guard line.count >= 3, line.count <= 70 else { return false }
        if line.contains("$") { return true }
        let words = line.split(separator: " ")
        guard words.count <= 7 else { return false }
        let uppercaseLetters = line.filter { $0.isLetter && $0.isUppercase }.count
        let letters = line.filter(\.isLetter).count
        return letters > 0 && Double(uppercaseLetters) / Double(max(letters, 1)) > 0.45
    }

    private func cleanedName(_ line: String) -> String {
        line
            .replacingOccurrences(of: #"\s+\$?\d+(\.\d{2})?$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedTerms(from preferences: UserTastePreferences) -> [String] {
        (preferences.safeFoodOptions + preferences.flavors + preferences.mealPlans + [preferences.favoriteFood])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && $0 != "none" }
            .removingDuplicates()
    }

    private func categoryScore(for text: String, itemType: MenuItemType) -> Int {
        guard itemType != .any else { return 0 }
        let positiveMatch = itemType.positiveTerms.contains { text.contains($0) }
        let negativeMatch = itemType.negativeTerms.contains { text.contains($0) }

        switch (positiveMatch, negativeMatch) {
        case (true, false): return 22
        case (true, true): return 8
        case (false, true): return -28
        case (false, false): return -6
        }
    }
}

private struct ParsedMenuItem {
    let name: String
    let details: [String]

    var ingredients: [String] {
        details
            .joined(separator: ", ")
            .components(separatedBy: CharacterSet(charactersIn: ",;•|/"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(8)
            .map { $0 }
    }

    var searchableText: String {
        ([name] + details).joined(separator: " ")
    }
}

private struct MenuRecommendationPayload: Decodable {
    let recommendations: [MenuRecommendationDTO]
}

private struct MenuRecommendationDTO: Decodable {
    let name: String
    let matchScore: Int
    let whyChosen: String
    let ingredients: [String]
    let cautions: [String]
}

private extension String {
    func trimmingCodeFence() -> String {
        var text = trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") {
            text.removeFirst("```json".count)
        } else if text.hasPrefix("```") {
            text.removeFirst("```".count)
        }
        if text.hasSuffix("```") {
            text.removeLast("```".count)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
