import SwiftUI

// MARK: - Share Preview Sheet

/// Streamlined share sheet with all customization options in one view
struct SharePreviewSheet: View {
    let content: any ShareableContent
    @Binding var isPresented: Bool

    let isPremium: Bool
    var onPremiumTap: (() -> Void)?

    /// Optional photos available for background (e.g., from a week's entries)
    let availablePhotos: [UIImage]

    @State private var customization: ShareCustomization
    @State private var isGenerating = false
    @State private var showActivitySheet = false
    @State private var shareFileURL: URL?
    @State private var showStickerPicker = false
    @State private var showExpandedPreview = false
    @State private var selectedBackgroundPhoto: UIImage?

    private let renderer = ShareImageRenderer.shared

    /// Check if content is a DrinkEntry with a photo available
    private var entryHasPhoto: Bool {
        guard let entry = content as? DrinkEntry else { return false }
        return entry.sharePhoto != nil
    }

    /// Check if we have photos available for background selection
    private var hasAvailablePhotos: Bool {
        !availablePhotos.isEmpty || entryHasPhoto
    }

    init(
        content: any ShareableContent,
        isPresented: Binding<Bool>,
        isPremium: Bool,
        initialTheme: ShareTheme = .classic,
        availablePhotos: [UIImage] = [],
        onPremiumTap: (() -> Void)? = nil
    ) {
        self.content = content
        self._isPresented = isPresented
        self.isPremium = isPremium
        self.availablePhotos = availablePhotos
        self.onPremiumTap = onPremiumTap

        var initial = content.contentType == .weeklyRecap
            ? ShareCustomization.recapDefault
            : ShareCustomization.milestoneDefault
        initial.theme = initialTheme

        // If photos are available, default to using photo background
        if !availablePhotos.isEmpty {
            initial.useEntryPhotoBackground = true
        }

        self._customization = State(initialValue: initial)

        // Set initial selected photo if available
        if let firstPhoto = availablePhotos.first {
            self._selectedBackgroundPhoto = State(initialValue: firstPhoto)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Interactive preview
                previewSection

                Divider()

                // Customization controls
                ScrollView {
                    VStack(spacing: 20) {
                        // Background picker (photo vs theme) - show when photos available
                        if hasAvailablePhotos {
                            backgroundPickerSection
                        }

                        // Theme picker - show when not using photo background
                        if !hasAvailablePhotos || !customization.useEntryPhotoBackground {
                            themesSection
                        }

                        // Format picker
                        formatSection

                        // Stickers
                        stickersSection

                        // Options
                        optionsSection
                    }
                    .padding(.vertical, 16)
                }

                Divider()

                // Share button
                shareButton
                    .padding()
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerSheet(
                placedStickers: $customization.stickers,
                isPremium: isPremium,
                onPremiumTap: onPremiumTap
            )
        }
        .fullScreenCover(isPresented: $showExpandedPreview) {
            ExpandedStickerArrangeView(
                content: content,
                customization: $customization,
                backgroundPhoto: effectiveBackgroundPhoto
            )
        }
        .onChange(of: customization) { _ in
            shareFileURL = nil
        }
    }

    // MARK: - Preview Section

    /// Get the effective background photo for preview
    private var effectiveBackgroundPhoto: UIImage? {
        guard customization.useEntryPhotoBackground else { return nil }

        // For DrinkEntry, the entry has its own photo
        if let entry = content as? DrinkEntry {
            return entry.sharePhoto
        }

        // For other content, use selected photo or first available
        return selectedBackgroundPhoto ?? availablePhotos.first
    }

    private var previewSection: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                InteractiveShareCardPreview(
                    content: content,
                    customization: $customization,
                    backgroundPhoto: effectiveBackgroundPhoto
                )
                .frame(height: 280)

                // Expand button
                Button {
                    showExpandedPreview = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .padding(8)
            }

