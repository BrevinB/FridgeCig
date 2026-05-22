import SwiftUI

struct SubscriptionSection: View {
    @EnvironmentObject var purchaseService: PurchaseService

    var body: some View {
        Section {
            NavigationLink {
                SubscriptionStatusView()
            } label: {
                HStack(spacing: 14) {
                    SettingsIconBadge(
                        systemImage: purchaseService.isPremium ? "crown.fill" : "crown",
                        tint: .dietCokeRed
                    )

                    Text(purchaseService.isPremium ? "FridgeCig Pro" : "Upgrade to Pro")
                        .fontWeight(.medium)

                    Spacer()

                    if purchaseService.isPremium {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
            }
        } header: {
            Text("Subscription")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List { SubscriptionSection() }
    }
    .withPreviewEnvironment()
}
#endif
