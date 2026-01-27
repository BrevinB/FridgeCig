import SwiftUI

// MARK: - Share Preview Sheet

/// Quick preview and share sheet for share cards
struct SharePreviewSheet: View {
    let content: any ShareableContent
    @Binding var isPresented: Bool

    let isPremium: Bool
    var onPremiumTap: (() -> Void)?

    @State private var customization: ShareCustomization
    @State private var showEditor = false
    @State private var isGenerating = false
    @State private var generatedImage: UIImage?

    private let renderer = ShareImageRenderer.shared

    init(
        content: any ShareableContent,
        isPresented: Binding<Bool>,
        isPremium: Bool,
        initialTheme: ShareTheme = .classic,
        onPremiumTap: (() -> Void)? = nil
    ) {
        self.content = content
        self._isPresented = isPresented
        self.isPremium = isPremium
        self.onPremiumTap = onPremiumTap

        var initial = content.contentType == .weeklyRecap
            ? ShareCustomization.recapDefault
            : ShareCustomization.milestoneDefault
        initial.theme = initialTheme
        self._customization = State(initialValue: initial)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card preview
                cardPreview
                    .padding()

                Divider()

                // Theme picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(ShareTheme.allCases) { theme in
                            ThemeCard(
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
                    .padding()
                }

                Divider()

                // Actions
                actionsSection
                    .padding()
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            ShareEditorView(
                content: content,
                customization: $customization,
                isPresented: $showEditor,
                isPremium: isPremium,
                onShare: { performShare() },
                onPremiumTap: onPremiumTap
            )
        }
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        ShareCardPreviewContainer(
            content: content,
            customization: customization
        )
        .frame(maxHeight: 320)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                performShare()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("Share")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dietCokeRed)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isGenerating)

            // Customize button
            Button {
                showEditor = true
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Customize")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions

    private func performShare() {
        isGenerating = true

        Task {
            let image = renderer.renderShareableContent(content, customization: customization)
            generatedImage = image

            await MainActor.run {
                isGenerating = false

                if let image = image {
                    shareImage(image)
                }
            }
        }
    }

    private func shareImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        topVC.present(activityVC, animated: true)
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
