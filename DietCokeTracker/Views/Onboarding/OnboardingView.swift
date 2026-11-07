import SwiftUI

/// The drink a new user picked as their usual during onboarding.
struct OnboardingFirstDrink {
    let brand: BeverageBrand
    let type: DrinkType
}

struct OnboardingView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var identityService: IdentityService
    /// `firstDrink` is non-nil when the user chose to log their first drink now;
    /// it seeds the add-drink form.
    let onComplete: (_ firstDrink: OnboardingFirstDrink?) -> Void
    @State private var currentPage = 0
    @State private var selectedBrand: BeverageBrand = .dietCoke
    @State private var selectedType: DrinkType = .regularCan
    @State private var displayName = IdentityService.suggestedDisplayName()
    @State private var suggestedName = ""
    @State private var selectedEmoji: String?
    @State private var isFinishing = false
    @Environment(\.colorScheme) private var colorScheme

    private let totalPages = 3

    private var isLastPage: Bool { currentPage == totalPages - 1 }

    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    UsualDrinkPage(selectedBrand: $selectedBrand, selectedType: $selectedType)
                        .tag(1)

                    NamePage(displayName: $displayName, selectedEmoji: $selectedEmoji)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? themeManager.primaryColor : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    Button {
                        if isLastPage {
                            completeOnboarding(logNow: true)
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Group {
                            if isFinishing {
                                ProgressView().tint(.white)
                            } else {
                                Text(primaryButtonTitle)
                            }
                        }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isLastPage ? selectedBrand.buttonGradient : LinearGradient(
                                colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .clipShape(Capsule())
                    }
                    .disabled(isFinishing)
                    .padding(.horizontal, 32)

                    // Not everyone has a drink in hand on first launch; let them
                    // in without inventing a log.
                    if isLastPage {
                        Button("Not right now") {
                            completeOnboarding(logNow: false)
                        }
                        .disabled(isFinishing)
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                    } else {
                        // Spacer to maintain layout
                        Text(" ")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            TelemetryService.onboardingStarted()
        }
        .onChange(of: currentPage) { _, page in
            TelemetryService.onboardingPageViewed(page: page)
            // A reinstall may have restored a profile from iCloud; show that
            // name rather than inventing a new one.
            if page == 2, identityService.state == .ready,
               let existing = identityService.currentProfile?.displayName {
                displayName = existing
            }
            if suggestedName.isEmpty {
                suggestedName = displayName
            }
        }
    }

    private var primaryButtonTitle: String {
        switch currentPage {
        case 0: return "Get Started"
        case totalPages - 1: return "Log My First Drink"
        default: return "Continue"
        }
    }

    private func completeOnboarding(logNow: Bool) {
        isFinishing = true
        Task {
            // The profile must exist before the first drink is saved, or that
            // drink (and its photo) never reaches the feeds.
            await ensureProfile()
            preferences.defaultBrand = selectedBrand
            preferences.markOnboardingComplete()
            TelemetryService.onboardingCompleted(brand: selectedBrand, drinkType: selectedType, loggedFirstDrink: logNow)
            isFinishing = false
            onComplete(logNow ? OnboardingFirstDrink(brand: selectedBrand, type: selectedType) : nil)
        }
    }

    private func ensureProfile() async {
        // Identity restore from iCloud runs at launch; don't race it into
        // creating a duplicate profile.
        for _ in 0..<25 where identityService.state == .loading {
            try? await Task.sleep(for: .milliseconds(200))
        }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? suggestedName : trimmed

        if identityService.state == .ready {
            if name != identityService.currentProfile?.displayName {
                try? await identityService.updateDisplayName(name)
            }
        } else {
            do {
                try await identityService.createIdentity(displayName: name)
                TelemetryService.profileCreated()
                TelemetryService.onboardingProfileCreated(editedName: name != suggestedName, hasEmoji: selectedEmoji != nil)
            } catch {
                // Social setup is still reachable from the Social tab.
                AppLogger.identity.error("Onboarding profile creation failed: \(error.localizedDescription)")
                return
            }
        }

        if let emoji = selectedEmoji, var profile = identityService.currentProfile {
            profile.profileEmoji = emoji
            identityService.currentProfile = profile
            try? await identityService.saveProfile()
        }
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    @EnvironmentObject var globalFeedService: GlobalFeedService
    @State private var isAnimating = false
    @State private var communityPhotos: [UIImage] = []

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated logo/icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dietCokeRed.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 110
                        )
                    )
                    .frame(width: 170, height: 170)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                // App icon
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.dietCokeRed.opacity(0.5), radius: 20, y: 10)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            VStack(spacing: 10) {
                Text("FridgeCig")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("For people who take their Diet Coke\nand Coke Zero seriously.")
                    .font(.body)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                WelcomeValueRow(icon: "flame.fill", color: .orange, text: "Build a daily streak in one tap")
                WelcomeValueRow(icon: "trophy.fill", color: .yellow, text: "Climb the leaderboard")
                WelcomeValueRow(icon: "flag.checkered", color: .blue, text: "Collect all 52 state cans")
            }
            .padding(.horizontal, 40)

            if !communityPhotos.isEmpty {
                communityStrip
                    .transition(.opacity)
            }

            Spacer()
            Spacer()
        }
        .padding()
        .task {
            await loadCommunityPhotos()
        }
    }

    /// Real photos from the Global feed — shows what the community is before
    /// asking anyone to join it.
    private var communityStrip: some View {
        VStack(spacing: 8) {
            HStack(spacing: -10) {
                ForEach(Array(communityPhotos.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                }
            }
            .accessibilityHidden(true)

            Text("See what everyone's sipping")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeDarkSilver)
        }
    }

    private func loadCommunityPhotos() async {
        await globalFeedService.refresh()
        var loaded: [UIImage] = []
        for item in globalFeedService.items {
            guard loaded.count < 5, let photoURL = item.payload.photoURL else { continue }
            if let image = await globalFeedService.fetchPhoto(recordName: photoURL) {
                loaded.append(image)
            }
        }
        withAnimation(.easeOut(duration: 0.3)) {
            communityPhotos = loaded
        }
    }
}

