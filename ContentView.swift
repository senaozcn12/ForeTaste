//
//  ContentView.swift
//  MenuMind
//
//  Created by Sena Ozcan on 7/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WelcomeView()
    }
}

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.46, blue: 0.65),
                        Color(red: 1.0, green: 0.62, blue: 0.26),
                        Color(red: 1.0, green: 0.86, blue: 0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                LavaLampBackground()
                    .ignoresSafeArea()

                VStack {
                    Spacer(minLength: geometry.size.height * 0.24)

                    VStack(spacing: 4) {
                        Text("Welcome to")
                            .font(.custom("Avenir Next", size: 28).weight(.medium))
                            .foregroundStyle(Color(red: 0.24, green: 0.16, blue: 0.16)).opacity(0.86)

                        Text("MenuMind")
                            .font(.custom("Avenir Next", size: 52).weight(.heavy))
                            .foregroundStyle(Color(red: 0.52, green: 0.18, blue: 0.20))

                        MenuMindLogoMark()
                            .foregroundStyle(Color(red: 0.52, green: 0.18, blue: 0.20))
                            .frame(width: 118, height: 118)
                            .padding(.top, 34)
                    }

                    Spacer()

                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.52, green: 0.18, blue: 0.20))
                            .frame(width: 250, height: 58, alignment: .center)
                            .background(Color(red: 1.0, green: 0.91, blue: 0.76).opacity(0.88))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color(red: 0.52, green: 0.18, blue: 0.20).opacity(0.12), lineWidth: 1)
                            }
                            .shadow(color: Color(red: 0.52, green: 0.18, blue: 0.20).opacity(0.24), radius: 16, x: 0, y: 10)
                    }
                    .padding(.bottom, 78)
                }
                }
            }
        }
    }
}

private struct MenuMindLogoMark: View {
    var body: some View {
        ZStack {
            HStack(spacing: -7) {
                Image(systemName: "fork.fill")
                    .font(.system(size: 72, weight: .bold))
                Text("m")
                    .font(.system(size: 86, weight: .heavy, design: .rounded))
                    .offset(y: -1)
            }

            Circle()
                .frame(width: 7, height: 7)
                .offset(x: 24, y: 10)
            Circle()
                .frame(width: 7, height: 7)
                .offset(x: 52, y: 10)
            Capsule()
                .frame(width: 25, height: 5)
                .rotationEffect(.degrees(8))
                .offset(x: 38, y: 31)
        }
        .accessibilityHidden(true)
    }
}

private struct LavaLampBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    LavaBlob(
                        color: Color(red: 1.0, green: 0.46, blue: 0.65).opacity(0.32),
                        size: CGSize(width: 310, height: 220),
                        base: CGPoint(x: 0.25, y: 0.22),
                        travel: CGVector(dx: 0.26, dy: 0.22),
                        speed: 0.82,
                        phase: 0.0,
                        time: time,
                        containerSize: geometry.size
                    )
                    LavaBlob(
                        color: Color(red: 1.0, green: 0.62, blue: 0.26).opacity(0.28),
                        size: CGSize(width: 350, height: 250),
                        base: CGPoint(x: 0.76, y: 0.28),
                        travel: CGVector(dx: 0.24, dy: 0.28),
                        speed: 0.66,
                        phase: 1.7,
                        time: time,
                        containerSize: geometry.size
                    )
                    LavaBlob(
                        color: Color(red: 1.0, green: 0.86, blue: 0.35).opacity(0.30),
                        size: CGSize(width: 340, height: 230),
                        base: CGPoint(x: 0.32, y: 0.74),
                        travel: CGVector(dx: 0.30, dy: 0.24),
                        speed: 0.58,
                        phase: 3.2,
                        time: time,
                        containerSize: geometry.size
                    )
                    LavaBlob(
                        color: Color(red: 1.0, green: 0.46, blue: 0.65).opacity(0.20),
                        size: CGSize(width: 270, height: 190),
                        base: CGPoint(x: 0.78, y: 0.78),
                        travel: CGVector(dx: 0.22, dy: 0.20),
                        speed: 0.90,
                        phase: 4.6,
                        time: time,
                        containerSize: geometry.size
                    )
                    LavaBlob(
                        color: Color(red: 0.52, green: 0.18, blue: 0.20).opacity(0.10),
                        size: CGSize(width: 280, height: 190),
                        base: CGPoint(x: 0.50, y: 0.50),
                        travel: CGVector(dx: 0.26, dy: 0.26),
                        speed: 0.50,
                        phase: 2.4,
                        time: time,
                        containerSize: geometry.size
                    )
                }
            }
        }
    }
}

