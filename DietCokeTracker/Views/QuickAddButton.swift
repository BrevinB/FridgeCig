import SwiftUI
import UIKit

struct QuickAddButton: View {
    let type: DrinkType
    let action: () -> Void
    var onAddWithRating: ((DrinkRating) -> Void)? = nil
    var onAddWithPhoto: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            action()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(.dietCokeRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.shortName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)

                    Text("\(String(format: "%.0f", type.ounces)) oz")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.dietCokeRed)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.dietCokeCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            // Rating options
            Section("Rate this DC") {
                ForEach(DrinkRating.allCases) { rating in
                    Button {
                        onAddWithRating?(rating)
                    } label: {
                        Label(rating.displayName, systemImage: rating.icon)
                    }
                }
            }

            // Photo option
            if onAddWithPhoto != nil {
                Section {
                    Button {
                        onAddWithPhoto?()
                    } label: {
                        Label("Add with Photo", systemImage: "camera.fill")
                    }
                }
            }

            // Quick add (no extras)
            Section {
                Button {
                    action()
                } label: {
                    Label("Quick Add", systemImage: "plus.circle")
                }
            }
        }
    }
}

struct QuickAddButtonCompact: View {
    let type: DrinkType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.dietCokeRed.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(.dietCokeRed)
                }

                Text(type.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        QuickAddButton(
            type: .regularCan,
            action: { print("Quick add") },
            onAddWithRating: { rating in print("Add with rating: \(rating)") },
            onAddWithPhoto: { print("Add with photo") }
        )
        QuickAddButton(type: .mcdonaldsLarge, action: {})

        HStack(spacing: 20) {
            QuickAddButtonCompact(type: .regularCan) {}
            QuickAddButtonCompact(type: .tallCan) {}
            QuickAddButtonCompact(type: .bottle20oz) {}
        }
    }
    .padding()
}
