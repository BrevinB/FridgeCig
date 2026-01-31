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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background with metallic gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.dietCokeDarkMetallicGradient : Color.dietCokeMetallicGradient)

            // Ambient bubbles
            AmbientBubblesBackground(bubbleCount: 6)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 16) {
                // Avatar with gradient ring
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.dietCokeRed.opacity(0.3), radius: 8, y: 2)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 88, height: 88)

                    Text(identity.displayName.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.dietCokeRed, Color.dietCokeDeepRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
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