private struct LavaBlob: View {
    let color: Color
    let size: CGSize
    let base: CGPoint
    let travel: CGVector
    let speed: Double
    let phase: Double
    let time: TimeInterval
    let containerSize: CGSize

    var body: some View {
        let progress = time * speed + phase
        let x = containerSize.width * (base.x + travel.dx * sin(progress))
        let y = containerSize.height * (base.y + travel.dy * cos(progress * 0.83))
        let scaleX = 1.0 + 0.12 * sin(progress * 1.4)
        let scaleY = 1.0 + 0.16 * cos(progress * 1.1)
        let rotation = Angle.degrees(18 * sin(progress * 0.7))

        Ellipse()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .blur(radius: 26)
            .scaleEffect(x: scaleX, y: scaleY)
            .rotationEffect(rotation)
            .position(x: x, y: y)
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var resetEmail = ""
    @State private var accountName = ""
    @State private var accountEmail = ""
    @State private var accountPassword = ""
    @State private var showingForgotPassword = false
    @State private var showingCreateAccount = false
    @State private var showingResetConfirmation = false
    @State private var showHomePage = false
    @State private var showTasteSurvey = false
    @State private var statusMessage = ""
    @State private var accountAgreedToTerms = false
    @State private var showingTermsDetails = false

    var body: some View {
        loginScreen()
    }

    private func loginScreen() -> some View {
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

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("MenuMind")
                        .font(.custom("Avenir Next", size: 52).weight(.heavy))
                        .foregroundStyle(Color(red: 0.52, green: 0.18, blue: 0.20))

                    Text("Log into MenuMind")
                        .font(.custom("Avenir Next", size: 21).weight(.semibold))
                        .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))
                }

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))

                    SecureField("Password", text: $password)
                        .padding()
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))

                    Button("Forgot password?") {
                        resetEmail = email
                        showingForgotPassword = true
                    }
                    .font(.custom("Avenir Next", size: 15).weight(.semibold))
                    .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Button {
                        showHomePage = true
                    } label: {
                        Text("Log In")
                            .font(.custom("Avenir Next", size: 18).weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color(red: 0.88, green: 0.22, blue: 0.36))
                    }

                    Button {
                        showHomePage = true
                    } label: {
                        Text("Continue as Guest")
                            .font(.custom("Avenir Next", size: 18).weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.62, green: 0.24, blue: 0.26).opacity(0.65), lineWidth: 1.5)
                            }
                            .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))
                    }

                    VStack(spacing: 10) {
                        Text("New to MenuMind?")
                            .font(.custom("Avenir Next", size: 14).weight(.medium))
                            .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))

                        Button {
                            accountEmail = email
                            showingCreateAccount = true
                        } label: {
                            Text("Create an Account")
                                .font(.custom("Avenir Next", size: 18).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.88, green: 0.22, blue: 0.36), in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 4)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.custom("Avenir Next", size: 13).weight(.medium))
                            .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
                .background(.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            forgotPasswordScreen()
        }
        .sheet(isPresented: $showingCreateAccount) {
            createAccountScreen()
        }
        .navigationDestination(isPresented: $showHomePage) {
            HomePageView()
        }
        .navigationDestination(isPresented: $showTasteSurvey) {
            TasteSurveyView {
                showTasteSurvey = false
                showHomePage = true
            }
        }
        .alert("Password Reset Sent", isPresented: $showingResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your email for instructions to reset your MenuMind password.")
        }
    }

    private func createAccountScreen() -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.custom("Avenir Next", size: 34).weight(.heavy))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Join MenuMind to save your favorites and get back in faster.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Name", text: $accountName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                TextField("Email", text: $accountEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                SecureField("Password", text: $accountPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                TermsAgreementRow(
                    isAgreed: $accountAgreedToTerms,
                    tint: Color(red: 0.62, green: 0.24, blue: 0.26),
                    onTermsTapped: {
                        showingTermsDetails = true
                    }
                )

                Button {
                    if accountAgreedToTerms {
                        email = accountEmail
                        password = accountPassword
                        showingCreateAccount = false
                        showTasteSurvey = true
                    } else {
                        statusMessage = "Please agree to the Terms & Conditions before creating an account."
                        showingTermsDetails = true
                    }
                } label: {
                    Text("Create Account")
                        .font(.custom("Avenir Next", size: 18).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 1.0, green: 0.38, blue: 0.28), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }

                if !statusMessage.isEmpty && !accountAgreedToTerms {
                    Text(statusMessage)
                        .font(.custom("Avenir Next", size: 13).weight(.medium))
                        .foregroundStyle(Color(red: 0.62, green: 0.24, blue: 0.26))
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateAccount = false
                    }
                }
            }
            .sheet(isPresented: $showingTermsDetails) {
                TermsAndConditionsView()
            }
        }
    }

    private func forgotPasswordScreen() -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.custom("Avenir Next", size: 34).weight(.heavy))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Enter the email linked to your MenuMind account.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Email", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                Button {
                    showingForgotPassword = false
                    showingResetConfirmation = true
                } label: {
                    Text("Send Reset Link")
                        .font(.custom("Avenir Next", size: 18).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 1.0, green: 0.38, blue: 0.28), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingForgotPassword = false
                    }
                }
            }
        }
    }
}

