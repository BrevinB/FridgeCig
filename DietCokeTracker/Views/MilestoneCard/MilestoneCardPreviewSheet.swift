import SwiftUI

struct MilestoneCardPreviewSheet: View {
    let card: MilestoneCard
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var showingSharePreview = false
    @State private var showingPaywall = false

    // Map old CardTheme to new ShareTheme for initial selection
    private var initialShareTheme: ShareTheme {
        .classic
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Preview using new ShareCardView
                    ShareCardPreviewContainer(
                        content: card,
                        customization: .milestoneDefault
                    )
                    .frame(height: 280)
                    .padding(.top)

                    // Quick theme preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share Your Achievement")
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)

                        Text("Create beautiful share cards with themes, stickers, and multiple formats for Instagram, Twitter, and more.")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Share Button - opens new SharePreviewSheet
                    Button {
                        showingSharePreview = true
                    } label: {
                        Label("Customize & Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.dietCokeRed)
                            )
                    }
                    .padding(.horizontal)

                    // Premium features callout
                    if !purchaseService.isPremium {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text("Premium unlocks 8 extra themes, stickers, and more formats")
                                .font(.caption)
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Share Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSharePreview) {
            SharePreviewSheet(
                content: card,
                isPresented: $showingSharePreview,
                isPremium: purchaseService.isPremium,
                initialTheme: initialShareTheme,
                onPremiumTap: {
                    showingSharePreview = false
                    showingPaywall = true
                }
            )
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Theme Button

struct ThemeButton: View {
    let theme: CardTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 3)
                    )

                if isLocked {
                    Color.black.opacity(0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MilestoneCardPreviewSheet(
        card: MilestoneCard.forDrinkCount(100, username: "DCFan")
    )
    .environmentObject(PurchaseService.shared)
}
