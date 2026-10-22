import SwiftUI

/// "Post to" choice for a drink log. Picking Global here is the consent to
/// post publicly, so when it's selected the picker always says so.
struct VisibilityPicker: View {
    @Binding var visibility: PostVisibility
    var hasPhoto: Bool = false
    @EnvironmentObject var activityService: ActivityFeedService
    @Environment(\.colorScheme) private var colorScheme

    private var availableOptions: [PostVisibility] {
        let prefs = activityService.sharingPreferences
        if !prefs.shareDrinkLogs { return [.onlyMe] }
        // Sharing Settings is the off switch for Global.
        return prefs.sharePhotosGlobally ? [.public, .friends, .onlyMe] : [.friends, .onlyMe]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Post to")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)

            HStack(spacing: 8) {
                ForEach(availableOptions) { option in
                    optionButton(option)
                }
            }

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .animation(.easeInOut(duration: 0.2), value: visibility)
        .animation(.easeInOut(duration: 0.2), value: hasPhoto)
    }

    private var caption: String? {
        if visibility == .public {
            return "🌍 Anyone can see this photo on the Global feed."
        }
        if !hasPhoto && availableOptions.contains(.public) {
            return "Add a photo to post to the Global feed."
        }
        return nil
    }

    private func optionButton(_ option: PostVisibility) -> some View {
        let isSelected = visibility == option
        let isDisabled = option == .public && !hasPhoto

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                visibility = option
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(option == .public ? "Global" : option.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .white : .dietCokeCharcoal)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? Color.dietCokeRed
                          : (colorScheme == .dark ? Color(white: 0.15) : Color(.systemGray6)))
            )
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
