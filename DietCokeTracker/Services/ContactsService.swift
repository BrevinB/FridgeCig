import Foundation
import Contacts
import os

@MainActor
class ContactsService: ObservableObject {
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var contacts: [ContactInfo] = []

    private let contactStore = CNContactStore()

    struct ContactInfo: Identifiable, Hashable {
        let id = UUID()
        let givenName: String
        let familyName: String

        var fullName: String {
            [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
        }

        var initials: String {
            let first = givenName.first.map { String($0) } ?? ""
            let last = familyName.first.map { String($0) } ?? ""
            return (first + last).uppercased()
        }
    }

    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return granted
        } catch {
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return false
        }
    }

    func loadContacts() async {
        guard authorizationStatus == .authorized else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var loadedContacts: [ContactInfo] = []

        do {
            try await Task.detached { [contactStore] in
                try contactStore.enumerateContacts(with: request) { contact, _ in
                    let info = ContactInfo(
                        givenName: contact.givenName,
                        familyName: contact.familyName
                    )
                    if !info.fullName.isEmpty {
                        loadedContacts.append(info)
                    }
                }
            }.value

            self.contacts = loadedContacts
        } catch {
            AppLogger.general.error("Failed to load contacts: \(error.localizedDescription)")
        }
    }

    func filteredContacts(query: String) -> [ContactInfo] {
        guard !query.isEmpty else { return contacts }
        let lowercased = query.lowercased()
        return contacts.filter { contact in
            contact.fullName.lowercased().contains(lowercased)
        }
    }
}
