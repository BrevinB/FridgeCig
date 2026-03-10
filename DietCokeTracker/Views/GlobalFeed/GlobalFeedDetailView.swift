import SwiftUI

struct GlobalFeedDetailView: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var globalFeedService: GlobalFeedService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let item: ActivityItem
    let photo: UIImage?

    @State private var showingReportSheet = false
    @State private var showingBlockAlert = false
    @State private var hasBlocked = false
    @State private var showCheersAnimation = false

    private var hasCheered: Bool {
        activityService.hasUserCheered(item)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    private var cheersButtonBackground: Color {
        if hasCheered {
            return Color.dietCokeRed.opacity(0.12)
        }
        return colorScheme == .dark ? Color(white: 0.15) : Color(.systemGray6)
    }

    private var toolbarIconSecondary: Color {
        colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray5)
    }

    private var noteBackground: Color {
        colorScheme == .dark ? Color(white: 0.12) : Color(.systemGray6)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    photoSection
                    infoSection
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.dietCokeDarkSilver, toolbarIconSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingReportSheet = true
                        } label: {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }

                        Button(role: .destructive) {
                            showingBlockAlert = true
                        } label: {
                            Label("Block User", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.dietCokeDarkSilver, toolbarIconSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                ReportContentSheet(
                    activityID: item.id.uuidString,
                    reportedUserID: item.userID,
                    onReported: {
                        dismiss()
                    }
                )
            }
            .alert("Block User", isPresented: $showingBlockAlert) {
                Button("Block", role: .destructive) {
                    Task {
                        await blockUser()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Block \(item.displayName)? Their photos will no longer appear in your Explore feed.")
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        ZStack {
            if let photo = photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                photoPlaceholder
            }

            if showCheersAnimation {
                cheersOverlay
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onTapGesture(count: 2) {
            doubleTapCheers()
        }
    }

    private var photoPlaceholder: some View {
        let fillColor = colorScheme == .dark ? Color(white: 0.15) : Color.gray.opacity(0.12)
        return RoundedRectangle(cornerRadius: 16)
            .fill(fillColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.dietCokeDarkSilver)
                    Text("Photo unavailable")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }
    }

    private var cheersOverlay: some View {
        Image(systemName: "hands.clap.fill")
            .font(.system(size: 64))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 8)
            .scaleEffect(showCheersAnimation ? 1.0 : 0.5)
            .opacity(showCheersAnimation ? 1 : 0)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            userInfoRow
            drinkDetailsView
            noteView
            hintText
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var userInfoRow: some View {
        HStack(alignment: .center, spacing: 12) {
            avatarView
            userDetails
            Spacer()
            cheersButton
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            Text(String(item.displayName.prefix(1)).uppercased())
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.dietCokeRed)
        }
    }

    private var userDetails: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(item.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)

                if item.isPremium {
                    proBadge
                }
            }

            HStack(spacing: 6) {
                if let drinkType = item.payload.drinkType {
                    if let ounces = item.payload.drinkOunces, ounces != drinkType.ounces {
                        let ozText = ounces.truncatingRemainder(dividingBy: 1) == 0
                            ? "\(Int(ounces)) oz"
                            : String(format: "%.1f oz", ounces)
                        Text("\(drinkType.displayName) · \(ozText)")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    } else {
                        Text(drinkType.displayName)
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }

                Text("·")
                    .foregroundColor(.dietCokeDarkSilver)

                Text(item.formattedTime)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
    }

    private var proBadge: some View {
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
                colors: [
                    Color(red: 1.0, green: 0.84, blue: 0.0),
                    Color(red: 0.9, green: 0.7, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }

    private var cheersButton: some View {
        Button {
            HapticManager.cheerSent()
            Task {
                await activityService.toggleCheers(for: item)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: hasCheered ? "hands.clap.fill" : "hands.clap")
                    .font(.system(size: 18))
                    .symbolEffect(.bounce, value: showCheersAnimation)
                if item.cheersCount > 0 {
                    Text("\(item.cheersCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(hasCheered ? .dietCokeRed : .dietCokeDarkSilver)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(cheersButtonBackground)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var drinkDetailsView: some View {
        let hasDetails = item.payload.drinkRating != nil
            || item.payload.drinkOunces != nil
            || item.payload.drinkSpecialEdition != nil
            || (item.payload.drinkBrand != nil && item.payload.drinkBrand != .dietCoke)

        if hasDetails {
            HStack(spacing: 8) {
                // Rating
                if let rating = item.payload.drinkRating {
                    HStack(spacing: 4) {
                        Image(systemName: rating.icon)
                            .font(.system(size: 12))
                            .foregroundColor(rating.color)
                        Text(rating.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeCharcoal)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(rating.color.opacity(0.12))
                    )
                }

                // Ounces
                if let ounces = item.payload.drinkOunces {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text(ounces.truncatingRemainder(dividingBy: 1) == 0
                             ? "\(Int(ounces)) oz"
                             : String(format: "%.1f oz", ounces))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeCharcoal)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }

                // Special Edition
                if let edition = item.payload.drinkSpecialEdition {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(edition)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dietCokeCharcoal)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.12))
                    )
                }

                // Brand (only show if not default Diet Coke)
                if let brand = item.payload.drinkBrand, brand != .dietCoke {
                    Text(brand.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(brand.color.opacity(0.12))
                        )
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var noteView: some View {
        if let note = item.payload.drinkNote, !note.isEmpty {
            Text("\"\(note)\"")
                .font(.body)
                .italic()
                .foregroundColor(.dietCokeCharcoal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(noteBackground)
                )
        }
    }

    @ViewBuilder
    private var hintText: some View {
        if photo != nil {
            Text("Double-tap photo to cheers")
                .font(.caption2)
                .foregroundColor(.dietCokeDarkSilver.opacity(0.6))
        }
    }

    // MARK: - Actions

    private func doubleTapCheers() {
        guard !hasCheered else { return }
        HapticManager.cheerSent()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            showCheersAnimation = true
        }

        Task {
            await activityService.toggleCheers(for: item)
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.easeOut(duration: 0.25)) {
                showCheersAnimation = false
            }
        }
    }

    private func blockUser() async {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return }
        do {
            try await friendService.blockUser(blockerID: currentUserID, targetID: item.userID)
            globalFeedService.removeItemsFromUser(item.userID)
            hasBlocked = true
            dismiss()
        } catch {
            AppLogger.friends.error("Failed to block user: \(error.localizedDescription)")
        }
    }
}
