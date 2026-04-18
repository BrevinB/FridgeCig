import SwiftUI

struct FeedView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case global = "Global"

        var id: String { rawValue }
    }

    @AppStorage("feedScope") private var scopeRaw: String = Scope.friends.rawValue
    @State private var showingPreferences = false
    @Environment(\.colorScheme) private var colorScheme

    private var scope: Binding<Scope> {
        Binding(
            get: { Scope(rawValue: scopeRaw) ?? .friends },
            set: { scopeRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Scope", selection: scope) {
                ForEach(Scope.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            switch scope.wrappedValue {
            case .friends:
                ActivityFeedView()
            case .global:
                GlobalFeedView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPreferences = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingPreferences) {
            SharingPreferencesView()
        }
    }
}

#Preview {
    let ckManager = CloudKitManager()
    return NavigationStack {
        FeedView()
            .environmentObject(ActivityFeedService(cloudKitManager: ckManager))
            .environmentObject(GlobalFeedService(cloudKitManager: ckManager))
            .environmentObject(IdentityService(cloudKitManager: ckManager))
            .environmentObject(FriendConnectionService(cloudKitManager: ckManager))
            .environmentObject(ThemeManager())
    }
}
