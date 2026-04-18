import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPackage: Package?
    @State private var errorMessage: String?
    @State private var animateHero = false

    private var streakDays: Int { store.streakDays }
    private var totalDrinks: Int { store.allTimeCount }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Non-scrolling content fills available space
                    VStack(spacing: 16) {
                        heroSection
                        featureCarousel
                    }
                    .frame(maxHeight: .infinity)

                    purchaseSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.secondary, colorScheme == .dark ? Color(white: 0.2) : Color(.systemGray5))
                    }
                }
            }
        }
        .onAppear {
            autoSelectPackage()
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateHero = true
            }
        }
        .onChange(of: purchaseService.offerings?.current?.availablePackages.count) { _, _ in
            autoSelectPackage()
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.06, green: 0.06, blue: 0.08)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dietCokeRed.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateHero ? 1.0 : 0.6)
                    .opacity(animateHero ? 1 : 0)

                VStack(spacing: 6) {
                    if streakDays > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(animateHero ? 1.0 : 0.5)

                        Text("\(streakDays)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(.dietCokeCharcoal)

                        Text("day streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeDarkSilver)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0), Color(red: 0.9, green: 0.7, blue: 0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHero ? 1.0 : 0.5)

                        Text("Go Pro")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.dietCokeCharcoal)
                    }
                }
            }

            // Personal hook
            Text(heroMessage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 16)
    }

    private var heroMessage: String {
        if streakDays >= 7 {
            return "Your \(streakDays)-day streak deserves protection."
        } else if streakDays > 0 {
            return "Don't let your streak slip away."
        } else if totalDrinks >= 10 {
            return "You've logged \(totalDrinks) drinks. Level up your experience."
        } else {
            return "Unlock the full FridgeCig experience."
        }
    }

    // MARK: - Feature Carousel

    private let features: [(icon: String, title: String, subtitle: String, gradient: [Color])] = [
        ("snowflake", "Streak Freezes", "3 per month. Auto-activates\nwhen you miss a day.", [.cyan, .blue]),
        ("rectangle.3.offgrid.fill", "Home Widgets", "Track your DCs at a glance\nright from your home screen.", [.red, .orange]),
        ("applewatch", "Apple Watch", "Log drinks from your wrist.\nInstant, effortless tracking.", [.green, .mint]),
        ("paintpalette.fill", "Premium Themes", "Customize your app with\nexclusive color themes.", [.purple, .pink]),
        ("heart.text.square.fill", "Health Sync", "Auto-log caffeine intake\nto Apple Health.", [.pink, .red]),
    ]

    @State private var currentFeature = 0

    private var featureCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $currentFeature) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    CarouselCard(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        gradient: feature.gradient,
                        colorScheme: colorScheme
                    )
                    .tag(index)
                    .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 130)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentFeature ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.4))
                        .frame(width: index == currentFeature ? 8 : 6, height: index == currentFeature ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentFeature)
                }
            }
        }
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Divider()

            // Packages
            VStack(spacing: 8) {
                if let offerings = purchaseService.offerings,
                   let packages = offerings.current?.availablePackages {
                    ForEach(packages, id: \.identifier) { package in
                        PackageButton(
                            package: package,
                            isSelected: selectedPackage?.identifier == package.identifier,
                            allPackages: packages
                        ) {
                            selectedPackage = package
                        }
                    }
                } else {
                    ProgressView()
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)

            // CTA
            Button {
                Task { await purchase() }
            } label: {
                if purchaseService.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text(purchaseButtonText)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: selectedPackage != nil ? [Color.dietCokeRed, Color.dietCokeDeepRed] : [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: selectedPackage != nil ? Color.dietCokeRed.opacity(0.3) : .clear, radius: 8, y: 4)
            .disabled(selectedPackage == nil || purchaseService.isPurchasing)
            .padding(.horizontal)

            // Restore + terms
            HStack(spacing: 16) {
                Button("Restore Purchases") {
                    Task {
                        do {
                            try await purchaseService.restorePurchases()
                            if purchaseService.isPremium { dismiss() }
                        } catch {
                            errorMessage = "Restore failed: \(error.localizedDescription)"
                        }
                    }
                }
                .font(.caption2)
                .foregroundColor(.dietCokeRed)

                Text("·").foregroundColor(.secondary)

                Text(selectedPackage?.packageType == .lifetime
                     ? "One-time purchase"
                     : "Auto-renews. Cancel anytime.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Link("Privacy Policy", destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/privacy.html")!)
                Text("·").foregroundColor(.secondary)
                Link("Terms of Service", destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/terms.html")!)
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Logic

    private func autoSelectPackage() {
        guard selectedPackage == nil,
              let packages = purchaseService.offerings?.current?.availablePackages else { return }
        selectedPackage = packages.first { $0.packageType == .annual } ?? packages.first
    }

    private var purchaseButtonText: String {
        guard let package = selectedPackage else { return "Continue" }

        if let intro = package.storeProduct.introductoryDiscount,
           intro.paymentMode == .freeTrial {
            return "Start Free Trial"
        }

        if let intro = package.storeProduct.introductoryDiscount,
           intro.paymentMode == .payUpFront || intro.paymentMode == .payAsYouGo {
            return "Start with \(intro.localizedPriceString)"
        }

        if streakDays > 0 {
            return "Protect My Streak"
        }

        if package.packageType == .lifetime {
            return "Unlock Pro Forever"
        }

        return "Go Pro - \(package.storeProduct.localizedPriceString)"
    }

    private func purchase() async {
        guard let package = selectedPackage else { return }
        do {
            try await purchaseService.purchase(package)
            if purchaseService.isPremium { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Carousel Card

private struct CarouselCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 10, y: 4)
        )
    }
}

// MARK: - Package Button

private struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let allPackages: [Package]
    let action: () -> Void

    private var isYearly: Bool { package.packageType == .annual }
    private var isLifetime: Bool { package.packageType == .lifetime }

    private var introOffer: StoreProductDiscount? {
        package.storeProduct.introductoryDiscount
    }

    private var hasFreeTrial: Bool {
        introOffer?.paymentMode == .freeTrial
    }

    private var trialDuration: String? {
        guard let offer = introOffer, offer.paymentMode == .freeTrial else { return nil }
        let unit = offer.subscriptionPeriod.unit
        let value = offer.subscriptionPeriod.value
        switch unit {
        case .day: return value == 1 ? "1 Day" : "\(value) Days"
        case .week: return value == 1 ? "1 Week" : "\(value) Weeks"
        case .month: return value == 1 ? "1 Month" : "\(value) Months"
        case .year: return value == 1 ? "1 Year" : "\(value) Years"
        @unknown default: return nil
        }
    }

    private var annualSavingsPercentage: Int? {
        guard isYearly else { return nil }
        guard let monthlyPackage = allPackages.first(where: { $0.packageType == .monthly }) else { return nil }

        let monthlyPrice = monthlyPackage.storeProduct.price as Decimal
        let annualPrice = package.storeProduct.price as Decimal
        let yearlyAtMonthlyRate = monthlyPrice * 12
        guard yearlyAtMonthlyRate > 0 else { return nil }

        let savings = yearlyAtMonthlyRate - annualPrice
        let percentage = Int((NSDecimalNumber(decimal: savings / yearlyAtMonthlyRate).doubleValue) * 100)
        return percentage > 0 ? percentage : nil
    }

    private var badgeText: String? {
        if hasFreeTrial, let duration = trialDuration {
            return "\(duration) Free"
        }
        if let savings = annualSavingsPercentage {
            return "Save \(savings)%"
        }
        if isLifetime {
            return "Best Value"
        }
        return nil
    }

    private var badgeColor: Color {
        if hasFreeTrial { return .blue }
        if isLifetime { return .purple }
        return .green
    }

    private var periodName: String {
        guard let period = package.storeProduct.subscriptionPeriod else { return "period" }
        switch period.unit {
        case .day: return period.value == 1 ? "day" : "\(period.value) days"
        case .week: return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month: return period.value == 1 ? "month" : "\(period.value) months"
        case .year: return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default: return "period"
        }
    }

    private var priceSubtitle: String {
        if hasFreeTrial {
            return "then \(package.storeProduct.localizedPriceString)/\(periodName)"
        }
        if isLifetime { return "One-time purchase" }
        return "per \(periodName)"
    }

    var body: some View {
        Button(action: action) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.dietCokeRed : Color.dietCokeSilver, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.dietCokeRed)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.dietCokeCharcoal)

                        if let badge = badgeText {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .cornerRadius(4)
                        }
                    }

                    Text(priceSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if hasFreeTrial {
                    Text("FREE")
                        .font(.headline)
                        .foregroundColor(.blue)
                } else {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.headline)
                        .foregroundColor(.dietCokeRed)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? Color.dietCokeRed.opacity(0.06)
                          : Color.dietCokeCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.dietCokeRed : Color.dietCokeSilver.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Icon View

private struct AppIconView: View {
    let size: CGFloat

    private var cornerRadius: CGFloat { size * 0.2237 }

    var body: some View {
        Group {
            if let icon = loadAppIcon() {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.dietCokeRed)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func loadAppIcon() -> UIImage? {
        let candidates = [
            "AppIcon60x60@3x.png",
            "AppIcon60x60@2x.png",
            "AppIcon76x76@2x.png",
            "AppIcon120x120.png",
            "AppIcon180x180.png",
            "AppIcon1024x1024.png"
        ]
        for name in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: nil),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let image = UIImage(named: name) {
            return image
        }
        return nil
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseService.shared)
        .environmentObject(DrinkStore())
        .environmentObject(UserPreferences())
}
