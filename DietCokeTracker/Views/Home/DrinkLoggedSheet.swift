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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingShareSheet = false
    @State private var iconScale: CGFloat = 0.4

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
        .presentationDetents([.medium])
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
