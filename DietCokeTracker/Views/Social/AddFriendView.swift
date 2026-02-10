import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: AddMethod = .code

    enum AddMethod: String, CaseIterable {
        case code = "Code"
        case search = "Search"

        var icon: String {
            switch self {
            case .code: return "number"
            case .search: return "magnifyingglass"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Method Picker
                Picker("Method", selection: $selectedMethod) {
                    ForEach(AddMethod.allCases, id: \.self) { method in
                        Label(method.rawValue, systemImage: method.icon)
                            .tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedMethod {
                case .code:
                    ShareCodeView()
                case .search:
                    UsernameSearchView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.dietCokeRed)
                }
            }
        }
    }
}

#Preview {
    AddFriendView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
        .environmentObject(FriendConnectionService(cloudKitManager: CloudKitManager()))
}
