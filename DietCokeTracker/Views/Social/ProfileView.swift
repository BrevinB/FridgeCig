import SwiftUI

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

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 80, height: 80)

                Text(identity.displayName.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.dietCokeRed)
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
                    .foregroundColor(.dietCokeDarkSilver)
            }

            // Member since
            Text("Member since \(identity.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Friend Code Section

struct FriendCodeSection: View {
    let friendCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundColor(.dietCokeRed)
                Text("Your Friend Code")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
            }

            HStack {
                Text(friendCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.dietCokeRed)

                Spacer()

                Button {
                    UIPasteboard.general.string = friendCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(.dietCokeRed)
                }

                ShareLink(item: "Add me on FridgeCig! My friend code: \(friendCode)") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.dietCokeRed)
                }
            }

            Text("Share this code with friends so they can find you")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
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
