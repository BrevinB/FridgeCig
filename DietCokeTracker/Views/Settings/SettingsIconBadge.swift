import SwiftUI

/// 40×40 gradient circle icon used as the leading element of every settings row.
/// Centralizes the pattern that previously appeared inlined 14+ times in SettingsView.
struct SettingsIconBadge: View {
    let systemImage: String
    let tint: Color
    var iconColor: Color? = nil
    var size: CGFloat = 40
    var iconSize: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.2), tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: systemImage)
                .foregroundColor(iconColor ?? tint)
                .font(.system(size: iconSize, weight: .medium))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsIconBadge(systemImage: "crown.fill", tint: .dietCokeRed)
        SettingsIconBadge(systemImage: "bell.fill", tint: .blue)
        SettingsIconBadge(systemImage: "heart.text.square.fill", tint: .red)
        SettingsIconBadge(systemImage: "trash", tint: .red)
    }
    .padding()
}
