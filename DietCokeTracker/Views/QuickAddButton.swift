import SwiftUI
import UIKit

struct QuickAddButton: View {
    let type: DrinkType
    var brand: BeverageBrand = .dietCoke
    let action: () -> Void
    var onAddWithRating: ((DrinkRating) -> Void)? = nil
    var onAddWithPhoto: (() -> Void)? = nil

    @State private var isExpanded = false
    @State private var isPressed = false
    @State private var showRatingPicker = false
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        brand.color
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main tappable area
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(isExpanded ? 0.3 : 0.2),
                                        accentColor.opacity(isExpanded ? 0.15 : 0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: type.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(accentColor)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.shortName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.dietCokeCharcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("\(String(format: "%.0f", type.ounces)) oz")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.dietCokeSilver)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded options
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.dietCokeSilver.opacity(0.2))

                    if showRatingPicker {
                        // Rating picker view
                        ratingPickerView
                    } else {
                        // Action buttons
                        actionButtonsView
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isExpanded ? Color.dietCokeRed.opacity(0.3) : Color.dietCokeSilver.opacity(0.2),
                    lineWidth: isExpanded ? 1.5 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
            radius: isExpanded ? 12 : 8,
            x: 0,
            y: isExpanded ? 4 : 2
        )
        .onChange(of: isExpanded) { _, expanded in
            if !expanded {
                showRatingPicker = false
            }
        }
    }

    // MARK: - Action Buttons View

    private var actionButtonsView: some View {
        HStack(spacing: 0) {
            // Quick Add
            ExpandedActionButton(
                icon: "plus",
                label: "Quick",
                color: .dietCokeRed,
                accessibilityLabel: "Quick add \(type.shortName)"
            ) {
                performAction {
                    action()
                }
            }

            Divider()
                .frame(height: 44)
                .background(Color.dietCokeSilver.opacity(0.2))
                .accessibilityHidden(true)

            // Add with Photo
            ExpandedActionButton(
                icon: "camera.fill",
                label: "Photo",
                color: .blue,
                accessibilityLabel: "Add \(type.shortName) with photo"
            ) {
                performAction {
                    onAddWithPhoto?()
                }
            }

            Divider()
                .frame(height: 44)
                .background(Color.dietCokeSilver.opacity(0.2))
                .accessibilityHidden(true)

            // Add with Rating
            ExpandedActionButton(
                icon: "star.fill",
                label: "Rate",
                color: .orange,
                accessibilityLabel: "Add \(type.shortName) with rating"
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRatingPicker = true
                }
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Rating Picker View

    private var ratingPickerView: some View {
        VStack(spacing: 12) {
            // Back button and title
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showRatingPicker = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                Text("Rate this DC")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                // Spacer for alignment
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Rating options
            HStack(spacing: 8) {
                ForEach(DrinkRating.allCases) { rating in
                    QuickRatingButton(rating: rating) {
                        performAction {
                            onAddWithRating?(rating)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    // MARK: - Helpers

    private func performAction(_ action: () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        action()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isExpanded = false
            showRatingPicker = false
        }
    }
}

// MARK: - Expanded Action Button

struct ExpandedActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var accessibilityLabel: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout.weight(.medium))
                    .foregroundColor(color)

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isPressed ? color.opacity(0.1) : Color.clear)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? label)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Quick Rating Button

struct QuickRatingButton: View {
    let rating: DrinkRating
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: rating.icon)
                .font(.title3.weight(.medium))
                .foregroundColor(rating.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isPressed ? rating.color.opacity(0.2) : rating.color.opacity(0.1))
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate as \(rating.rawValue)")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Compact Button (unchanged)

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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            QuickAddButton(
                type: .regularCan,
                action: { print("Quick add") },
                onAddWithRating: { rating in print("Add with rating: \(rating)") },
                onAddWithPhoto: { print("Add with photo") }
            )
            QuickAddButton(
                type: .mcdonaldsLarge,
                action: { print("Quick add") },
                onAddWithRating: { rating in print("Add with rating: \(rating)") },
                onAddWithPhoto: { print("Add with photo") }
            )
        }

        HStack(spacing: 12) {
            QuickAddButton(type: .bottle20oz, action: {})
            QuickAddButton(type: .chickfilaLarge, action: {})
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
