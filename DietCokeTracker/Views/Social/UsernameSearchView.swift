import SwiftUI

struct UsernameSearchView: View {
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @State private var searchText = ""
    @State private var results: [UserProfile] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.dietCokeDarkSilver)

                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isSearchFocused)
                        .onSubmit {
                            search()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results = []
                            hasSearched = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                    }
                }
                .padding(12)
                .background(Color.dietCokeCardBackground)
                .cornerRadius(12)

                if isSearching {
                    ProgressView()
                } else {
                    Button("Search") {
                        search()
                    }
                    .foregroundColor(.dietCokeRed)
                    .disabled(searchText.count < 2)
                }
            }
            .padding()

            // Results
            if isSearching {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if hasSearched && results.isEmpty {
                Spacer()
                EmptySearchView()
                Spacer()
            } else if !results.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { user in
                            SearchResultRow(
                                user: user,
                                isCurrentUser: user.userIDString == identityService.currentIdentity?.userIDString,
                                isFriend: friendService.friendIDs.contains(user.userIDString),
                                onAdd: { await sendRequest(to: user) }
                            )
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                SearchPromptView()
                Spacer()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Friend Request Sent!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("They'll see your request in their Friends list.")
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func search() {
        guard searchText.count >= 2 else { return }

        isSearching = true
        hasSearched = true

        Task {
            do {
                results = try await friendService.searchByUsername(searchText.lowercased())
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isSearching = false
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
}

// MARK: - Search Prompt

private struct SearchPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.dietCokeSilver)

            Text("Search by Username")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text("Find friends by their username")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
    }
}

// MARK: - Empty Search

private struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 48))
                .foregroundColor(.dietCokeSilver)

            Text("No Results")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text("Try a different username")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let user: UserProfile
    let isCurrentUser: Bool
    let isFriend: Bool
    let onAdd: () async -> Void
    @State private var isAdding = false

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 48, height: 48)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.dietCokeRed)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeCharcoal)

                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }

                if let username = user.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            Spacer()

            // Action
            if isCurrentUser {
                // No action for self
            } else if isFriend {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Friends")
                }
                .font(.caption)
                .foregroundColor(.green)
            } else {
                Button {
                    isAdding = true
                    Task {
                        await onAdd()
                        isAdding = false
                    }
                } label: {
                    if isAdding {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundColor(.dietCokeRed)
                    }
                }
                .disabled(isAdding)
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    UsernameSearchView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
