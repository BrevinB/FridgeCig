import SwiftUI

/// The one-time opt-in for the Global feed.
///
/// This used to live only in Sharing Settings, behind a gear icon inside a tab
/// most people never opened — which meant the Global feed was invisible from the
/// one screen where someone actually decides what to do with a drink they just
/// logged. This sheet is presentable from anywhere, so the ask can happen at the
/// moment of intent.
struct GlobalFeedInviteSheet: View {
    /// Called after the user opts in, so the presenting screen can act on it
    /// (select Public, open the camera, refresh the feed).
    var onEnabled: (() -> Void)?

    @EnvironmentObject private var activityService: ActivityFeedService
    @EnvironmentObject private var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isEnabling = false

    init(onEnabled: (() -> Void)? = nil) {
        self.onEnabled = onEnabled
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    hero
                    points

                    VStack(spacing: 12) {
                        Button(action: enable) {
                            HStack(spacing: 8) {
                                if isEnabling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "globe")
                                }
                                Text(isEnabling ? "Turning on…" : "Share to the Global Feed")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(isEnabling)

                        Button("Not Now") { dismiss() }
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    Text("You can turn this off any time in Sharing Settings. Turning it off hides your future photos — it doesn't delete ones you've already shared.")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Global Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.18), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.dietCokeRed, .dietCokeDeepRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Put your can on the map")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)
                    .multilineTextAlignment(.center)

                Text("The Global feed is every FridgeCig user's drink photos in one place. Share yours and people outside your friends list can react to it.")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Points

    private var points: some View {
        VStack(spacing: 14) {
            InvitePoint(
                icon: "camera.fill",
                tint: .dietCokeRed,
                title: "Only photos, only when you pick Public",
                detail: "Drinks logged without a photo, or set to Friends or Only Me, never go global."
            )
            InvitePoint(
                icon: "checkmark.shield.fill",
                tint: .green,
                title: "Screened before it posts",
                detail: "Every photo is checked on your device first. Anything flagged stays out of the feed."
            )
            InvitePoint(
                icon: "person.crop.circle.badge.questionmark",
                tint: .blue,
                title: "Just your display name",
                detail: "No location, no real name, nothing from your private stats."
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
    }

    // MARK: - Actions

    private func enable() {
        isEnabling = true
        HapticManager.success()

        activityService.setGlobalPhotoSharing(true)

        Task {
            await identityService.setSharePhotosGlobally(true)
            isEnabling = false
            onEnabled?()
            dismiss()
        }
    }
}

// MARK: - Invite Point

private struct InvitePoint: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dietCokeCharcoal)

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#if DEBUG
#Preview {
    GlobalFeedInviteSheet()
        .withPreviewEnvironment()
}
#endif
