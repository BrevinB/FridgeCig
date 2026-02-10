import SwiftUI

struct SharingPreferencesView: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @Environment(\.dismiss) private var dismiss

    @State private var shareBadges: Bool = true
    @State private var shareStreaks: Bool = true
    @State private var shareDrinks: Bool = true
    @State private var showPhotos: Bool = true

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

                        Text("Activities are only visible to your friends. You can change these settings at any time.")
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
        }
    }

    private func loadCurrentPreferences() {
        let prefs = activityService.sharingPreferences
        shareBadges = prefs.shareBadges
        shareStreaks = prefs.shareStreakMilestones
        shareDrinks = prefs.shareDrinkLogs
        showPhotos = prefs.showPhotosInFeed
    }

    private func savePreferences() {
        let newPrefs = UserSharingPreferences(
            shareBadges: shareBadges,
            shareStreakMilestones: shareStreaks,
            shareDrinkLogs: shareDrinks,
            showPhotosInFeed: showPhotos
        )
        activityService.updatePreferences(newPrefs)
    }
}

#Preview {
    SharingPreferencesView()
        .environmentObject(ActivityFeedService(cloudKitManager: CloudKitManager()))
}
