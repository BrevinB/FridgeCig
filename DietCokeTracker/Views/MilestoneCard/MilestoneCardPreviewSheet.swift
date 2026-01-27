import SwiftUI

struct MilestoneCardPreviewSheet: View {
    let card: MilestoneCard
    @StateObject private var milestoneService = MilestoneCardService()
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTheme: CardTheme = .classic
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Preview
                    MilestoneCardView(card: card, theme: selectedTheme)
                        .frame(maxWidth: 320)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                        .padding(.top)

                    // Theme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose a Theme")
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(CardTheme.allCases) { theme in
                                ThemeButton(
                                    theme: theme,
                                    isSelected: selectedTheme == theme,
                                    isLocked: theme.isPremium && !purchaseService.isPremium
                                ) {
                                    if theme.isPremium && !purchaseService.isPremium {
                                        showingPaywall = true
                                    } else {
                                        selectedTheme = theme
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Share Button
                    Button {
                        generateAndShare()
                    } label: {
                        Label("Share to Stories", systemImage: "square.and.arrow.up")
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

                    // Info Text
                    Text("Share your achievement on Instagram Stories, iMessage, and more!")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func generateAndShare() {
        if let image = milestoneService.generateShareImage(for: card, theme: selectedTheme) {
            shareImage = image
            showingShareSheet = true
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
