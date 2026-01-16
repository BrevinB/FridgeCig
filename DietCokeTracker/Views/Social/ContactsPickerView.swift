import SwiftUI
import Contacts

struct ContactsPickerView: View {
    @EnvironmentObject var contactsService: ContactsService
    @EnvironmentObject var friendService: FriendConnectionService
    @EnvironmentObject var identityService: IdentityService
    @State private var searchText = ""
    @State private var selectedContact: ContactsService.ContactInfo?
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            switch contactsService.authorizationStatus {
            case .notDetermined:
                RequestAccessView()
            case .denied, .restricted:
                AccessDeniedView()
            case .authorized:
                ContactsListView(
                    searchText: $searchText,
                    selectedContact: $selectedContact
                )
            @unknown default:
                RequestAccessView()
            }
        }
        .sheet(item: $selectedContact) { contact in
            ContactSearchSheet(
                contact: contact,
                searchResults: $searchResults,
                isSearching: $isSearching,
                hasSearched: $hasSearched,
                onDismiss: { selectedContact = nil },
                onSearch: { await searchForContact(contact) },
                onAddFriend: { profile in await addFriend(profile) }
            )
        }
        .alert("Friend Request Sent!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("They'll see your request in their Friends list.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await contactsService.loadContacts()
        }
    }

    private func searchForContact(_ contact: ContactsService.ContactInfo) async {
        isSearching = true
        hasSearched = false

        do {
            // Search by first name, last name, and full name as potential usernames
            var allResults: [UserProfile] = []
            let searchTerms = [
                contact.givenName.lowercased(),
                contact.familyName.lowercased(),
                contact.fullName.lowercased().replacingOccurrences(of: " ", with: ""),
                contact.fullName.lowercased().replacingOccurrences(of: " ", with: "_")
            ].filter { !$0.isEmpty && $0.count >= 2 }

            for term in searchTerms {
                let results = try await friendService.searchByUsername(term)
                for result in results where !allResults.contains(where: { $0.id == result.id }) {
                    allResults.append(result)
                }
            }

            searchResults = allResults
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSearching = false
        hasSearched = true
    }

    private func addFriend(_ profile: UserProfile) async {
        guard let currentUserID = identityService.currentIdentity?.userIDString else { return }

        do {
            try await friendService.sendFriendRequest(from: currentUserID, to: profile)
            showingSuccess = true
            selectedContact = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Request Access View

private struct RequestAccessView: View {
    @EnvironmentObject var contactsService: ContactsService

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.dietCokeSilver)

            Text("Access Your Contacts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            Text("Find friends who are already using FridgeCig by searching your contacts.")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Allow Access") {
                Task {
                    _ = await contactsService.requestAccess()
                    await contactsService.loadContacts()
                }
            }
            .buttonStyle(.dietCokePrimary)
            .padding(.horizontal, 48)

            Spacer()
        }
    }
}

// MARK: - Access Denied View

private struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 64))
                .foregroundColor(.dietCokeSilver)

            Text("Contacts Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.dietCokeCharcoal)

            Text("To find friends from your contacts, please enable access in Settings.")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.dietCokePrimary)
            .padding(.horizontal, 48)

            Spacer()
        }
    }
}

// MARK: - Contacts List View

private struct ContactsListView: View {
    @EnvironmentObject var contactsService: ContactsService
    @Binding var searchText: String
    @Binding var selectedContact: ContactsService.ContactInfo?

    var filteredContacts: [ContactsService.ContactInfo] {
        contactsService.filteredContacts(query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.dietCokeDarkSilver)

                TextField("Search contacts", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                }
            }
            .padding(12)
            .background(Color.dietCokeCardBackground)
            .cornerRadius(12)
            .padding()

            // Contacts List
            if contactsService.isLoading {
                Spacer()
                ProgressView("Loading contacts...")
                Spacer()
            } else if filteredContacts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.dietCokeSilver)
                    Text("No contacts found")
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredContacts) { contact in
                            ContactRow(contact: contact) {
                                selectedContact = contact
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}

// MARK: - Contact Row

private struct ContactRow: View {
    let contact: ContactsService.ContactInfo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.dietCokeRed.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text(contact.initials)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.dietCokeRed)
                }

                Text(contact.fullName)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeCharcoal)

                Spacer()

                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .padding(12)
            .background(Color.dietCokeCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Search Sheet

private struct ContactSearchSheet: View {
    let contact: ContactsService.ContactInfo
    @Binding var searchResults: [UserProfile]
    @Binding var isSearching: Bool
    @Binding var hasSearched: Bool
    let onDismiss: () -> Void
    let onSearch: () async -> Void
    let onAddFriend: (UserProfile) async -> Void

    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Contact Info
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.dietCokeRed.opacity(0.1))
                            .frame(width: 72, height: 72)

                        Text(contact.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.dietCokeRed)
                    }

                    Text(contact.fullName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)
                }
                .padding(.top, 20)

                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if hasSearched {
                    if searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.dietCokeSilver)

                            Text("No matching users found")
                                .font(.subheadline)
                                .foregroundColor(.dietCokeDarkSilver)

                            Text("They might not have set up a profile yet, or use a different username.")
                                .font(.caption)
                                .foregroundColor(.dietCokeSilver)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        Text("Possible Matches")
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { profile in
                                    SearchResultRow(
                                        profile: profile,
                                        onAdd: { await onAddFriend(profile) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Spacer()

                    VStack(spacing: 16) {
                        Text("Search for this contact on FridgeCig?")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)

                        Button("Search") {
                            Task { await onSearch() }
                        }
                        .buttonStyle(.dietCokePrimary)
                        .padding(.horizontal, 48)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Find Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }
}

// MARK: - Search Result Row (for sheet)

private struct SearchResultRow: View {
    let profile: UserProfile
    let onAdd: () async -> Void
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var friendService: FriendConnectionService
    @State private var isAdding = false

    private var isCurrentUser: Bool {
        profile.userIDString == identityService.currentIdentity?.userIDString
    }

    private var isFriend: Bool {
        friendService.friendIDs.contains(profile.userIDString)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 48, height: 48)

                Text(profile.displayName.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.dietCokeRed)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)

                if let username = profile.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }

            Spacer()

            if isCurrentUser {
                Text("You")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
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
    ContactsPickerView()
        .environmentObject(ContactsService())
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
