import SwiftUI
import AVFoundation
import UIKit

// MARK: - CameraSessionManager

final class CameraSessionManager: NSObject, ObservableObject {
    // MARK: Published State
    @Published var isSessionRunning = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var capturedImage: UIImage?
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var error: String?

    // MARK: AVCapture
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var currentDeviceInput: AVCaptureDeviceInput?

    // MARK: Permissions

    func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async { self.permissionStatus = status }

        switch status {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionStatus = granted ? .authorized : .denied
                }
                if granted { self.configureSession() }
            }
        default:
            break
        }
    }

    // MARK: Session Configuration

    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // Remove existing input
            if let existing = self.currentDeviceInput {
                self.session.removeInput(existing)
            }

            // Add camera input
            guard let device = self.bestDevice(for: self.cameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.error = "Unable to access camera" }
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentDeviceInput = input
            }

            // Add photo output (only once)
            if self.session.outputs.isEmpty, self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    private func bestDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
            return device
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    // MARK: Start / Stop

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = self.session.isRunning }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }

    // MARK: Capture

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            if let device = self.currentDeviceInput?.device,
               device.hasFlash {
                settings.flashMode = self.flashMode
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: Flip Camera

    func flipCamera() {
        let newPosition: AVCaptureDevice.Position = (cameraPosition == .back) ? .front : .back
        cameraPosition = newPosition
        configureSession()
    }

    // MARK: Toggle Flash

    func toggleFlash() {
        switch flashMode {
        case .off:  flashMode = .on
        case .on:   flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            DispatchQueue.main.async { self.error = error.localizedDescription }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else {
            DispatchQueue.main.async { self.error = "Failed to process photo" }
            return
        }

        // Mirror front-camera images so they look natural
        if cameraPosition == .front,
           let cgImage = image.cgImage {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        }

        DispatchQueue.main.async { self.capturedImage = image }
    }
}

// MARK: - CameraPreviewView

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - CameraView

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var cameraManager = CameraSessionManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.permissionStatus == .authorized {
                cameraContent
            } else if cameraManager.permissionStatus == .denied || cameraManager.permissionStatus == .restricted {
                permissionDeniedView
            }
        }
        .statusBarHidden(true)
        .onAppear {
            cameraManager.checkPermissions()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) {
            guard let newImage = cameraManager.capturedImage else { return }
            capturedImage = newImage
            dismiss()
        }
    }

    // MARK: Camera Content

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }

            // Brief error overlay
            if let error = cameraManager.error {
                errorOverlay(error)
            }
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Spacer()

            // Flash toggle — hidden when front camera
            if cameraManager.cameraPosition == .back {
                Button {
                    cameraManager.toggleFlash()
                } label: {
                    Image(systemName: flashIconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(cameraManager.flashMode == .off ? .white : themeManager.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }

            // Camera flip
            Button {
                cameraManager.flipCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [.black.opacity(0.6), .clear],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            captureButton
                .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: Capture Button

    private var captureButton: some View {
        Button {
            HapticManager.mediumImpact()
            cameraManager.capturePhoto()
        } label: {
            ZStack {
                // Outer white ring
                Circle()
                    .fill(Color.white)
                    .frame(width: 75, height: 75)

                // Dark gap
                Circle()
                    .fill(Color.black)
                    .frame(width: 67, height: 67)

                // Inner white fill
                Circle()
                    .fill(Color.white)
                    .frame(width: 61, height: 61)
            }
        }
    }

    // MARK: Flash Icon

    private var flashIconName: String {
        switch cameraManager.flashMode {
        case .off:  return "bolt.slash.fill"
        case .on:   return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }

    // MARK: Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.primaryGradient)

            Text("Camera Access Required")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Please allow camera access in Settings to take photos.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(themeManager.buttonGradient)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 4)
        }
    }

    // MARK: Error Overlay

    private func errorOverlay(_ message: String) -> some View {
        Text(message)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.8))
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    cameraManager.error = nil
                }
            }
    }
}

// MARK: - Camera Availability Check

extension CameraView {
    static var isAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}
