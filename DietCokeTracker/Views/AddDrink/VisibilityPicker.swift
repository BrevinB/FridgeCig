import SwiftUI

/// Audience picker on the Add Drink screen.
///
/// Public is always offered when drink sharing is on, even before the user has
/// opted into the Global feed and even without a photo attached. Hiding it until
/// both were true meant the Global feed was undiscoverable from the only screen
/// where someone decides what to do with a drink — the opt-in lived three
/// screens away behind a gear icon, so the option quite literally did not exist
/// for anyone who hadn't already gone looking for it.
///
/// Instead, the unmet requirement becomes the prompt: tapping Public either asks
/// for consent or asks for a photo.
struct VisibilityPicker: View {
    @Binding var visibility: PostVisibility
    var hasPhoto: Bool = false
    /// Invoked when the user picks Public without a photo, so the parent can
    /// open the camera.
    var onRequestPhoto: (() -> Void)?

    @EnvironmentObject private var activityService: ActivityFeedService
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingGlobalInvite = false
    /// Opening the camera has to wait until the invite sheet is fully gone —
    /// presenting a sheet from a dismissing sheet drops it.
    @State private var pendingPhotoRequest = false

    init(
        visibility: Binding<PostVisibility>,
        hasPhoto: Bool = false,
        onRequestPhoto: (() -> Void)? = nil
    ) {
        self._visibility = visibility
        self.hasPhoto = hasPhoto
        self.onRequestPhoto = onRequestPhoto
    }

    private var prefs: UserSharingPreferences {
        activityService.sharingPreferences
    }

    private var availableOptions: [PostVisibility] {
        // A global "don't share my drinks" setting still wins over everything.
        prefs.shareDrinkLogs ? PostVisibility.allCases : [.onlyMe]
    }

    private var isOptedIntoGlobal: Bool {
        prefs.sharePhotosGlobally && prefs.showPhotosInFeed
    }

    /// What still stands between this post and the Global feed.
    private var publicBlocker: PublicBlocker? {
        if !isOptedIntoGlobal { return .needsOptIn }
        if !hasPhoto { return .needsPhoto }
        return nil
    }

    private enum PublicBlocker {
        case needsOptIn
        case needsPhoto
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who can see this?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)

            HStack(spacing: 8) {
                ForEach(availableOptions) { option in
                    VisibilityChip(
                        option: option,
                        isSelected: visibility == option,
                        // Public reads as "available, one step away" rather than
                        // selected, until the step is done.
                        isPending: option == .public && publicBlocker != nil
                    ) {
                        select(option)
                    }
                }
            }

            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundColor(.dietCokeDarkSilver)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .sheet(isPresented: $showingGlobalInvite, onDismiss: {
            if pendingPhotoRequest {
                pendingPhotoRequest = false
                onRequestPhoto?()
            }
        }) {
            GlobalFeedInviteSheet {
                // Consent granted — carry the user's original intent through.
                visibility = .public
                pendingPhotoRequest = !hasPhoto
            }
        }
    }

    private var hint: String? {
        guard availableOptions.contains(.public) else { return nil }

        switch publicBlocker {
        case .needsOptIn:
            return "Public posts your photo to the Global feed for all FridgeCig users. Tap to see how it works."
        case .needsPhoto:
            return "Public needs a photo — tap to add one."
        case nil:
            return visibility == .public
                ? "This photo will appear in the Global feed."
                : nil
        }
    }

    private func select(_ option: PostVisibility) {
        guard option == .public else {
            withAnimation(.easeInOut(duration: 0.2)) { visibility = option }
            return
        }

        switch publicBlocker {
        case .needsOptIn:
            HapticManager.lightImpact()
            showingGlobalInvite = true
        case .needsPhoto:
            HapticManager.lightImpact()
            withAnimation(.easeInOut(duration: 0.2)) { visibility = .public }
            onRequestPhoto?()
        case nil:
            withAnimation(.easeInOut(duration: 0.2)) { visibility = .public }
        }
    }
}

// MARK: - Chip

private struct VisibilityChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let option: PostVisibility
    let isSelected: Bool
    let isPending: Bool
    let action: () -> Void

    private var foreground: Color {
        if isSelected && !isPending { return .white }
        return isPending ? .dietCokeRed : .dietCokeCharcoal
    }

    private var background: Color {
        if isSelected && !isPending { return .dietCokeRed }
        if isPending { return Color.dietCokeRed.opacity(colorScheme == .dark ? 0.18 : 0.1) }
        return colorScheme == .dark ? Color(white: 0.15) : Color(.systemGray6)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(option.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(foreground)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isPending && isSelected ? Color.dietCokeRed.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
private struct VisibilityPickerPreviewWrapper: View {
    @State private var visibility: PostVisibility = .friends
    let hasPhoto: Bool
    var body: some View {
        VisibilityPicker(visibility: $visibility, hasPhoto: hasPhoto)
            .padding()
    }
}

#Preview("No photo") {
    VisibilityPickerPreviewWrapper(hasPhoto: false)
        .withPreviewEnvironment()
}

#Preview("With photo") {
    VisibilityPickerPreviewWrapper(hasPhoto: true)
        .withPreviewEnvironment()
}
#endif
