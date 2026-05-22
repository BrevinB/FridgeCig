import SwiftUI

struct HealthSection: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @StateObject private var healthKitManager = HealthKitManager.shared
    @Binding var showingHealthKitPaywall: Bool
    @State private var isRequestingHealthKit = false
    @State private var isHealthKitEnabled = false

    var body: some View {
        Section {
            if healthKitManager.isHealthKitAvailable {
                availableRow
            } else {
                unavailableRow
            }
        } header: {
            Text("Health")
        } footer: {
            if healthKitManager.isHealthKitAvailable && purchaseService.isPremium && healthKitManager.isAuthorized {
                Text("Caffeine from your drinks will be automatically logged to Apple Health.")
            }
        }
        .onAppear {
            isHealthKitEnabled = healthKitManager.isAutoLogEnabled && healthKitManager.isAuthorized
        }
    }

    private var availableRow: some View {
        Button {
            handleHealthKitToggle()
        } label: {
            HStack(spacing: 14) {
                SettingsIconBadge(systemImage: "heart.text.square.fill", tint: .red)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Sync to Apple Health")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if !purchaseService.isPremium {
                            ProBadge()
                        }
                    }

                    Text("Auto-log caffeine intake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isRequestingHealthKit {
                    ProgressView()
                } else if purchaseService.isPremium {
                    Toggle("Sync to Apple Health", isOn: $isHealthKitEnabled)
                        .labelsHidden()
                        .onChange(of: isHealthKitEnabled) { _, _ in
                            handleHealthKitToggle()
                        }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .disabled(isRequestingHealthKit)
    }

    private var unavailableRow: some View {
        HStack(spacing: 14) {
            SettingsIconBadge(systemImage: "heart.slash.fill", tint: .gray)

            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health")
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text("Not available on this device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func handleHealthKitToggle() {
        if !purchaseService.isPremium {
            showingHealthKitPaywall = true
            return
        }
        if healthKitManager.isAuthorized {
            healthKitManager.isAutoLogEnabled.toggle()
            return
        }
        isRequestingHealthKit = true
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    if healthKitManager.isAuthorized {
                        healthKitManager.isAutoLogEnabled = true
                    }
                    isRequestingHealthKit = false
                }
            } catch {
                await MainActor.run {
                    isRequestingHealthKit = false
                }
            }
        }
    }
}

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.9, green: 0.7, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }
}

#if DEBUG
private struct HealthSectionPreviewWrapper: View {
    @State private var showing = false
    var body: some View {
        NavigationStack {
            List {
                HealthSection(showingHealthKitPaywall: $showing)
            }
        }
    }
}

#Preview { HealthSectionPreviewWrapper().withPreviewEnvironment() }
#Preview("Pro badge") { ProBadge().padding() }
#endif
