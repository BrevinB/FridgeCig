import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable: header + features
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            AppIconView(size: 80)

                            Text("FridgeCig Pro")
                                .font(.largeTitle.bold())
                                .foregroundColor(.dietCokeCharcoal)
                                .multilineTextAlignment(.center)

                            Text("Widgets, streak protection, and more")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // Features
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "rectangle.3.offgrid.fill",
                                title: "Home Screen Widgets",
                                description: "Track at a glance from your home screen"
                            )
                            FeatureRow(
                                icon: "applewatch",
                                title: "Apple Watch App",
                                description: "Log drinks from your wrist instantly"
                            )
                            FeatureRow(
                                icon: "snowflake",
                                title: "Streak Freezes",
                                description: "Protect your streak with 3 freezes per month"
                            )
                            FeatureRow(
                                icon: "paintpalette.fill",
                                title: "Premium Themes",
                                description: "Customize your app with exclusive themes"
                            )
                            FeatureRow(
                                icon: "heart.text.square.fill",
                                title: "Sync to Apple Health",
                                description: "Auto-log caffeine intake to HealthKit"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }

                // Pinned bottom: packages + CTA + restore + terms
                VStack(spacing: 12) {
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

                    // Purchase button
                    Button {
                        Task { await purchase() }
                    } label: {
                        if purchaseService.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(purchaseButtonText)
                        }
                    }
                    .buttonStyle(.dietCokePrimary)
                    .disabled(selectedPackage == nil || purchaseService.isPurchasing)
                    .opacity(selectedPackage == nil ? 0.6 : 1)
                    .padding(.horizontal)

                    // Restore + terms
                    HStack(spacing: 16) {
                        Button("Restore Purchases") {
                            Task {
                                do {
                                    try await purchaseService.restorePurchases()
                                    if purchaseService.isPremium {
                                        dismiss()
                                    }
                                } catch {
                                    errorMessage = "Restore failed: \(error.localizedDescription)"
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.dietCokeRed)

                        Text("·")
                            .foregroundColor(.secondary)

                        Text(selectedPackage?.packageType == .lifetime
                             ? "One-time purchase"
                             : "Auto-renews. Cancel anytime.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Link("Privacy Policy", destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/privacy.html")!)
                        Text("·")
                            .foregroundColor(.secondary)
                        Link("Terms of Service", destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/terms.html")!)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)

                    // Error message
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
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            autoSelectPackage()
        }
        .onChange(of: purchaseService.offerings?.current?.availablePackages.count) { _ in
            autoSelectPackage()
        }
    }

    private func autoSelectPackage() {
        guard selectedPackage == nil,
              let packages = purchaseService.offerings?.current?.availablePackages else { return }
        selectedPackage = packages.first { $0.packageType == .annual } ?? packages.first
    }

    private var purchaseButtonText: String {
        guard let package = selectedPackage else { return "Continue" }

        // Check for free trial
        if let intro = package.storeProduct.introductoryDiscount,
           intro.paymentMode == .freeTrial {
            return "Start Free Trial"
        }

        // Check for intro offer
        if let intro = package.storeProduct.introductoryDiscount,
           intro.paymentMode == .payUpFront || intro.paymentMode == .payAsYouGo {
            return "Start with \(intro.localizedPriceString)"
        }

        if package.packageType == .lifetime {
            return "Purchase for \(package.storeProduct.localizedPriceString)"
        } else {
            return "Subscribe for \(package.storeProduct.localizedPriceString)"
        }
    }

    private func purchase() async {
        guard let package = selectedPackage else { return }
        do {
            try await purchaseService.purchase(package)
            if purchaseService.isPremium {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.dietCokeRed)
                .frame(width: 44, height: 44)
                .background(Color.dietCokeRed.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Package Button

private struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let allPackages: [Package]
    let action: () -> Void

    private var isYearly: Bool {
        package.packageType == .annual
    }

    private var isLifetime: Bool {
        package.packageType == .lifetime
    }

    // Check for intro offer (trial or discount)
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

    private var introDiscountPercentage: Int? {
        guard let offer = introOffer,
              offer.paymentMode == .payUpFront || offer.paymentMode == .payAsYouGo,
              let regularPrice = package.storeProduct.pricePerMonth?.doubleValue,
              regularPrice > 0 else { return nil }

        let discountPrice = offer.price as Decimal
        let regular = regularPrice
        let discount = NSDecimalNumber(decimal: discountPrice).doubleValue
        let percentage = Int(((regular - discount) / regular) * 100)
        return percentage > 0 ? percentage : nil
    }

    /// Calculate savings vs monthly plan (for annual packages)
    private var annualSavingsPercentage: Int? {
        guard isYearly else { return nil }

        // Find monthly package to compare
        guard let monthlyPackage = allPackages.first(where: { $0.packageType == .monthly }) else { return nil }

        let monthlyPrice = monthlyPackage.storeProduct.price as Decimal
        let annualPrice = package.storeProduct.price as Decimal

        // Calculate what 12 months would cost
        let yearlyAtMonthlyRate = monthlyPrice * 12
        guard yearlyAtMonthlyRate > 0 else { return nil }

        let savings = yearlyAtMonthlyRate - annualPrice
        let percentage = Int((NSDecimalNumber(decimal: savings / yearlyAtMonthlyRate).doubleValue) * 100)

        return percentage > 0 ? percentage : nil
    }

    private var badgeInfo: (text: String, color: Color)? {
        // Priority: Free Trial > Intro Discount > Annual Savings > Lifetime
        if hasFreeTrial, let duration = trialDuration {
            return ("\(duration) Free Trial", .blue)
        }
        if let discount = introDiscountPercentage {
            return ("\(discount)% Off", .green)
        }
        if let savings = annualSavingsPercentage {
            return ("Save \(savings)%", .green)
        }
        if isLifetime {
            return ("Best Value", .purple)
        }
        return nil
    }

    private var priceSubtitle: String {
        // Show trial info
        if hasFreeTrial {
            return "then \(package.storeProduct.localizedPriceString)/\(periodName)"
        }

        // Show intro offer price info
        if let offer = introOffer, offer.paymentMode == .payUpFront || offer.paymentMode == .payAsYouGo {
            let introPrice = offer.localizedPriceString
            let introPeriod = formatPeriod(offer.subscriptionPeriod)
            return "\(introPrice) for \(introPeriod), then \(package.storeProduct.localizedPriceString)/\(periodName)"
        }

        // Standard subtitles
        if isLifetime {
            return "One-time purchase"
        }
        return "per \(periodName)"
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

    private func formatPeriod(_ period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 1 ? "1 day" : "\(period.value) days"
        case .week: return period.value == 1 ? "1 week" : "\(period.value) weeks"
        case .month: return period.value == 1 ? "1 month" : "\(period.value) months"
        case .year: return period.value == 1 ? "1 year" : "\(period.value) years"
        @unknown default: return "\(period.value) periods"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Free trial banner
                if hasFreeTrial, let duration = trialDuration {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.caption)
                        Text("\(duration) Free Trial")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                                .foregroundColor(.dietCokeCharcoal)

                            if !hasFreeTrial, let badge = badgeInfo {
                                Text(badge.text)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(badge.color)
                                    .cornerRadius(4)
                            }
                        }

                        Text(priceSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if hasFreeTrial {
                            Text("FREE")
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        } else {
                            Text(package.storeProduct.localizedPriceString)
                                .font(.title3.bold())
                                .foregroundColor(.dietCokeRed)
                        }

                        if isLifetime {
                            Text("forever")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(hasFreeTrial ? Color.blue.opacity(0.05) : (isLifetime ? Color.dietCokeRed.opacity(0.05) : Color.dietCokeCardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? (hasFreeTrial ? Color.blue : Color.dietCokeRed) : Color.dietCokeSilver, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                // Fallback
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
        // Modern single-size icon: Xcode generates files like "AppIcon60x60@3x.png" in the bundle
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
        // Fallback: try UIImage(named:) for older icon formats
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
}
