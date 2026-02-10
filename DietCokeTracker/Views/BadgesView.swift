import SwiftUI

struct BadgesView: View {
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory: BadgeCategory = .all
    @State private var selectedBadge: Badge?
    @State private var showingPaywall = false
    @State private var showBadgeUpsell = false
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        themeManager.backgroundColor(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Header
                    ProgressHeaderView(
                        earned: badgeStore.earnedCount,
                        total: badgeStore.totalCount,
                        percentage: badgeStore.completionPercentage
                    )
                    .padding(.horizontal)

                    // Category Filter
                    CategoryFilterView(selectedCategory: $selectedCategory)

                    // Badges Grid
                    BadgesGridView(
                        badges: filteredBadges,
                        brand: preferences.defaultBrand,
                        onBadgeTap: { badge in
                            selectedBadge = badge
                        }
                    )
                    .padding(.horizontal)

                    // Badge upsell banner (first badge earned, non-premium)
                    if showBadgeUpsell && !purchaseService.isPremium {
                        UpsellBanner.badgeTrigger(
                            onTap: {
                                showingPaywall = true
                            },
                            onDismiss: {
                                withAnimation {
                                    showBadgeUpsell = false
                                }
                                preferences.markBadgeUpsellShown()
                            }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Badges")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge, brand: preferences.defaultBrand)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                // Check for first badge upsell (when user has exactly 1 badge)
                if !purchaseService.isPremium && preferences.shouldShowBadgeUpsell(isFirstBadge: badgeStore.earnedCount == 1) {
                    withAnimation(.easeInOut.delay(0.5)) {
                        showBadgeUpsell = true
                    }
                }
            }
        }
    }

    private var filteredBadges: [Badge] {
        switch selectedCategory {
        case .all:
            return badgeStore.allBadges
        case .earned:
            return badgeStore.earnedBadges
        case .milestones:
            return badgeStore.badges(ofType: .milestone)
        case .streaks:
            return badgeStore.badges(ofType: .streak)
        case .volume:
            return badgeStore.badges(ofType: .volume)
        case .variety:
            return badgeStore.badges(ofType: .variety)
        case .lifestyle:
            return badgeStore.badges(ofType: .lifestyle)
        case .special:
            return badgeStore.badges(ofType: .special)
        }
    }
}

// MARK: - Badge Category

enum BadgeCategory: String, CaseIterable {
    case all = "All"
    case earned = "Earned"
    case milestones = "Milestones"
    case streaks = "Streaks"
    case volume = "Volume"
    case variety = "Variety"
    case lifestyle = "Fun"
    case special = "Special"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .earned: return "checkmark.seal.fill"
        case .milestones: return "flag.fill"
        case .streaks: return "flame.fill"
        case .volume: return "flask.fill"
        case .variety: return "square.stack.3d.up.fill"
        case .lifestyle: return "face.smiling.fill"
        case .special: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .dietCokeRed
        case .earned: return .green
        case .milestones: return .blue
        case .streaks: return .orange
        case .volume: return .cyan
        case .variety: return .purple
        case .lifestyle: return .pink
        case .special: return .yellow
        }
    }
}

// MARK: - Progress Header

struct ProgressHeaderView: View {
    let earned: Int
    let total: Int
    let percentage: Double
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.primaryGradient)

            // Ambient bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .opacity(0.5)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Badge Collection")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(earned) of \(total)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("badges earned")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: percentage / 100)
                            .stroke(
                                Color.white,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(percentage))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .accessibilityHidden(true)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * (percentage / 100), height: 10)
                    }
                }
                .frame(height: 10)
                .accessibilityHidden(true)
            }
            .padding(20)
        }
        .frame(height: 180)
        .shadow(color: themeManager.primaryColor.opacity(0.4), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Badge collection: \(earned) of \(total) badges earned, \(Int(percentage)) percent complete")
    }
}

// MARK: - Category Filter

struct CategoryFilterView: View {
    @Binding var selectedCategory: BadgeCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let category: BadgeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.dietCokeCardBackground
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? category.color.opacity(0.4) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue) badges")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Badges Grid

struct BadgesGridView: View {
    let badges: [Badge]
    var brand: BeverageBrand = .dietCoke
    let onBadgeTap: (Badge) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if badges.isEmpty {
            EmptyBadgesView(brand: brand)
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    BadgeGridItem(badge: badge, brand: brand) {
                        onBadgeTap(badge)
                    }
                }
            }
        }
    }
}

struct EmptyBadgesView: View {
    var brand: BeverageBrand = .dietCoke

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeSilver.opacity(0.2), Color.dietCokeSilver.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "trophy")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeSilver, Color.dietCokeDarkSilver],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("No badges yet")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Keep drinking \(brand.shortName) to earn badges!")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Share Badge Sheet

struct ShareBadgeSheet: View {
    let badge: Badge
    var brand: BeverageBrand = .dietCoke
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Share Your Achievement")
                    .font(.headline)

                // Preview of shareable badge
                ShareableBadgeView(badge: badge, brand: brand)
                    .background(
                        GeometryReader { _ in
                            Color.clear
                                .onAppear {
                                    generateShareImage()
                                }
                        }
                    )

                if let image = shareImage {
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(
                            "\(brand.shortName) Badge: \(badge.title)",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Label("Share Badge", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.dietCokePrimary)
                } else {
                    ProgressView()
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Share Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateShareImage() {
        let renderer = ImageRenderer(content: ShareableBadgeView(badge: badge, brand: brand))
        renderer.scale = 3.0
        shareImage = renderer.uiImage
    }
}

// MARK: - Shareable Badge View (for image export)

struct ShareableBadgeView: View {
    let badge: Badge
    var brand: BeverageBrand = .dietCoke

    private var dynamicDescription: String {
        badge.description(for: brand)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                BrandIconView(brand: brand, size: DrinkIconSize.sm)
                    .foregroundStyle(brand.iconGradient)
                Text("FridgeCig")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)
            }

            // Badge
            ZStack {
                Circle()
                    .fill(badge.rarity.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(badge.rarity.color, lineWidth: 4)
                    .frame(width: 100, height: 100)

                Image(systemName: badge.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(badge.rarity.color)
            }

            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text(dynamicDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    Text(badge.rarity.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(badge.rarity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(badge.rarity.color.opacity(0.15))
                        .clipShape(Capsule())

                    if let date = badge.formattedUnlockDate {
                        Text("Earned \(date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .environment(\.colorScheme, .light) // Always render in light mode for sharing
    }
}

// MARK: - Previews

#Preview("Badges View") {
    BadgesView()
        .environmentObject(BadgeStore())
        .environmentObject(UserPreferences())
        .environmentObject(PurchaseService.shared)
}
