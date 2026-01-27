import Foundation
import SwiftUI
import UIKit

// MARK: - Share Image Renderer

/// Utility for rendering SwiftUI views to images at various sizes
@MainActor
class ShareImageRenderer {

    // MARK: - Singleton

    static let shared = ShareImageRenderer()

    private init() {}

    // MARK: - Render Methods

    /// Render any SwiftUI view to a UIImage at the specified format size
    func render<V: View>(_ view: V, format: ShareFormat) -> UIImage? {
        render(view, size: format.size)
    }

    /// Render any SwiftUI view to a UIImage at a specific size
    func render<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        // Force layout
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Render a view with a completion handler (for async contexts)
    func renderAsync<V: View>(_ view: V, format: ShareFormat) async -> UIImage? {
        return render(view, format: format)
    }

    // MARK: - Share Content Rendering

    /// Render shareable content with customization
    func renderShareableContent(
        _ content: any ShareableContent,
        customization: ShareCustomization
    ) -> UIImage? {
        let view = ShareCardView(content: content, customization: customization)
        return render(view, format: customization.format)
    }

    // MARK: - Batch Rendering

    /// Render the same content in multiple formats
    func renderAllFormats<V: View>(_ view: @escaping (ShareFormat) -> V) -> [ShareFormat: UIImage] {
        var results: [ShareFormat: UIImage] = [:]

        for format in ShareFormat.allCases {
            if let image = render(view(format), format: format) {
                results[format] = image
            }
        }

        return results
    }

    // MARK: - Preview Generation

    /// Generate a smaller preview image for UI display
    func renderPreview<V: View>(_ view: V, format: ShareFormat, maxDimension: CGFloat = 400) -> UIImage? {
        let scale = min(maxDimension / format.width, maxDimension / format.height)
        let previewSize = CGSize(
            width: format.width * scale,
            height: format.height * scale
        )

        return render(view, size: previewSize)
    }
}

// MARK: - Image Utilities

extension UIImage {
    /// Compress image data for sharing
    func compressedData(quality: CGFloat = 0.9) -> Data? {
        jpegData(compressionQuality: quality)
    }

    /// Scale image while maintaining aspect ratio
    func scaled(toFit maxDimension: CGFloat) -> UIImage? {
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Share Activity Controller

extension ShareImageRenderer {
    /// Create a share activity view controller for the given image
    func shareActivityController(for image: UIImage, caption: String? = nil) -> UIActivityViewController {
        var items: [Any] = [image]
        if let caption = caption {
            items.append(caption)
        }

        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude certain activity types if needed
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]

        return controller
    }
}