            if !customization.stickers.isEmpty {
                Text("Drag stickers to reposition \u{2022} Tap expand for easier editing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap expand to arrange stickers easier")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Background Picker

    private var backgroundPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Photo vs Theme toggle
            HStack(spacing: 12) {
                BackgroundOptionButton(
                    title: availablePhotos.count > 1 ? "Photo" : "Your Photo",
                    icon: "photo.fill",
                    isSelected: customization.useEntryPhotoBackground
                ) {
                    customization.useEntryPhotoBackground = true
                }

                BackgroundOptionButton(
                    title: "Theme",
                    icon: "paintpalette.fill",
                    isSelected: !customization.useEntryPhotoBackground
                ) {
                    customization.useEntryPhotoBackground = false
                }
            }
            .padding(.horizontal)

            // Photo selection - show when using photo background and multiple photos available
            if customization.useEntryPhotoBackground && availablePhotos.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a photo from this week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(availablePhotos.enumerated()), id: \.offset) { index, photo in
                                PhotoThumbnailButton(
                                    photo: photo,
                                    isSelected: selectedBackgroundPhoto == photo || (selectedBackgroundPhoto == nil && index == 0)
                                ) {
                                    selectedBackgroundPhoto = photo
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Themes Section

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShareTheme.allCases) { theme in
                        CompactThemeCard(
                            theme: theme,
                            isSelected: customization.theme == theme,
                            isLocked: theme.isPremium && !isPremium
                        ) {
                            if theme.isPremium && !isPremium {
                                onPremiumTap?()
                            } else {
                                customization.theme = theme
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Format")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ShareFormat.allCases) { format in
                        FormatChip(
                            format: format,
                            isSelected: customization.format == format,
                            isLocked: format.isPremium && !isPremium
                        ) {
                            if format.isPremium && !isPremium {
                                onPremiumTap?()
                            } else {
                                customization.format = format
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Stickers Section

    private var stickersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Stickers")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                if !isPremium {
                    Text("Premium")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }

                Spacer()

                Button {
                    showStickerPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.dietCokeRed)
                }
            }
            .padding(.horizontal)

            if !customization.stickers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customization.stickers) { placed in
                            HStack(spacing: 4) {
                                StickerView(sticker: placed.sticker, size: 24)
                                Button {
                                    customization.stickers.removeAll { $0.id == placed.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gray.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 12) {
            Toggle("Show Username", isOn: $customization.showUsername)
            Toggle("Show App Branding", isOn: $customization.showBranding)
        }
        .font(.subheadline)
        .padding(.horizontal)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            prepareAndShare()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Preparing..." : "Share")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.dietCokeRed)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isGenerating)
    }

    // MARK: - Actions

    private func prepareAndShare() {
        isGenerating = true

        Task {
            let image = renderer.renderShareableContent(
                content,
                customization: customization,
                backgroundPhoto: effectiveBackgroundPhoto
            )

            await MainActor.run {
                isGenerating = false

                guard let image,
                      let url = writeImageToTempFile(image) else { return }
                shareFileURL = url
                presentActivityController(for: url)
            }
        }
    }

    private func writeImageToTempFile(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FridgeCig-Share.jpg")
        // Overwrite any previous share file
        try? FileManager.default.removeItem(at: url)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private func presentActivityController(for url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.maxY - 100,
                width: 0,
                height: 0
            )
        }

        topVC.present(activityVC, animated: true)
    }
}

// MARK: - Compact Theme Card

struct CompactThemeCard: View {
    let theme: ShareTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.backgroundColor)
                        .frame(width: 56, height: 56)

                    if theme.backgroundStyle == .gradient || theme.backgroundStyle == .multiGradient {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: theme.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                    }

                    if isLocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 56, height: 56)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 2)
                )

                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .dietCokeRed : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Format Chip

struct FormatChip: View {
    let format: ShareFormat
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Aspect ratio indicator
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.dietCokeRed : Color.gray, lineWidth: 1.5)
                    .frame(width: aspectWidth, height: aspectHeight)

                Text(format.displayName)
                    .font(.caption.weight(.medium))

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.dietCokeRed.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .dietCokeRed : .primary)
        }
        .buttonStyle(.plain)
    }

    private var aspectWidth: CGFloat {
        switch format.category {
        case .vertical: return 9
        case .square: return 12
        case .horizontal: return 16
        }
    }

    private var aspectHeight: CGFloat {
        switch format.category {
        case .vertical: return 16
        case .square: return 12
        case .horizontal: return 9
        }
    }
}

// MARK: - Photo Thumbnail Button

struct PhotoThumbnailButton: View {
    let photo: UIImage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.dietCokeRed : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? Color.dietCokeRed.opacity(0.3) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expanded Sticker Arrange View

struct ExpandedStickerArrangeView: View {
    let content: any ShareableContent
    @Binding var customization: ShareCustomization
    var backgroundPhoto: UIImage?
    @Environment(\.dismiss) private var dismiss

    // Card dimensions
    private var cardWidth: CGFloat { customization.format.width }
    private var cardHeight: CGFloat { customization.format.height }

