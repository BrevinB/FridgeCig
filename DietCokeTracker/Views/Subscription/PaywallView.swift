import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.dietCokeRed)

                        Text("FridgeCig Pro")
                            .font(.largeTitle.bold())
                            .foregroundColor(.dietCokeCharcoal)

                        Text("Unlock premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "rectangle.3.offgrid.fill",
                            title: "Home Screen Widgets",
                            description: "Track your Diet Cokes at a glance"
                        )
                        FeatureRow(
                            icon: "applewatch",
                            title: "Apple Watch App",
                            description: "Log drinks from your wrist"
                        )
                    }
                    .padding(.horizontal)

                    // Packages
                    if let offerings = purchaseService.offerings,
                       let packages = offerings.current?.availablePackages {
                        VStack(spacing: 12) {
                            ForEach(packages, id: \.identifier) { package in
                                PackageButton(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier
                                ) {
                                    selectedPackage = package
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        ProgressView()
                            .padding()
                    }

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

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            try? await purchaseService.restorePurchases()
                            if purchaseService.isPremium {
                                dismiss()
                            }
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.dietCokeRed)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Terms
                    VStack(spacing: 4) {
                        if selectedPackage?.packageType == .lifetime {
                            Text("One-time purchase. No subscription required.")
                        } else {
                            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                        }
                        Text("Payment will be charged to your Apple ID account.")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
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
            if let packages = purchaseService.offerings?.current?.availablePackages {
                // Select yearly by default (better value)
                selectedPackage = packages.first { $0.packageType == .annual } ?? packages.first
            }
        }
    }

    private var purchaseButtonText: String {
        guard let package = selectedPackage else { return "Continue" }
        if package.packageType == .lifetime {
            return "Purchase"
        } else {
            return "Subscribe"
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
    let action: () -> Void

    private var isYearly: Bool {
        package.packageType == .annual
    }

    private var isLifetime: Bool {
        package.packageType == .lifetime
    }

    private var badgeInfo: (text: String, color: Color)? {
        if isLifetime {
            return ("Best Value", .purple)
        } else if isYearly {
            return ("Save 44%", .green)
        }
        return nil
    }

    private var priceSubtitle: String? {
        if isLifetime {
            return "One-time purchase"
        } else if isYearly {
            return "per year"
        } else if package.packageType == .monthly {
            return "per month"
        }
        return nil
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)

                        if let badge = badgeInfo {
                            Text(badge.text)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(badge.color)
                                .cornerRadius(4)
                        }
                    }

                    if let subtitle = priceSubtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title3.bold())
                        .foregroundColor(.dietCokeRed)

                    if isLifetime {
                        Text("forever")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLifetime ? Color.dietCokeRed.opacity(0.05) : Color.dietCokeCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.dietCokeRed : Color.dietCokeSilver, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseService.shared)
}