private struct WelcomeValueRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.15)))

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Name Page

private struct NamePage: View {
    @Binding var displayName: String
    @Binding var selectedEmoji: String?
    @State private var showingEmojiPicker = false
    @FocusState private var isNameFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("How should the\ncommunity see you?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.dietCokeCharcoal)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Your name on the leaderboard and the Global feed.\nYou can change it anytime.")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 32)

                Button {
                    showingEmojiPicker = true
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.dietCokeRed.opacity(0.12))
                                .frame(width: 96, height: 96)

                            if let selectedEmoji {
                                Text(selectedEmoji)
                                    .font(.system(size: 48))
                            } else {
                                Text(initial)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.dietCokeRed)
                            }
                        }

                        Text(selectedEmoji == nil ? "Pick an emoji" : "Change emoji")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeRed)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedEmoji == nil ? "Pick an emoji avatar" : "Change emoji avatar")

                TextField("Display name", text: $displayName)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.dietCokeSilver.opacity(0.25), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerSheet { emoji in
                selectedEmoji = emoji
            }
        }
    }

    private var initial: String {
        displayName.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }
}

// MARK: - Usual Drink Page

private struct UsualDrinkPage: View {
    @Binding var selectedBrand: BeverageBrand
    @Binding var selectedType: DrinkType

    /// The handful of formats that cover nearly every log; the full list
    /// stays a tap away in the add-drink form.
    private let commonTypes: [DrinkType] = [.regularCan, .miniCan, .bottle20oz, .fountainMedium]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What's your usual?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.dietCokeCharcoal)

                    Text("We'll have it ready every time you log.\nYou can always pick something else.")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 10) {
                    ForEach(BeverageBrand.allCases) { brand in
                        BrandOptionRow(brand: brand, isSelected: selectedBrand == brand) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedBrand = brand
                            }
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(commonTypes) { type in
                        DrinkTypeOption(type: type, brand: selectedBrand, isSelected: selectedType == type) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedType = type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct DrinkTypeOption: View {
    let type: DrinkType
    let brand: BeverageBrand
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    /// "Fountain Medium" is too long for a half-width tile; size is a detail
    /// the add-drink form handles.
    private var label: String {
        type == .fountainMedium ? "Fountain" : type.displayName
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                DrinkIconView(drinkType: type, size: DrinkIconSize.md)
                    .frame(width: 26, height: 26)
                    .foregroundColor(brand.color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? brand.color.opacity(colorScheme == .dark ? 0.15 : 0.08)
                          : (colorScheme == .dark ? Color(white: 0.12) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? brand.color.opacity(0.5) : Color.dietCokeSilver.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct BrandOptionRow: View {
    let brand: BeverageBrand
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [brand.color.opacity(0.2), brand.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    BrandIconView(brand: brand, size: DrinkIconSize.lg)
                        .foregroundColor(brand.color)
                }

                Text(brand.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [brand.color, brand.color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.title2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? brand.color.opacity(colorScheme == .dark ? 0.15 : 0.08)
                          : (colorScheme == .dark ? Color(white: 0.12) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? brand.color.opacity(0.5) : Color.dietCokeSilver.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview {
    OnboardingView(onComplete: { _ in })
        .withPreviewEnvironment(populated: false)
}
#endif
