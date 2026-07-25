import SwiftUI

/// Confirms what happened to a drink the user marked Public.
///
/// Posting globally used to produce no feedback at all: a photo that passed
/// screening and one that got rejected looked identical from the logging screen.
/// People can't repeat a behaviour they can't tell worked, and can't fix one
/// they don't know failed.
struct GlobalPostToast: View {
    // Declared ahead of the stored parameters so the trailing-closure call site
    // stays valid.
    @Environment(\.colorScheme) private var colorScheme

    let outcome: ActivityFeedService.GlobalPostOutcome
    let onTap: () -> Void
    let onDismiss: () -> Void

    private var icon: String {
        switch outcome {
        case .published: return "globe.americas.fill"
        case .blockedBySafety: return "exclamationmark.shield.fill"
        case .noPhoto: return "camera.fill"
        case .notOptedIn: return "globe.badge.chevron.backward"
        }
    }

    private var tint: Color {
        switch outcome {
        case .published: return .dietCokeRed
        case .blockedBySafety: return .orange
        case .noPhoto, .notOptedIn: return .dietCokeDarkSilver
        }
    }

    private var title: String {
        switch outcome {
        case .published: return "Shared to the Global feed"
        case .blockedBySafety: return "Kept out of the Global feed"
        case .noPhoto, .notOptedIn: return "Shared with friends only"
        }
    }

    private var detail: String {
        switch outcome {
        case .published: return "Tap to see it"
        case .blockedBySafety: return "The photo didn't pass screening. Your friends can still see it."
        case .noPhoto: return "Global posts need a photo of your drink"
        case .notOptedIn: return "Turn on global sharing to post publicly"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(tint.opacity(0.14)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.dietCokeDarkSilver)
                    .padding(8)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)
                    .accessibilityLabel("Dismiss")
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.16) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        GlobalPostToast(outcome: .published, onTap: {}, onDismiss: {})
        GlobalPostToast(outcome: .blockedBySafety, onTap: {}, onDismiss: {})
        GlobalPostToast(outcome: .noPhoto, onTap: {}, onDismiss: {})
        GlobalPostToast(outcome: .notOptedIn, onTap: {}, onDismiss: {})
    }
}
#endif