    @State private var selectedStickerId: UUID?

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            // Ensure non-negative available space
            let rawAvailableHeight = geometry.size.height - safeArea.top - safeArea.bottom - 100 // Leave room for button
            let rawAvailableWidth = geometry.size.width - 32 // Padding
            let availableHeight = max(0, rawAvailableHeight)
            let availableWidth = max(0, rawAvailableWidth)

            // Prevent division by zero
            let safeCardWidth = max(1, cardWidth)
            let safeCardHeight = max(1, cardHeight)

            let scaleToFitHeight = availableHeight / safeCardHeight
            let scaleToFitWidth = availableWidth / safeCardWidth
            // Clamp scale to a sane, finite range
            let rawScale = min(scaleToFitHeight, scaleToFitWidth)
            let scale = rawScale.isFinite ? max(0, rawScale) : 0

            let rawScaledWidth = safeCardWidth * scale
            let rawScaledHeight = safeCardHeight * scale
            let scaledWidth = rawScaledWidth.isFinite ? max(0, rawScaledWidth) : 0
            let scaledHeight = rawScaledHeight.isFinite ? max(0, rawScaledHeight) : 0

            let safeScaledWidth = (scaledWidth.isFinite && scaledWidth > 0) ? scaledWidth : 0
            let safeScaledHeight = (scaledHeight.isFinite && scaledHeight > 0) ? scaledHeight : 0

            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Arrange Stickers")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, safeArea.top + 10)

                    Spacer()

                    // Large preview with interactive stickers
                    ZStack {
                        // Base card (without stickers)
                        baseCardPreview(scale: scale, scaledWidth: scaledWidth, scaledHeight: scaledHeight)

                        // Interactive sticker layer
                        interactiveStickerLayer(scaledWidth: scaledWidth, scaledHeight: scaledHeight)
                    }
                    .modifier(SafeSizedFrame(width: safeScaledWidth, height: safeScaledHeight))

                    Spacer()

                    // Instructions
                    VStack(spacing: 8) {
                        Text("Drag to move \u{2022} Pinch to resize \u{2022} Rotate with two fingers")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        if customization.stickers.isEmpty {
                            Text("Add stickers from the share screen")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.dietCokeRed)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, safeArea.bottom + 10)
                }
            }
        }
    }

    @ViewBuilder
    private func baseCardPreview(scale: CGFloat, scaledWidth: CGFloat, scaledHeight: CGFloat) -> some View {
        let baseCustomization = ShareCustomization(
            theme: customization.theme,
            format: customization.format,
            photoBackgroundId: customization.photoBackgroundId,
            stickers: [],
            customAccentColor: customization.customAccentColor,
            customText: customization.customText,
            showUsername: customization.showUsername,
            showBranding: customization.showBranding,
            useEntryPhotoBackground: customization.useEntryPhotoBackground
        )

        let safeWidth = (scaledWidth.isFinite && scaledWidth > 0) ? scaledWidth : 0
        let safeHeight = (scaledHeight.isFinite && scaledHeight > 0) ? scaledHeight : 0

        ShareCardView(content: content, customization: baseCustomization, backgroundPhoto: backgroundPhoto)
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(Rectangle())
            .scaleEffect(scale)
            .modifier(SafeSizedFrame(width: safeWidth, height: safeHeight))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func interactiveStickerLayer(scaledWidth: CGFloat, scaledHeight: CGFloat) -> some View {
        let safeWidth = (scaledWidth.isFinite && scaledWidth > 0) ? scaledWidth : 0
        let safeHeight = (scaledHeight.isFinite && scaledHeight > 0) ? scaledHeight : 0

        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedStickerId = nil
                }

            ForEach($customization.stickers) { $sticker in
                DraggableStickerView(
                    sticker: $sticker,
                    containerSize: CGSize(width: safeWidth, height: safeHeight),
                    isSelected: selectedStickerId == sticker.id,
                    onSelect: { selectedStickerId = sticker.id },
                    onDelete: {
                        customization.stickers.removeAll { $0.id == sticker.id }
                        selectedStickerId = nil
                    }
                )
            }
        }
        .modifier(SafeSizedFrame(width: safeWidth, height: safeHeight))
    }
}

// MARK: - Safe Sized Frame Modifier

private struct SafeSizedFrame: ViewModifier {
    let width: CGFloat
    let height: CGFloat

    func body(content: Content) -> some View {
        if width > 0, width.isFinite, height > 0, height.isFinite {
            content.frame(width: width, height: height)
        } else {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SharePreviewSheet_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewSheet(
            content: MilestoneCard.forDrinkCount(100, username: "TestUser"),
            isPresented: .constant(true),
            isPremium: false
        )
    }
}
#endif

