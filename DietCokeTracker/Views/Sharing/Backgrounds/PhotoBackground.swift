import SwiftUI
import PhotosUI

// MARK: - Photo Background

/// Photo background with overlay for share cards
struct PhotoBackground: View {
    let assetId: String?

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var overlayOpacity: Double = 0.4
    var overlayColor: Color = .black

    var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder while loading
                Color.gray.opacity(0.3)

                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.white)
                }
            }

            // Dark overlay for text readability
            overlayColor.opacity(overlayOpacity)
        }
        .clipped()
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let assetId = assetId else { return }
        isLoading = true
        defer { isLoading = false }

        // Fetch the asset from Photos library
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = fetchResult.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        let targetSize = CGSize(width: 1920, height: 1920)

        await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                Task { @MainActor in
                    self.loadedImage = image
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Photo Background with Blur

/// Photo background with blur effect
struct BlurredPhotoBackground: View {
    let assetId: String?
    let blurRadius: CGFloat

    var body: some View {
        PhotoBackground(assetId: assetId, overlayOpacity: 0.2)
            .blur(radius: blurRadius)
            .scaleEffect(1.2) // Prevent blur edges from showing
    }
}

// MARK: - Static Image Background

/// Background using a UIImage directly (for previews or cached images)
struct StaticImageBackground: View {
    let image: UIImage
    var overlayOpacity: Double = 0.4
    var overlayColor: Color = .black

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)

            overlayColor.opacity(overlayOpacity)
        }
        .clipped()
    }
}

// MARK: - Preview

#if DEBUG
struct PhotoBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with placeholder (no real asset ID)
            PhotoBackground(assetId: nil)
                .frame(width: 300, height: 400)
                .cornerRadius(20)

            // Preview with static image
            if let image = UIImage(systemName: "photo.fill") {
                StaticImageBackground(image: image)
                    .frame(width: 300, height: 200)
                    .cornerRadius(20)
            }
        }
        .padding()
    }
}
#endif
