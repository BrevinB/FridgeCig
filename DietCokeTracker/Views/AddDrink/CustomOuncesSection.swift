import SwiftUI

struct CustomOuncesSection: View {
    @Binding var useCustomOunces: Bool
    @Binding var customOuncesText: String
    let defaultOunces: Double

    private var ouncesValidation: EntryValidator.ValidationResult {
        guard let oz = Double(customOuncesText) else {
            return .valid()
        }
        return EntryValidator.validateOunces(oz)
    }

    private var hasError: Bool {
        useCustomOunces && !ouncesValidation.isValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    useCustomOunces.toggle()
                    if useCustomOunces && customOuncesText.isEmpty {
                        customOuncesText = String(format: "%.1f", defaultOunces)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.dietCokeRed)
                    Text("Custom Amount")
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    Spacer()

                    Image(systemName: useCustomOunces ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(useCustomOunces ? .dietCokeRed : .dietCokeDarkSilver)
                }
            }

            if useCustomOunces {
                VStack(spacing: 8) {
                    Text("Poured some out? Only had half? Enter the actual amount.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Min: \(Int(EntryValidator.minOuncesPerEntry)) oz • Max: \(Int(EntryValidator.maxOuncesPerEntry)) oz")
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        TextField("Amount", text: $customOuncesText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(hasError ? Color.red : Color.dietCokeRed.opacity(0.3), lineWidth: hasError ? 2 : 1)
                            )

                        Text("oz")
                            .font(.headline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    if hasError, let message = ouncesValidation.errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(message)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 8) {
                        QuickOzButton(label: "1/4", multiplier: 0.25, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "1/2", multiplier: 0.5, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "3/4", multiplier: 0.75, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                        QuickOzButton(label: "Full", multiplier: 1.0, defaultOunces: defaultOunces, customOuncesText: $customOuncesText)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

struct QuickOzButton: View {
    let label: String
    let multiplier: Double
    let defaultOunces: Double
    @Binding var customOuncesText: String

    private var resultingOunces: Double {
        defaultOunces * multiplier
    }

    var body: some View {
        Button {
            customOuncesText = String(format: "%.1f", resultingOunces)
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.dietCokeSilver.opacity(0.2))
                .foregroundColor(.dietCokeCharcoal)
                .cornerRadius(8)
        }
        .accessibilityLabel("\(label) of default, \(String(format: "%.1f", resultingOunces)) ounces")
    }
}

#if DEBUG
private struct CustomOuncesPreviewWrapper: View {
    @State private var useCustom: Bool
    @State private var text: String
    init(useCustom: Bool = true, text: String = "8.0") {
        _useCustom = State(initialValue: useCustom)
        _text = State(initialValue: text)
    }
    var body: some View {
        CustomOuncesSection(
            useCustomOunces: $useCustom,
            customOuncesText: $text,
            defaultOunces: 12
        )
        .padding()
    }
}

#Preview("Expanded") { CustomOuncesPreviewWrapper(useCustom: true, text: "8.0") }
#Preview("Collapsed") { CustomOuncesPreviewWrapper(useCustom: false, text: "") }
#endif
