import SwiftUI

struct TodayDrinksSection: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.colorScheme) private var colorScheme

    var todayEntries: [DrinkEntry] {
        store.entries.filter { $0.isToday }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TODAY'S DRINKS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()

                if !todayEntries.isEmpty {
                    Text("\(todayEntries.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.dietCokeRed)
                        .clipShape(Circle())
                }
            }

            if todayEntries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEntries) { entry in
                        DrinkRowView(entry: entry)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.dietCokeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeSilver.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "drop.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.dietCokeSilver.opacity(0.5), .dietCokeSilver.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 4) {
                Text("No drinks yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dietCokeCharcoal)
                Text("Tap + to log your first DC")
                    .font(.system(size: 13))
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#if DEBUG
#Preview("With drinks") {
    TodayDrinksSection()
        .padding()
        .withPreviewEnvironment()
}

#Preview("Empty") {
    TodayDrinksSection()
        .padding()
        .withPreviewEnvironment(populated: false)
}
#endif