struct TermsAgreementRow: View {
    @Binding var isAgreed: Bool
    let tint: Color
    let onTermsTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isAgreed ? "Terms agreed" : "Terms not agreed")

            HStack(spacing: 3) {
                Text("I agree to the")
                Button {
                    onTermsTapped()
                } label: {
                    Text("Terms & Conditions")
                        .underline()
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            .font(.custom("Avenir Next", size: 14).weight(.medium))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(termsText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var termsText: String {
        """
        Terms & Conditions
        Welcome to MenuMind. By creating an account or using our app, you agree to these Terms & Conditions.
        Purpose of MenuMind
        MenuMind is designed to help users make informed dining decisions by providing menu information, personalized recommendations, dietary filtering, accessibility insights, and community reviews.
        While we strive to provide accurate information, MenuMind is an informational tool and should not replace your own judgment or medical advice.
        User Responsibilities
        By using MenuMind, you agree to provide accurate profile information, keep your account secure, use the app respectfully, and not misuse or interfere with the app or its services.
        Food Allergies & Dietary Restrictions
        MenuMind provides recommendations based on information supplied by restaurants, users, and third-party sources. We cannot guarantee that menu information is always complete or up to date.
        Users should always verify ingredients with the restaurant, inform restaurant staff of allergies or dietary restrictions, and exercise personal judgment before consuming food.
        MenuMind is not responsible for allergic reactions, dietary issues, or health outcomes resulting from reliance on app information.
        Accessibility & Sensory Information
        Sensory ratings, accessibility details, and environmental information may come from users, restaurants, or third-party sources. Experiences can vary based on time of day, crowd levels, restaurant renovations, and personal sensitivities.
        Privacy
        Your food preferences, dietary restrictions, accessibility settings, and profile information are used to personalize your experience. We do not sell your personal information.
        AI Recommendations
        MenuMind uses artificial intelligence to generate personalized food and restaurant recommendations. AI recommendations are suggestions only and may not always be accurate or suitable for every individual.
        Limitation of Liability
        MenuMind is provided as is. To the fullest extent permitted by law, MenuMind is not liable for food allergies, allergic reactions, medical emergencies, incorrect menu information, restaurant experiences, or losses resulting from using the app.
        Acceptance
        By using MenuMind, you acknowledge that you have read, understood, and agree to these Terms & Conditions.
        """
    }
}

#Preview {
    WelcomeView()
}
