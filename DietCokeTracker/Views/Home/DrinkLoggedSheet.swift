import SwiftUI
import UIKit

/// Everything the celebration sheet needs to know about a just-logged drink.
struct LoggedDrinkCelebration: Identifiable {
    let id = UUID()
    let entry: DrinkEntry
    let photo: UIImage?
    let visibility: PostVisibility
    let willPostGlobally: Bool
}

/// Shown right after a drink is logged — the emotional peak of the app.
/// Confirms where the post went and offers share/feed CTAs instead of
/// dropping the user back on Home with no feedback.
struct DrinkLoggedSheet: View {
    let celebration: LoggedDrinkCelebration

    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingShareSheet = false
    @State private var iconScale: CGFloat = 0.4
    // Captured on appear so the card doesn't vanish mid-sheet once the
    // system prompt resolves; the card swaps to a confirmation instead.
    @State private var showsReminderPrompt = false
    @State private var reminderResult: Bool?
    // One ask per sheet: the leaderboard invite wins until the user has a
    // profile or has said no, then reminders get their turn.
    @State private var showsLeaderboardPrompt = false
    @State private var leaderboardName = IdentityService.suggestedDisplayName()
    @State private var suggestedLeaderboardName = ""
    @State private var isJoiningLeaderboard = false
    @State private var leaderboardJoined = false
    @State private var leaderboardJoinFailed = false
    @AppStorage("hasDismissedLeaderboardPrompt") private var hasDismissedLeaderboardPrompt = false

