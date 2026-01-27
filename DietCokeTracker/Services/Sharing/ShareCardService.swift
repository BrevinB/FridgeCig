import Foundation
import SwiftUI
import Combine

// MARK: - Share Card Service

/// Main service managing share flow, state, and customization presets
@MainActor
class ShareCardService: ObservableObject {

    // MARK: - Published State

    @Published var currentContent: (any ShareableContent)?
    @Published var customization: ShareCustomization = .milestoneDefault
    @Published var isEditorPresented: Bool = false
    @Published var isGeneratingImage: Bool = false
    @Published var generatedImage: UIImage?

    // MARK: - Persistence Keys

    private let lastThemeKey = "ShareCard_LastTheme"
    private let lastFormatKey = "ShareCard_LastFormat"
    private let savedPresetsKey = "ShareCard_SavedPresets"

    // MARK: - Dependencies

    private let renderer = ShareImageRenderer.shared

    // MARK: - Initialization

    init() {
        loadUserPreferences()
    }

    // MARK: - Content Management

    /// Set content to share (milestone, recap, etc.)
    func setContent(_ content: any ShareableContent) {
        currentContent = content
        // Reset customization based on content type
        switch content.contentType {
        case .milestone:
            customization = .milestoneDefault
        case .weeklyRecap:
            customization = .recapDefault
        default:
            customization = .milestoneDefault
        }
        // Apply saved theme preference
        if let savedTheme = loadLastTheme() {
            customization.theme = savedTheme
        }
        if let savedFormat = loadLastFormat() {
            customization.format = savedFormat
        }
    }

    /// Clear current content
    func clearContent() {
        currentContent = nil
        generatedImage = nil
    }

    // MARK: - Customization

    func setTheme(_ theme: ShareTheme) {
        customization.theme = theme
        saveLastTheme(theme)
    }

    func setFormat(_ format: ShareFormat) {
        customization.format = format
        saveLastFormat(format)
    }

    func addSticker(_ sticker: Sticker, at position: CGPoint, in size: CGSize) {
        var placed = PlacedSticker(sticker: sticker)
        placed.setPosition(position, in: size)
        customization.stickers.append(placed)
    }

    func removeSticker(_ sticker: PlacedSticker) {
        customization.stickers.removeAll { $0.id == sticker.id }
    }

    func updateSticker(_ sticker: PlacedSticker) {
        if let index = customization.stickers.firstIndex(where: { $0.id == sticker.id }) {
            customization.stickers[index] = sticker
        }
    }

    func setPhotoBackground(_ assetId: String?) {
        customization.photoBackgroundId = assetId
    }

    func setCustomAccentColor(_ color: Color?) {
        customization.setAccentColor(color)
    }

    func toggleBranding(_ show: Bool) {
        customization.showBranding = show
    }

    func toggleUsername(_ show: Bool) {
        customization.showUsername = show
    }

    // MARK: - Image Generation

    func generateImage() async -> UIImage? {
        guard let content = currentContent else { return nil }

        isGeneratingImage = true
        defer { isGeneratingImage = false }

        // Create the share card view with current customization
        let image = renderer.renderShareableContent(content, customization: customization)
        generatedImage = image
        return image
    }

    func generatePreview() -> UIImage? {
        guard let content = currentContent else { return nil }

        let view = ShareCardView(content: content, customization: customization)
        return renderer.renderPreview(view, format: customization.format)
    }

    // MARK: - Sharing

    func share(from viewController: UIViewController) async {
        guard let image = await generateImage() else { return }

        let caption = generateShareCaption()
        let activityController = renderer.shareActivityController(for: image, caption: caption)

        // Configure for iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        viewController.present(activityController, animated: true)
    }

    private func generateShareCaption() -> String? {
        guard let content = currentContent else { return nil }

        switch content.contentType {
        case .milestone:
            return "\(content.shareTitle) \(content.shareSubtitle) #FridgeCig"
        case .weeklyRecap:
            return "My weekly recap: \(content.shareValue) Diet Cokes! #FridgeCig"
        default:
            return nil
        }
    }

    // MARK: - Presets

    struct SharePreset: Identifiable, Codable {
        let id: UUID
        let name: String
        let customization: ShareCustomization

        init(id: UUID = UUID(), name: String, customization: ShareCustomization) {
            self.id = id
            self.name = name
            self.customization = customization
        }
    }

    @Published private(set) var savedPresets: [SharePreset] = []

    func saveCurrentAsPreset(name: String) {
        let preset = SharePreset(name: name, customization: customization)
        savedPresets.append(preset)
        savePresets()
    }

    func loadPreset(_ preset: SharePreset) {
        customization = preset.customization
    }

    func deletePreset(_ preset: SharePreset) {
        savedPresets.removeAll { $0.id == preset.id }
        savePresets()
    }

    // MARK: - Persistence

    private func loadUserPreferences() {
        loadPresets()
    }

    private func saveLastTheme(_ theme: ShareTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: lastThemeKey)
    }

    private func loadLastTheme() -> ShareTheme? {
        guard let rawValue = UserDefaults.standard.string(forKey: lastThemeKey) else {
            return nil
        }
        return ShareTheme(rawValue: rawValue)
    }

    private func saveLastFormat(_ format: ShareFormat) {
        UserDefaults.standard.set(format.rawValue, forKey: lastFormatKey)
    }

    private func loadLastFormat() -> ShareFormat? {
        guard let rawValue = UserDefaults.standard.string(forKey: lastFormatKey) else {
            return nil
        }
        return ShareFormat(rawValue: rawValue)
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(savedPresets)
            UserDefaults.standard.set(data, forKey: savedPresetsKey)
        } catch {
            print("Failed to save presets: \(error)")
        }
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: savedPresetsKey) else {
            return
        }
        do {
            savedPresets = try JSONDecoder().decode([SharePreset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
        }
    }

    // MARK: - Premium Check

    func canUseCustomization(_ customization: ShareCustomization, isPremium: Bool) -> Bool {
        if isPremium { return true }
        return !customization.usesPremiumFeatures
    }

    func premiumFeaturesUsed(in customization: ShareCustomization) -> [String] {
        var features: [String] = []

        if customization.theme.isPremium {
            features.append("Premium Theme: \(customization.theme.displayName)")
        }
        if customization.format.isPremium {
            features.append("Premium Format: \(customization.format.displayName)")
        }
        if customization.hasPhotoBackground {
            features.append("Photo Background")
        }
        if customization.hasStickers {
            features.append("Stickers")
        }
        if customization.customAccentColor != nil {
            features.append("Custom Colors")
        }

        return features
    }
}

// MARK: - Environment Key

struct ShareCardServiceKey: EnvironmentKey {
    static let defaultValue: ShareCardService? = nil
}

extension EnvironmentValues {
    var shareCardService: ShareCardService? {
        get { self[ShareCardServiceKey.self] }
        set { self[ShareCardServiceKey.self] = newValue }
    }
}
