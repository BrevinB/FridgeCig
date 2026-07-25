import SwiftUI

/// "Where's your Diet Coke?" — a one-tap poke that pushes a friend to log.
///
/// This is the only social action that reaches *out* rather than reacting to
/// something already posted, which makes it the one that pulls lapsed friends
/// back in. Rate-limited per friend so it stays a nudge and not a nuisance.
struct NudgeButton: View {
    let friend: UserProfile
    /// Compact renders as an icon-only circle for tight rows.
    var compact: Bool = false

    @EnvironmentObject private var socialNotifications: SocialNotificationService
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSending = false
    @State private var justSent = false
    @State private var cooldownRemaining: TimeInterval?

    private var isOnCooldown: Bool {
        cooldownRemaining != nil
    }

    private var isDisabled: Bool {
        isSending || justSent || isOnCooldown
    }

    var body: some View {
        Button(action: sendNudge) {
            if compact {
                compactLabel
            } else {
                fullLabel
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .task(id: friend.userIDString) { await trackCooldown() }
        .accessibilityLabel(accessibilityLabel)
    }

    /// Keeps the countdown label honest while the button is on cooldown, and
    /// stops as soon as it clears or the view goes away. No timer runs in the
    /// common case where the friend is nudgeable.
    private func trackCooldown() async {
        refreshCooldown()
        while !Task.isCancelled && cooldownRemaining != nil {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            refreshCooldown()
        }
    }

    // MARK: - Labels

    private var compactLabel: some View {
        Image(systemName: iconName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(foreground)
            .frame(width: 34, height: 34)
            .background(Circle().fill(background))
    }

    private var fullLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .symbolEffect(.bounce, value: justSent)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(background))
    }

    private var iconName: String {
        if justSent { return "checkmark" }
        if isOnCooldown { return "clock" }
        return "hand.wave.fill"
    }

    private var title: String {
        if justSent { return "Nudged!" }
        if let remaining = cooldownRemaining { return "Nudged \(Self.shortDuration(remaining)) left" }
        return "Nudge"
    }

    private var foreground: Color {
        if justSent { return .green }
        if isOnCooldown { return .dietCokeDarkSilver }
        return .dietCokeRed
    }

    private var background: Color {
        if justSent { return Color.green.opacity(0.12) }
        if isOnCooldown { return colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray6) }
        return Color.dietCokeRed.opacity(colorScheme == .dark ? 0.22 : 0.12)
    }

    private var accessibilityLabel: String {
        if justSent { return "Nudge sent" }
        if isOnCooldown { return "Already nudged \(friend.displayName) recently" }
        return "Nudge \(friend.displayName)"
    }

    // MARK: - Actions

    private func sendNudge() {
        guard !isDisabled else { return }
        isSending = true
        HapticManager.friendAction()

        Task {
            let sent = await socialNotifications.nudge(friend)
            isSending = false

            if sent {
                withAnimation(.spring(response: 0.3)) { justSent = true }
                try? await Task.sleep(for: .seconds(2))
                withAnimation { justSent = false }
            } else {
                HapticManager.warning()
            }
            refreshCooldown()
        }
    }

    private func refreshCooldown() {
        cooldownRemaining = socialNotifications.nudgeCooldownRemaining(for: friend.userIDString)
    }

    /// "2h" / "45m" — short enough to sit inside a pill.
    private static func shortDuration(_ interval: TimeInterval) -> String {
        let minutes = max(1, Int(interval / 60))
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        NudgeButton(friend: UserProfile(from: UserIdentity(displayName: "Alex", friendCode: "ABC123")))
        NudgeButton(friend: UserProfile(from: UserIdentity(displayName: "Alex", friendCode: "ABC123")), compact: true)
    }
    .padding()
    .withPreviewEnvironment()
}
#endif
