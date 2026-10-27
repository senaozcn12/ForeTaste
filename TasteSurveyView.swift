//
//  TasteSurveyView.swift
//  MenuMind
//

import SwiftUI

struct TasteSurveyView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var hasDietaryRestrictions: Bool?
    @State private var selectedRestrictions: Set<String> = []
    @State private var otherRestriction = ""
    @State private var selectedAllergies: Set<String> = []
    @State private var otherAllergy = ""
    @State private var selectedMealPlans: Set<String> = []
    @State private var otherMealPlan = ""
    @State private var selectedFlavors: Set<String> = []
    @State private var otherFlavor = ""
    @State private var selectedAvoidedTextures: Set<String> = []
    @State private var otherAvoidedTexture = ""
    @State private var favoriteFood = ""
    @State private var isGeneratingPalette = false

    private let restrictions = ["Allergies", "Celiac", "Lactose intolerance / Dairy allergy", "Vegan", "Vegetarian", "Pescatarian", "Other"]
    private let allergies = ["Peanuts", "Tree nuts", "Milk", "Eggs", "Soy", "Wheat", "Fish", "Shellfish", "Sesame", "Other"]
    private let mealPlans = ["Kosher", "Halal", "Jainism", "None", "Other"]
    private let flavors = ["Sweet", "Salty", "Sour", "Bitter", "Spice", "Savory", "Smokey", "Umami", "Other"]
    private let avoidedTextures = ["Grainy", "Sticky", "Gel-Like", "Mushy", "Crispy", "Crunchy", "Mixed textures", "Other"]

    private var surveySteps: [SurveyStep] {
        var steps: [SurveyStep] = [.intro, .dietaryRestrictions]

        if hasDietaryRestrictions == true {
            steps.append(.restrictionDetails)
        }

        if selectedRestrictions.contains("Allergies") {
            steps.append(.allergies)
        }

        steps += [.mealPlans, .flavors, .avoidedTextures, .favoriteFood]
        return steps
    }

    private var activeStep: SurveyStep {
        surveySteps[min(currentStep, surveySteps.count - 1)]
    }

    private var progressValue: Double {
        guard surveySteps.count > 1 else { return 0 }
        return Double(currentStep) / Double(surveySteps.count - 1)
    }

    private var canContinue: Bool {
        switch activeStep {
        case .intro:
            return true
        case .dietaryRestrictions:
            return hasDietaryRestrictions != nil
        case .restrictionDetails:
            return !selectedRestrictions.isEmpty && (!selectedRestrictions.contains("Other") || !otherRestriction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .allergies:
            return !selectedAllergies.isEmpty && (!selectedAllergies.contains("Other") || !otherAllergy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .mealPlans:
            return !selectedMealPlans.isEmpty && (!selectedMealPlans.contains("Other") || !otherMealPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .flavors:
            return !selectedFlavors.isEmpty && (!selectedFlavors.contains("Other") || !otherFlavor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .avoidedTextures:
            return !selectedAvoidedTextures.isEmpty && (!selectedAvoidedTextures.contains("Other") || !otherAvoidedTexture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .favoriteFood:
            return !favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.46, blue: 0.65),
                    Color(red: 1.0, green: 0.62, blue: 0.26),
                    Color(red: 1.0, green: 0.86, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isGeneratingPalette {
                generatingView
            } else {
                surveyView
            }
        }
        .font(.custom("Avenir Next", size: 17))
        .navigationBarBackButtonHidden(isGeneratingPalette)
    }

    private var surveyView: some View {
        VStack(spacing: 22) {
            progressBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    stepContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            navigationControls
        }
        .padding(24)
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MenuMind Survey")
                    .font(.custom("Avenir Next", size: 18).weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(min(currentStep + 1, surveySteps.count))/\(surveySteps.count)")
                    .font(.custom("Avenir Next", size: 14).weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.28))

                    Capsule()
                        .fill(.white)
                        .frame(width: max(12, geometry.size.width * progressValue))
                        .animation(.easeInOut(duration: 0.25), value: progressValue)
                }
            }
            .frame(height: 10)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch activeStep {
        case .intro:
            introContent
        case .dietaryRestrictions:
            questionContent(
                title: "Do you have any dietary restrictions?",
                subtitle: "This helps MenuMind keep your menu recommendations useful from the start."
            ) {
                yesNoSelector
            }
        case .restrictionDetails:
            questionContent(title: "Select your dietary restrictions", subtitle: "Choose all that apply.") {
                multiSelectGrid(options: restrictions, selection: $selectedRestrictions)
                conditionalTextField(title: "Other restriction", text: $otherRestriction, isVisible: selectedRestrictions.contains("Other"))
            }
        case .allergies:
            questionContent(title: "What allergies do you have?", subtitle: "Choose all that apply.") {
                multiSelectGrid(options: allergies, selection: $selectedAllergies)
                conditionalTextField(title: "Other allergy", text: $otherAllergy, isVisible: selectedAllergies.contains("Other"))
            }
        case .mealPlans:
            questionContent(title: "Do you follow any religious or cultural meal plans?", subtitle: "Choose all that apply.") {
                multiSelectGrid(options: mealPlans, selection: $selectedMealPlans)
                conditionalTextField(title: "Other meal plan", text: $otherMealPlan, isVisible: selectedMealPlans.contains("Other"))
            }
        case .flavors:
            questionContent(title: "What are your preferred tastes in food?", subtitle: "Choose all that apply.") {
                multiSelectGrid(options: flavors, selection: $selectedFlavors)
                conditionalTextField(title: "Other taste", text: $otherFlavor, isVisible: selectedFlavors.contains("Other"))
            }
        case .avoidedTextures:
            questionContent(title: "What textures would you like to avoid?", subtitle: "Choose all that apply.") {
                multiSelectGrid(options: avoidedTextures, selection: $selectedAvoidedTextures)
                conditionalTextField(title: "Other texture", text: $otherAvoidedTexture, isVisible: selectedAvoidedTextures.contains("Other"))
            }
        case .favoriteFood:
            questionContent(title: "Name your favorite food at the moment", subtitle: "Tell MenuMind what has been hitting the spot lately.") {
                TextField("Enter your favorite food", text: $favoriteFood)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.black)
            }
        }
    }

    private var introContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 36)

            Text("Now, let's get to know a little bit about you!")
                .font(.custom("Avenir Next", size: 35).weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Let's make every bite feel right")
                .font(.custom("Avenir Next", size: 23).weight(.medium))
                .foregroundStyle(.white.opacity(0.92))

            Text("Complete this personalized survey to unlock your MenuMind menu experience.")
                .font(.custom("Avenir Next", size: 17))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.top, 10)

            Spacer(minLength: 36)
        }
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .leading)
    }

    private var yesNoSelector: some View {
        HStack(spacing: 12) {
            yesNoButton(title: "Yes", value: true)
            yesNoButton(title: "No", value: false)
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button("Back") {
                    currentStep = max(currentStep - 1, 0)
                }
                .buttonStyle(SecondarySurveyButtonStyle())
            }

            Button(currentStep == surveySteps.count - 1 ? "Finish" : activeStep == .intro ? "Take Survey" : "Continue") {
                advanceSurvey()
            }
            .buttonStyle(PrimarySurveyButtonStyle())
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.55)
        }
    }

    private var generatingView: some View {
        VStack(spacing: 22) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.35)

            Text("Generating your taste palette!")
                .font(.custom("Avenir Next", size: 31).weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("MenuMind is shaping your menu around what feels right for you.")
                .font(.custom("Avenir Next", size: 17))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(28)
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            onComplete()
        }
    }

    private func questionContent<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.custom("Avenir Next", size: 28).weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.custom("Avenir Next", size: 16))
                .foregroundStyle(.white.opacity(0.88))

            content()
        }
        .padding(.top, 18)
    }

    private func multiSelectGrid(options: [String], selection: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.wrappedValue.contains(option)

                Button {
                    toggle(option, in: selection)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold))

                        Text(option)
                            .font(.custom("Avenir Next", size: 15).weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(isSelected ? Color(red: 0.86, green: 0.23, blue: 0.38) : Color(red: 0.24, green: 0.16, blue: 0.16))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 50)
                    .background(isSelected ? .white : .white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func conditionalTextField(title: String, text: Binding<String>, isVisible: Bool) -> some View {
        Group {
            if isVisible {
                TextField(title, text: text)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.black)
            }
        }
    }

    private func yesNoButton(title: String, value: Bool) -> some View {
        Button {
            hasDietaryRestrictions = value
            if value == false {
                selectedRestrictions.removeAll()
                otherRestriction = ""
                selectedAllergies.removeAll()
                otherAllergy = ""
            }
        } label: {
            Text(title)
                .font(.custom("Avenir Next", size: 17).weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(hasDietaryRestrictions == value ? Color(red: 0.86, green: 0.23, blue: 0.38) : Color(red: 0.24, green: 0.16, blue: 0.16))
                .background(hasDietaryRestrictions == value ? .white : .white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ option: String, in selection: Binding<Set<String>>) {
        if selection.wrappedValue.contains(option) {
            selection.wrappedValue.remove(option)
        } else {
            if option == "None" {
                selection.wrappedValue = [option]
            } else {
                selection.wrappedValue.remove("None")
                selection.wrappedValue.insert(option)
            }
        }
    }

    private func advanceSurvey() {
        guard canContinue else { return }

        if currentStep == surveySteps.count - 1 {
            savePreferences()
            isGeneratingPalette = true
        } else {
            currentStep += 1
        }
    }

    private func savePreferences() {
        let preferences = UserTastePreferences(
            hasDietaryRestrictions: hasDietaryRestrictions == true,
            restrictions: values(from: selectedRestrictions, otherValue: otherRestriction),
            allergies: values(from: selectedAllergies, otherValue: otherAllergy),
            mealPlans: values(from: selectedMealPlans, otherValue: otherMealPlan),
            flavors: values(from: selectedFlavors, otherValue: otherFlavor),
            avoidedTextures: values(from: selectedAvoidedTextures, otherValue: otherAvoidedTexture),
            favoriteFood: favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines),
            safeFoodOptions: []
        )
        UserDefaults.standard.saveTastePreferences(preferences)
    }

    private func values(from selection: Set<String>, otherValue: String) -> [String] {
        let trimmedOther = otherValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return selection
            .filter { $0 != "Other" }
            .sorted() + (trimmedOther.isEmpty ? [] : [trimmedOther])
    }
}

private enum SurveyStep {
    case intro
    case dietaryRestrictions
    case restrictionDetails
    case allergies
    case mealPlans
    case flavors
    case avoidedTextures
    case favoriteFood
}

private struct PrimarySurveyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Avenir Next", size: 17).weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(Color(red: 0.85, green: 0.22, blue: 0.37))
            .background(.white, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondarySurveyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Avenir Next", size: 17).weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    TasteSurveyView(onComplete: { })
}
