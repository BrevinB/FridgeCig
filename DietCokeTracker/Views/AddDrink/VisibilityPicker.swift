import SwiftUI

struct VisibilityPicker: View {
    @Binding var visibility: PostVisibility
    var hasPhoto: Bool = false
    @EnvironmentObject var activityService: ActivityFeedService
    @Environment(\.colorScheme) private var colorScheme

    private var availableOptions: [PostVisibility] {
        let prefs = activityService.sharingPreferences
        if !prefs.shareDrinkLogs {
            return [.onlyMe]
        }
        if !prefs.sharePhotosGlobally || !hasPhoto {
            return [.onlyMe, .friends]
        }
        return PostVisibility.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who can see this?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dietCokeCharcoal)

            HStack(spacing: 8) {
                ForEach(availableOptions) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            visibility = option
                        }
                    } label: {
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
                        .foregroundColor(visibility == option ? .white : .dietCokeCharcoal)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(visibility == option
                                      ? Color.dietCokeRed
                                      : (colorScheme == .dark ? Color(white: 0.15) : Color(.systemGray6)))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
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
