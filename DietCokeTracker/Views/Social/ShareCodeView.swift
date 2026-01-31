import SwiftUI

struct ShareCodeView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService

    // Optional initial code from deep link
    var initialCode: String?

    @State private var enteredCode = ""
    @State private var foundUser: UserProfile?
    @State private var searchState: SearchState = .idle
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var didAutoSearch = false
    @FocusState private var isCodeFocused: Bool

    init(initialCode: String? = nil) {
        self.initialCode = initialCode
    }

    enum SearchState {
        case idle
        case searching
        case found
        case notFound
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Your Code Section
                if let identity = identityService.currentIdentity {
                    YourCodeCard(friendCode: identity.friendCode)
                }

                // Enter Code Section
                EnterCodeCard(
                    enteredCode: $enteredCode,
                    searchState: searchState,
                    isCodeFocused: $isCodeFocused,
                    onLookup: lookupCode
                )

                // Found User Card
                if let user = foundUser, searchState == .found {
                    FoundUserCard(
                        user: user,
                        onAdd: { await sendRequest(to: user) }
                    )
                }

                // Not Found Message
                if searchState == .notFound {
                    NotFoundCard()
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Friend Request Sent!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {
                resetSearch()
            }
        } message: {
            Text("They'll see your request in their Friends list.")
        }
        .task {
            // Auto-fill and auto-search if we have an initial code from deep link
            if let code = initialCode, !didAutoSearch {
                enteredCode = code.uppercased()
                didAutoSearch = true
                // Auto-lookup after a brief delay for UI to update
                try? await Task.sleep(for: .milliseconds(300))
                lookupCode()
            }
        }
    }

    private func lookupCode() {
        guard enteredCode.count == 8 else { return }

        searchState = .searching
        foundUser = nil

        Task {
            do {
                if let user = try await friendService.lookupUserByFriendCode(enteredCode) {
                    foundUser = user
                    searchState = .found
                } else {
                    searchState = .notFound
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                searchState = .idle
            }
        }
    }

    private func sendRequest(to user: UserProfile) async {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return }

        do {
            try await friendService.sendFriendRequest(from: currentUserID, to: user)
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func resetSearch() {
        enteredCode = ""
        foundUser = nil
        searchState = .idle
    }
}

// MARK: - Your Code Card

private struct YourCodeCard: View {
    let friendCode: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundColor(.dietCokeRed)
                Text("Your Friend Code")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
                Spacer()
            }

            Text(friendCode)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.dietCokeRed)
                .kerning(4)

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = friendCode
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.dietCokeRed.opacity(0.1))
                    .cornerRadius(8)
                }

                ShareLink(
                    item: DeepLinkHandler.friendCodeURL(code: friendCode),
                    message: Text("Add me on FridgeCig!")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.dietCokeRed.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Text("Share this code with friends")
                .font(.caption)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding(20)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Enter Code Card

private struct EnterCodeCard: View {
    @Binding var enteredCode: String
    let searchState: ShareCodeView.SearchState
    var isCodeFocused: FocusState<Bool>.Binding
    let onLookup: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.dietCokeRed)
                Text("Enter Friend's Code")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)
                Spacer()
            }

            TextField("XXXXXXXX", text: $enteredCode)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                )
                .focused(isCodeFocused)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .onChange(of: enteredCode) { _, newValue in
                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    enteredCode = String(filtered.prefix(8))
                }
                .onSubmit {
                    onLookup()
                }

            Button {
                onLookup()
            } label: {
                HStack {
                    if searchState == .searching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                        Text("Look Up")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dietCokePrimary)
            .disabled(enteredCode.count != 8 || searchState == .searching)
        }
        .padding(20)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Found User Card

private struct FoundUserCard: View {
    let user: UserProfile
    let onAdd: () async -> Void
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.dietCokeRed.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Text(user.displayName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dietCokeRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundColor(.dietCokeCharcoal)

                    if let username = user.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }

                Spacer()
            }

            Button {
                isAdding = true
                Task {
                    await onAdd()
                    isAdding = false
                }
            } label: {
                HStack {
                    if isAdding {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Send Friend Request")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dietCokePrimary)
            .disabled(isAdding)
        }
        .padding(20)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Not Found Card

private struct NotFoundCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.system(size: 32))
                .foregroundColor(.dietCokeDarkSilver)

            Text("No user found")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text("Check the code and try again")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    ShareCodeView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
