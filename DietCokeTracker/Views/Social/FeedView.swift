import SwiftUI

struct FeedView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case global = "Global"

        var id: String { rawValue }
    }

    @AppStorage("feedScope") private var scopeRaw: String = Scope.friends.rawValue
    // Tracks whether the user ever picked a scope themselves; until they do,
    // friendless users get Global so their first impression isn't an empty feed.
    @AppStorage("feedScopeUserSet") private var scopeUserSet = false
    @State private var showingPreferences = false
    @EnvironmentObject var friendService: FriendConnectionService
    @Environment(\.colorScheme) private var colorScheme

    private var scope: Binding<Scope> {
        Binding(
            get: { Scope(rawValue: scopeRaw) ?? .friends },
            set: {
                // Set inside the binding (not .onChange) so only real user
                // interaction marks the choice, never state hydration.
                scopeUserSet = true
                scopeRaw = $0.rawValue
            }
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
        .onAppear {
            if !scopeUserSet, friendService.friends.isEmpty, scope.wrappedValue == .friends {
                scopeRaw = Scope.global.rawValue
            }
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
