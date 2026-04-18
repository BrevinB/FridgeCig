import SwiftUI

struct EmojiPickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var emojiText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    if emojiText.isEmpty {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 40))
                            .foregroundColor(.dietCokeDarkSilver)
                    } else {
                        Text(emojiText)
                            .font(.system(size: 50))
                    }
                }

                // Emoji text field
                TextField("Tap to pick emoji", text: $emojiText)
                    .font(.system(size: 48))
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onChange(of: emojiText) { _, newValue in
                        let filtered = newValue.filter { $0.isEmoji }
                        if let lastEmoji = filtered.last {
                            emojiText = String(lastEmoji)
                        } else {
                            emojiText = ""
                        }
                    }
                    .frame(height: 60)

                Text("Tap the field and use the emoji keyboard")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)

                Spacer()
            }
            .padding(.top, 32)
            .padding(.horizontal)
            .navigationTitle("Pick an Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if !emojiText.isEmpty {
                            onSelect(emojiText)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(emojiText.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
