import SwiftUI

struct SharingPreferencesView: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var shareBadges: Bool = true
    @State private var shareStreaks: Bool = true
    @State private var shareDrinks: Bool = true
    @State private var showPhotos: Bool = true
    @State private var shareGlobally: Bool = false
    @State private var showingGlobalExplanation: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $shareBadges) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Badge Unlocks")
                                    .foregroundColor(.dietCokeCharcoal)
                                Text("Share when you earn new badges")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                        } icon: {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                        }
                    }

                    Toggle(isOn: $shareStreaks) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Streak Milestones")
                                    .foregroundColor(.dietCokeCharcoal)
                                Text("Share when you hit 7, 30, 100+ day streaks")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                        } icon: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Milestones")
                } footer: {
                    Text("Share your achievements and streak milestones with friends.")
                }

                Section {
                    Toggle(isOn: $shareDrinks) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Drink Logs")
                                    .foregroundColor(.dietCokeCharcoal)
                                Text("Share your drinks with friends")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                        } icon: {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundColor(.dietCokeRed)
                        }
                    }

                    if shareDrinks {
                        Toggle(isOn: $showPhotos) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share Photos")
                                        .foregroundColor(.dietCokeCharcoal)
                                    Text("Upload your drink photos for friends to see")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeDarkSilver)
                                }
                            } icon: {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Drink Sharing")
                } footer: {
                    if shareDrinks && showPhotos {
                        Text("Your drink photos will be uploaded and visible to friends.")
                    } else if shareDrinks {
                        Text("Your friends can see your drink logs but not photos.")
                    } else {
                        Text("Enable drink sharing to let friends see your activity.")
                    }
                }

                if shareDrinks && showPhotos {
                    Section {
                        Toggle(isOn: $shareGlobally) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share Photos Globally")
                                        .foregroundColor(.dietCokeCharcoal)
                                    Text("Your drink photos will appear in the Global feed for all users")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeDarkSilver)
                                }
                            } icon: {
                                Image(systemName: "globe")
                                    .foregroundColor(.green)
                            }
                        }
                        .onChange(of: shareGlobally) { _, newValue in
                            if newValue {
                                showingGlobalExplanation = true
                            }
                        }
                    } header: {
                        Text("Global Feed")
                    } footer: {
                        Text("Photos shared globally are screened for safety before appearing in the Global tab. You can turn this off at any time.")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.dietCokeRed)
                            Text("Privacy Note")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.dietCokeCharcoal)
                        }

                        Text("Activities are only visible to your friends unless you enable global sharing. You can change these settings at any time.")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Sharing Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentPreferences()
            }
            .alert("Share Photos Globally", isPresented: $showingGlobalExplanation) {
                Button("Enable") { }
                Button("Cancel", role: .cancel) {
                    shareGlobally = false
                }
            } message: {
                Text("Your drink photos will be visible to all users in the Global tab. Photos are automatically screened for safety before appearing. You can disable this at any time.")
            }
        }
    }

    private func loadCurrentPreferences() {
        let prefs = activityService.sharingPreferences
        shareBadges = prefs.shareBadges
        shareStreaks = prefs.shareStreakMilestones
        shareDrinks = prefs.shareDrinkLogs
        showPhotos = prefs.showPhotosInFeed
        shareGlobally = prefs.sharePhotosGlobally
    }

    private func savePreferences() {
        let newPrefs = UserSharingPreferences(
            shareBadges: shareBadges,
            shareStreakMilestones: shareStreaks,
            shareDrinkLogs: shareDrinks,
            showPhotosInFeed: showPhotos,
            sharePhotosGlobally: shareGlobally
        )
        activityService.updatePreferences(newPrefs)

        // Sync sharePhotosGlobally to CloudKit UserProfile
        if var profile = identityService.currentProfile {
            profile.sharePhotosGlobally = shareGlobally
            Task {
                if let record = try? await cloudKitManager.fetchUserProfile(byUserID: profile.userIDString) {
                    record["sharePhotosGlobally"] = shareGlobally ? 1 : 0
                    try? await cloudKitManager.saveToPublic(record)
                }
            }
        }
    }
}

#Preview {
    let ckManager = CloudKitManager()
    SharingPreferencesView()
        .environmentObject(ActivityFeedService(cloudKitManager: ckManager))
        .environmentObject(IdentityService(cloudKitManager: ckManager))
        .environmentObject(ckManager)
}