    private var brand: BeverageBrand { celebration.entry.brand }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.dietCokeSilver.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [brand.color.opacity(0.18), brand.color.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(brand.color)
            }
            .scaleEffect(iconScale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconScale = 1
                }
            }

            VStack(spacing: 6) {
                Text("Logged!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text(celebration.entry.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
            }

            visibilityStatus

            if showsLeaderboardPrompt {
                leaderboardPrompt
            } else if showsReminderPrompt {
                reminderPrompt
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                if celebration.willPostGlobally {
                    Button {
                        dismiss()
                        deepLinkHandler.navigateToGlobalFeed()
                    } label: {
                        Label("View Global Feed", systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(brand.buttonGradient)
                            )
                    }
                }

                Button {
                    showingShareSheet = true
                } label: {
                    Label("Create Share Card", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(celebration.willPostGlobally ? brand.color : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(celebration.willPostGlobally
                                      ? AnyShapeStyle(brand.color.opacity(0.12))
                                      : AnyShapeStyle(brand.buttonGradient))
                        )
                }

                Button("Done") {
                    dismiss()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeDarkSilver)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .background(backgroundColor.ignoresSafeArea())
        .presentationDetents([presentationDetent])
        .onAppear {
            // Right after a log is when both asks make the most sense: there's
            // already a drink on the board and a streak to protect.
            if identityService.state == .noIdentity && !hasDismissedLeaderboardPrompt {
                showsLeaderboardPrompt = true
                suggestedLeaderboardName = leaderboardName
                TelemetryService.leaderboardPromptShown(source: "drinkLogged")
            } else if notificationService.authorizationStatus == .notDetermined {
                showsReminderPrompt = true
                TelemetryService.notificationPromptShown(source: "drinkLogged")
            }
        }
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingShareSheet) {
            SharePreviewSheet(
                content: celebration.entry,
                isPresented: $showingShareSheet,
                isPremium: purchaseService.isPremium,
                initialTheme: .classic
            )
        }
    }

    private var presentationDetent: PresentationDetent {
        if showsLeaderboardPrompt { return .fraction(0.78) }
        if showsReminderPrompt { return .fraction(0.68) }
        return .medium
    }

    private var canJoinLeaderboard: Bool {
        !leaderboardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isJoiningLeaderboard
    }

    private func joinLeaderboard() {
        guard canJoinLeaderboard else { return }
        let name = leaderboardName.trimmingCharacters(in: .whitespacesAndNewlines)
        isJoiningLeaderboard = true
        leaderboardJoinFailed = false
        Task {
            do {
                try await identityService.createIdentity(displayName: name)
                TelemetryService.profileCreated()
                TelemetryService.leaderboardPromptJoined(
                    source: "drinkLogged",
                    editedName: name != suggestedLeaderboardName
                )
                withAnimation { leaderboardJoined = true }
            } catch {
                leaderboardJoinFailed = true
            }
            isJoiningLeaderboard = false
        }
    }

    @ViewBuilder
    private var leaderboardPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: leaderboardJoined ? "checkmark.circle.fill" : "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundColor(leaderboardJoined ? .green : .yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text(leaderboardJoined ? "You're on the leaderboard!" : "Claim your leaderboard spot")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)
                    Text(leaderboardJoined
                         ? "Find your rank anytime in Social."
                         : "This drink already counts. You can change your name later.")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !leaderboardJoined {
                HStack(spacing: 8) {
                    TextField("Display name", text: $leaderboardName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.join)
                        .onSubmit(joinLeaderboard)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95))
                        )

                    Button(action: joinLeaderboard) {
                        Group {
                            if isJoiningLeaderboard {
                                ProgressView().tint(.white)
                            } else {
                                Text("Join")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 52)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(brand.buttonGradient))
                    }
                    .disabled(!canJoinLeaderboard)
                }

                HStack {
                    if leaderboardJoinFailed {
                        Text("Couldn't join right now. Try again from Social.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Button("Not now") {
                        hasDismissedLeaderboardPrompt = true
                        withAnimation { showsLeaderboardPrompt = false }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.dietCokeDarkSilver)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }

    private var reminderTimeText: String {
        notificationService.preferences.streakReminderTime
            .formatted(date: .omitted, time: .shortened)
    }

    @ViewBuilder
    private var reminderPrompt: some View {
        HStack(spacing: 12) {
            Image(systemName: reminderResult == true ? "checkmark.circle.fill" : "bell.badge.fill")
                .font(.system(size: 22))
                .foregroundColor(reminderResult == true ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminderResult == nil ? "Keep your streak alive" : reminderResult == true ? "Reminders on" : "No problem")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)
                Text(reminderResult == nil
                     ? "Get a nudge at \(reminderTimeText) on days you haven't logged."
                     : reminderResult == true
                        ? "We'll nudge you at \(reminderTimeText) if you haven't logged."
                        : "You can turn reminders on anytime in Settings.")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if reminderResult == nil {
                Button("Turn On") {
                    Task {
                        let granted = await notificationService.requestAuthorization()
                        TelemetryService.notificationPermissionResult(granted: granted, source: "drinkLogged")
                        withAnimation { reminderResult = granted }
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(brand.buttonGradient))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }

    private var visibilityStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(statusColor)

            Text(statusText)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }

    private var statusIcon: String {
        if celebration.willPostGlobally { return "globe" }
        switch celebration.visibility {
        case .friends: return "person.2.fill"
        case .public: return "globe"
        case .onlyMe: return "lock.fill"
        }
    }

    private var statusColor: Color {
        if celebration.willPostGlobally { return .green }
        switch celebration.visibility {
        case .friends: return .dietCokeRed
        case .public: return .green
        case .onlyMe: return .dietCokeDarkSilver
        }
    }

    private var statusText: String {
        if celebration.willPostGlobally {
            return "Your photo is on its way to the Global feed"
        }
        switch celebration.visibility {
        case .friends: return "Shared with your friends"
        case .public: return "Shared publicly"
        case .onlyMe: return "Saved privately, just for you"
        }
    }
}

#if DEBUG
#Preview {
    DrinkLoggedSheet(celebration: LoggedDrinkCelebration(
        entry: DrinkEntry(type: .regularCan),
        photo: nil,
        visibility: .friends,
        willPostGlobally: false
    ))
    .withPreviewEnvironment()
}
#endif
