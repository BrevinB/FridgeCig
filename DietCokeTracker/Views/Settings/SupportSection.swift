import SwiftUI
import StoreKit
import UIKit

struct SupportSection: View {
    var body: some View {
        Section {
            Button {
                if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first {
                    AppStore.requestReview(in: windowScene)
                }
            } label: {
                SettingsRow(icon: "star.fill", tint: .orange, title: "Rate FridgeCig")
            }

            Link(destination: URL(string: "mailto:brevbot2@gmail.com")!) {
                SettingsRow(icon: "envelope.fill", tint: .blue, title: "Contact Us")
            }

            Link(destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/privacy.html")!) {
                SettingsRow(icon: "lock.shield.fill", tint: .gray, title: "Privacy Policy")
            }

            Link(destination: URL(string: "https://brevinb.github.io/FridgeCig-Legal/terms.html")!) {
                SettingsRow(icon: "doc.text.fill", tint: .gray, title: "Terms of Service")
            }
        } header: {
            Text("Support")
        }
    }
}

/// Light-weight badge+title row shared by simple settings entries.
struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            SettingsIconBadge(systemImage: icon, tint: tint)
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview("Section") {
    NavigationStack {
        List { SupportSection() }
    }
}

#Preview("Row") {
    SettingsRow(icon: "star.fill", tint: .orange, title: "Rate FridgeCig")
        .padding()
}
