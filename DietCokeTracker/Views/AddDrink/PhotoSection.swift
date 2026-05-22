import SwiftUI
import UIKit

struct PhotoSection: View {
    @Binding var capturedPhoto: UIImage?
    @Binding var showingCamera: Bool

    @StateObject private var verificationService = ImageVerificationService()
    @State private var pendingPhoto: UIImage?
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Photo")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                if capturedPhoto != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            capturedPhoto = nil
                        }
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            Text("Take a photo of your drink (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let photo = capturedPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Button {
                            if CameraView.isAvailable {
                                showingCamera = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .accessibilityHidden(true)
                                Text("Retake")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        }
                        .accessibilityLabel("Retake photo")
                        .padding(8),
                        alignment: .bottomTrailing
                    )
            } else {
                Button {
                    if CameraView.isAvailable {
                        showingCamera = true
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .accessibilityHidden(true)
                        Text(CameraView.isAvailable ? "Take Photo" : "Camera Unavailable")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CameraView.isAvailable ? .dietCokeRed : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!CameraView.isAvailable)
                .accessibilityLabel(CameraView.isAvailable ? "Take photo of your drink" : "Camera unavailable")
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
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
                        .cornerRadius(12)
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
        PhotoSection(capturedPhoto: $photo, showingCamera: $showingCamera)
            .padding()
    }
}

#Preview { PhotoSectionPreviewWrapper() }
#endif
