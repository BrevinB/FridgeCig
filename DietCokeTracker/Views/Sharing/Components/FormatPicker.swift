import SwiftUI

// MARK: - Format Picker

/// Picker for selecting share card format (Story, Post, Twitter, TikTok)
struct FormatPicker: View {
    @Binding var selectedFormat: ShareFormat
    let isPremium: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                ForEach(ShareFormat.allCases) { format in
                    FormatButton(
                        format: format,
                        isSelected: selectedFormat == format,
                        isLocked: format.isPremium && !isPremium
                    ) {
                        if !format.isPremium || isPremium {
                            selectedFormat = format
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Format Button

struct FormatButton: View {
    let format: ShareFormat
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Format shape preview
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.dietCokeRed.opacity(0.2) : Color.gray.opacity(0.1))
                        .aspectRatio(format.aspectRatio, contentMode: .fit)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.dietCokeRed : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )

                    // Lock icon
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Text(format.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .dietCokeRed : .secondary)
            }
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.5 : 1)
    }
}

// MARK: - Compact Format Picker

/// Horizontal scrollable format picker for tight spaces
struct CompactFormatPicker: View {
    @Binding var selectedFormat: ShareFormat
    let isPremium: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ShareFormat.allCases) { format in
                    CompactFormatChip(
                        format: format,
                        isSelected: selectedFormat == format,
                        isLocked: format.isPremium && !isPremium
                    ) {
                        if !format.isPremium || isPremium {
                            selectedFormat = format
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CompactFormatChip: View {
    let format: ShareFormat
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: format.icon)
                    .font(.caption)

                Text(format.displayName)
                    .font(.caption.weight(.medium))

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.dietCokeRed : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.6 : 1)
    }
}

// MARK: - Preview

#if DEBUG
struct FormatPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            FormatPicker(
                selectedFormat: .constant(.instagramStory),
                isPremium: false
            )

            CompactFormatPicker(
                selectedFormat: .constant(.instagramPost),
                isPremium: true
            )
        }
        .padding()
    }
}
#endif
