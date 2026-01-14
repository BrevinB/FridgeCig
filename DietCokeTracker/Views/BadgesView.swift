import SwiftUI

struct BadgesView: View {
    @EnvironmentObject var badgeStore: BadgeStore
    @State private var selectedCategory: BadgeCategory = .all
    @State private var selectedBadge: Badge?
    @State private var showingShareSheet = false
    @State private var badgeToShare: Badge?

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
                        onBadgeTap: { badge in
                            selectedBadge = badge
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Badges")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge) {
                    badgeToShare = badge
                    showingShareSheet = true
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let badge = badgeToShare {
                    ShareBadgeSheet(badge: badge)
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
    case special = "Special"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .earned: return "checkmark.seal.fill"
        case .milestones: return "flag.fill"
        case .streaks: return "flame.fill"
        case .volume: return "drop.fill"
        case .variety: return "square.stack.3d.up.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Progress Header

struct ProgressHeaderView: View {
    let earned: Int
    let total: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("\(earned) of \(total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: percentage / 100)
                        .stroke(
                            Color.dietCokeRed,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(percentage))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.dietCokeRed)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.dietCokeRed)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .dietCokeCard()
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
                        title: category.rawValue,
                        icon: category.icon,
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
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dietCokeRed : Color.dietCokeCardBackground)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Badges Grid

struct BadgesGridView: View {
    let badges: [Badge]
    let onBadgeTap: (Badge) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if badges.isEmpty {
            EmptyBadgesView()
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    BadgeGridItem(badge: badge) {
                        onBadgeTap(badge)
                    }
                }
            }
        }
    }
}

struct EmptyBadgesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No badges yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Keep drinking Diet Coke to earn badges!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Share Badge Sheet

struct ShareBadgeSheet: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Share Your Achievement")
                    .font(.headline)

                // Preview of shareable badge
                ShareableBadgeView(badge: badge)
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
                            "Diet Coke Badge: \(badge.title)",
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
        let renderer = ImageRenderer(content: ShareableBadgeView(badge: badge))
        renderer.scale = 3.0
        shareImage = renderer.uiImage
    }
}

// MARK: - Shareable Badge View (for image export)

struct ShareableBadgeView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Diet Coke Tracker")
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

                Text(badge.description)
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
    }
}

// MARK: - Previews

#Preview("Badges View") {
    BadgesView()
        .environmentObject(BadgeStore())
}
