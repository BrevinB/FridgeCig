import SwiftUI
import UIKit

/// Hero of the add-drink form. Before a photo it's the fizzy drink preview
/// with a "Snap your drink" button; after, the photo takes over the card with
/// the drink details on top.
struct PhotoSection: View {
    @Binding var capturedPhoto: UIImage?
    @Binding var showingCamera: Bool
    let type: DrinkType
    var brand: BeverageBrand = .dietCoke
    var specialEdition: SpecialEdition? = nil
    var customOunces: Double? = nil
    var rating: DrinkRating? = nil

    @StateObject private var verificationService = ImageVerificationService()
    @State private var pendingPhoto: UIImage?
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""

    var body: some View {
        VStack(spacing: 8) {
            if let photo = capturedPhoto {
                photoCard(photo)
            } else {
                SelectedDrinkPreview(
                    type: type,
                    brand: brand,
                    specialEdition: specialEdition,
                    customOunces: customOunces,
                    rating: rating,
                    onTakePhoto: openCamera,
                    isCameraAvailable: CameraView.isAvailable
                )

                Text("Optional. Photos can be shared on the Global feed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $pendingPhoto)
        }
        .onChange(of: pendingPhoto) { _, newPhoto in
            guard let photo = newPhoto else { return }
            verifyPhoto(photo)
        }
        .alert("Not a DC?", isPresented: $showingVerificationAlert) {
            Button("Use Anyway", role: .destructive) {
                if let photo = pendingPhoto {
                    capturedPhoto = photo
                }
                pendingPhoto = nil
            }
            Button("Retake", role: .cancel) {
                pendingPhoto = nil
                showingCamera = true
            }
        } message: {
            Text(verificationMessage)
        }
        .overlay {
            if verificationService.isVerifying {
                ZStack {
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Verifying photo...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func photoCard(_ photo: UIImage) -> some View {
        Image(uiImage: photo)
            .resizable()
            .scaledToFill()
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottom) {
                // Scrim keeps the drink details legible on any photo.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                    HStack(spacing: 6) {
                        BrandIconView(brand: brand, size: DrinkIconSize.xs)
                        Text(brand.rawValue)
                        if let rating {
                            Text("·")
                            Image(systemName: rating.icon)
                            Text(rating.displayName)
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(16)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    photoButton("Retake", systemImage: "camera.fill", action: openCamera)
                        .disabled(!CameraView.isAvailable)
                    photoButton("Remove", systemImage: "xmark") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            capturedPhoto = nil
                        }
                    }
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func photoButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title == "Retake" ? "Retake photo" : "Remove photo")
    }

    private func openCamera() {
        if CameraView.isAvailable {
            showingCamera = true
        }
    }

    private func verifyPhoto(_ photo: UIImage) {
        guard ImageVerificationService.isAvailable else {
            capturedPhoto = photo
            pendingPhoto = nil
            return
        }

        Task {
            let result = await verificationService.verifyImage(photo)

            if result.isValid {
                capturedPhoto = photo
                pendingPhoto = nil
            } else {
                verificationMessage = result.message
                showingVerificationAlert = true
            }
        }
    }
}

#if DEBUG
private struct PhotoSectionPreviewWrapper: View {
    @State private var photo: UIImage?
    @State private var showingCamera = false
    var body: some View {
        PhotoSection(capturedPhoto: $photo, showingCamera: $showingCamera, type: .regularCan)
            .padding()
    }
}

#Preview { PhotoSectionPreviewWrapper().withPreviewEnvironment() }
#endif
