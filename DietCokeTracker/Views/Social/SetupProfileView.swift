import SwiftUI
import PhotosUI
import CloudKit

struct SetupProfileView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var displayName = ""
    @State private var isCreating = false
    @State private var showError = false
    @FocusState private var isNameFocused: Bool

    // Avatar state
    @State private var selectedEmoji: String?
    @State private var selectedImage: UIImage?
    @State private var showingAvatarOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingEmojiPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cameraImage: UIImage?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Avatar picker
            Button {
                showingAvatarOptions = true
            } label: {
                VStack(spacing: 8) {
                    ZStack(alignment: .bottomTrailing) {
                        avatarPreview

                        ZStack {
                            Circle()
                                .fill(Color.dietCokeRed)
                                .frame(width: 30, height: 30)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: 4)
                    }

                    Text("Add Profile Photo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeRed)
                }
            }
            .confirmationDialog("Profile Picture", isPresented: $showingAvatarOptions) {
                Button("Choose Photo") { showingPhotoPicker = true }
                Button("Take Photo") { showingCamera = true }
                Button("Pick Emoji") { showingEmojiPicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        selectedEmoji = nil
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(capturedImage: $cameraImage)
            }
            .onChange(of: cameraImage) { _, newImage in
                guard let newImage else { return }
                selectedImage = newImage
                selectedEmoji = nil
                cameraImage = nil
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerSheet { emoji in
                    selectedEmoji = emoji
                    selectedImage = nil
                }
            }

            // Title
            VStack(spacing: 8) {
                Text("Join the Leaderboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Compete with friends and see who drinks the most DC")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Name input
            VStack(alignment: .leading, spacing: 12) {
                Text("What should we call you?")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                TextField("Display Name", text: $displayName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.dietCokeCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if canContinue {
                            createProfile()
                        }
                    }

                Text("This is how you'll appear on the leaderboard")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button {
                createProfile()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Get Started")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dietCokePrimary)
            .disabled(!canContinue || isCreating)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(identityService.error?.localizedDescription ?? "Something went wrong")
        }
        .onAppear {
            isNameFocused = true
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let emoji = selectedEmoji {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Text(emoji)
                    .font(.system(size: 50))
            } else if let initial = displayName.trimmingCharacters(in: .whitespacesAndNewlines).first {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Text(String(initial).uppercased())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.dietCokeRed)
            } else {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.dietCokeRed)
            }
        }
    }

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createProfile() {
        guard canContinue else { return }

        isCreating = true
        Task {
            do {
                let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                try await identityService.createIdentity(displayName: name)

                // Upload avatar after profile is created
                if let image = selectedImage {
                    await uploadProfilePhoto(image)
                } else if let emoji = selectedEmoji {
                    await setProfileEmoji(emoji)
                }
            } catch {
                showError = true
            }
            isCreating = false
        }
    }

    private func uploadProfilePhoto(_ image: UIImage) async {
        guard let compressed = image.jpegData(compressionQuality: 0.7) else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        do {
            try compressed.write(to: tempURL)
            let asset = CKAsset(fileURL: tempURL)
            let record = CKRecord(recordType: "ProfilePhoto")
            record["photo"] = asset
            record["userID"] = identityService.currentIdentity?.userIDString

            let saved = try await cloudKitManager.saveToPublicAndReturn(record)
            try? FileManager.default.removeItem(at: tempURL)

            let photoID = saved.recordID.recordName
            ProfilePhotoCache.shared.setPhoto(image, for: photoID)

            if var profile = identityService.currentProfile {
                profile.profilePhotoID = photoID
                identityService.currentProfile = profile
                try await identityService.saveProfile()
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private func setProfileEmoji(_ emoji: String) async {
        if var profile = identityService.currentProfile {
            profile.profileEmoji = emoji
            identityService.currentProfile = profile
            try? await identityService.saveProfile()
        }
    }
}

#Preview {
    SetupProfileView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(CloudKitManager())
}
