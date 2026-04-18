import SwiftUI
import PhotosUI
import CloudKit

struct ProfileView: View {
    @EnvironmentObject var identityService: IdentityService
    @State private var showingResetAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Card
                if let identity = identityService.currentIdentity {
                    ProfileCardView(identity: identity)
                }

                // Friend Code Section
                if let identity = identityService.currentIdentity {
                    FriendCodeSection(friendCode: identity.friendCode)
                }

                // Privacy Settings
                PrivacySettingsSection()

                // Account Actions
                AccountActionsSection(showingResetAlert: $showingResetAlert)
            }
            .padding()
        }
        .alert("Reset Profile?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await identityService.resetIdentity()
                }
            }
        } message: {
            Text("This will remove your profile from the leaderboard. You can create a new one anytime.")
        }
    }
}

// MARK: - Profile Card

struct ProfileCardView: View {
    let identity: UserIdentity
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showingAvatarOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingEmojiPicker = false
    @State private var cameraImage: UIImage?

    var body: some View {
        ZStack {
            // Background with metallic gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)

            // Ambient bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 16) {
                // Avatar with edit button
                Button {
                    showingAvatarOptions = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(
                            displayName: identity.displayName,
                            profilePhotoID: identityService.currentProfile?.profilePhotoID,
                            profileEmoji: identityService.currentProfile?.profileEmoji,
                            size: 82,
                            showGradientRing: true
                        )

                        ZStack {
                            Circle()
                                .fill(Color.dietCokeRed)
                                .frame(width: 26, height: 26)
                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(.white)
                            } else {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: 4, y: 4)
                    }
                }
                .disabled(isUploading)
                .confirmationDialog("Profile Picture", isPresented: $showingAvatarOptions) {
                    Button("Choose Photo") { showingPhotoPicker = true }
                    Button("Take Photo") { showingCamera = true }
                    Button("Pick Emoji") { showingEmojiPicker = true }
                    Button("Use Initial") { Task { await resetToInitial() } }
                    Button("Cancel", role: .cancel) {}
                }
                .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
                .onChange(of: selectedPhoto) { _, newItem in
                    guard let newItem else { return }
                    Task { await uploadProfilePhoto(item: newItem) }
                }
                .fullScreenCover(isPresented: $showingCamera) {
                    CameraView(capturedImage: $cameraImage)
                }
                .onChange(of: cameraImage) { _, newImage in
                    guard let newImage else { return }
                    Task { await uploadCameraPhoto(newImage) }
                    cameraImage = nil
                }
                .sheet(isPresented: $showingEmojiPicker) {
                    EmojiPickerSheet { emoji in
                        Task { await setEmoji(emoji) }
                    }
                }

                // Name
                Text(identity.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                // Username if set
                if let username = identity.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                // Member since badge
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Member since \(identity.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.dietCokeDarkSilver)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.7))
                )
            }
            .padding(24)
        }
        .frame(height: 240)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 10,
            y: 4
        )
    }

    private func uploadCameraPhoto(_ image: UIImage) async {
        isUploading = true
        defer { isUploading = false }

        guard let compressed = image.jpegData(compressionQuality: 0.7) else { return }
        await uploadImageData(compressed, originalImage: image)
    }

    private func setEmoji(_ emoji: String) async {
        guard var profile = identityService.currentProfile else { return }
        profile.profileEmoji = emoji
        profile.profilePhotoID = nil
        identityService.currentProfile = profile
        try? await identityService.saveProfile()
    }

    private func resetToInitial() async {
        guard var profile = identityService.currentProfile else { return }
        profile.profileEmoji = nil
        profile.profilePhotoID = nil
        identityService.currentProfile = profile
        try? await identityService.saveProfile()
    }

    private func uploadProfilePhoto(item: PhotosPickerItem) async {
        isUploading = true
        defer { isUploading = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let compressed = image.jpegData(compressionQuality: 0.7) else { return }

        await uploadImageData(compressed, originalImage: image)
    }

    private func uploadImageData(_ compressed: Data, originalImage: UIImage) async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        do {
            try compressed.write(to: tempURL)
            let asset = CKAsset(fileURL: tempURL)
            let record = CKRecord(recordType: "ProfilePhoto")
            record["photo"] = asset
            record["userID"] = identity.userIDString

            let saved = try await cloudKitManager.saveToPublicAndReturn(record)
            try? FileManager.default.removeItem(at: tempURL)

            let photoID = saved.recordID.recordName
            ProfilePhotoCache.shared.setPhoto(originalImage, for: photoID)

            if var profile = identityService.currentProfile {
                profile.profilePhotoID = photoID
                profile.profileEmoji = nil
                identityService.currentProfile = profile
                try await identityService.saveProfile()
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            AppLogger.identity.error("Failed to upload profile photo: \(error.localizedDescription)")
        }
    }
}

// MARK: - Friend Code Section

struct FriendCodeSection: View {
    let friendCode: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.dietCokeRed)
                }
                Text("Your Friend Code")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
            }

            HStack {
                Text(friendCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                Button {
                    UIPasteboard.general.string = friendCode
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.dietCokeRed)
                    }
                }

                ShareLink(item: "Add me on FridgeCig! My friend code: \(friendCode)") {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.dietCokeRed)
                    }
                }
            }

            Text("Share this code with friends so they can find you")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dietCokeSilver.opacity(0.15), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 8,
            y: 3
        )
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsSection: View {
    @EnvironmentObject var identityService: IdentityService
    @State private var isPublic: Bool = false
    @State private var username: String = ""
    @State private var isEditingUsername = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.dietCokeRed)
                Text("Privacy")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
            }

            // Global Leaderboard Toggle
            HStack {
                Toggle(isOn: $isPublic) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show on Global Leaderboard")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeCharcoal)
                        Text("Let everyone see your stats")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
                .tint(.dietCokeRed)
                .disabled(isSaving)

                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .onChange(of: isPublic) { oldValue, newValue in
                // Only save if this is a user-initiated change, not onAppear
                guard oldValue != newValue else { return }
                Task {
                    isSaving = true
                    do {
                        try await identityService.setPublicVisibility(newValue)
                    } catch {
                        // Revert toggle on failure
                        isPublic = oldValue
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    isSaving = false
                }
            }

            Divider()

            // Username
            VStack(alignment: .leading, spacing: 8) {
                Text("Username (optional)")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeCharcoal)

                HStack {
                    TextField("Choose a username", text: $username)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    if !username.isEmpty {
                        Button("Save") {
                            Task {
                                try? await identityService.updateUsername(username)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.dietCokeRed)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)

                Text("Others can search for you by username")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
        .onAppear {
            isPublic = identityService.currentProfile?.isPublic ?? false
            username = identityService.currentIdentity?.username ?? ""
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Account Actions

struct AccountActionsSection: View {
    @Binding var showingResetAlert: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button {
                showingResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Profile")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.red)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }

            Text("This removes your profile from the leaderboard")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
    }
}
