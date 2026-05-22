import SwiftUI
import UIKit

struct AddDrinkView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var stateCanStore: StateCanStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var activityService: ActivityFeedService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedType: DrinkType = .regularCan
    @State private var selectedBrand: BeverageBrand?
    @State private var note: String = ""
    @State private var selectedCategory: DrinkCategory? = .cans
    @State private var selectedSpecialEdition: SpecialEdition? = nil
    @State private var selectedStateCanCode: String? = nil
    @State private var showSpecialEditions = false
    @State private var useCustomOunces = false
    @State private var customOuncesText: String = ""
    @State private var selectedRating: DrinkRating? = nil
    @State private var capturedPhoto: UIImage? = nil
    @State private var showingCamera = false
    @State private var visibility: PostVisibility = .friends

    @State private var showingValidationAlert = false
    @State private var validationAlertMessage = ""

    private var effectiveBrand: BeverageBrand {
        selectedBrand ?? preferences.defaultBrand
    }

    private var ouncesValidation: EntryValidator.ValidationResult {
        guard useCustomOunces, let oz = Double(customOuncesText) else {
            return .valid()
        }
        return EntryValidator.validateOunces(oz)
    }

    private var canAddDrink: Bool {
        if useCustomOunces {
            guard let oz = Double(customOuncesText), oz > 0 else { return false }
            if !ouncesValidation.isValid { return false }
        }
        return true
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SelectedDrinkPreview(
                        type: selectedType,
                        brand: effectiveBrand,
                        specialEdition: selectedSpecialEdition,
                        customOunces: useCustomOunces ? Double(customOuncesText) : nil,
                        rating: selectedRating
                    )

                    BrandSelectorView(
                        selectedBrand: $selectedBrand,
                        defaultBrand: preferences.defaultBrand
                    )

                    PhotoSection(
                        capturedPhoto: $capturedPhoto,
                        showingCamera: $showingCamera
                    )

                    VisibilityPicker(visibility: $visibility, hasPhoto: capturedPhoto != nil)

                    RatingSection(selectedRating: $selectedRating)

                    DrinkTypesGrid(
                        selectedType: $selectedType,
                        selectedCategory: $selectedCategory
                    )

                    SpecialEditionSection(
                        showSpecialEditions: $showSpecialEditions,
                        selectedSpecialEdition: $selectedSpecialEdition
                    )

                    // State can picker — only for America 250 mini cans (the
                    // 52-can series is mini-can-only).
                    if selectedSpecialEdition == .america250 && selectedType == .miniCan {
                        StateCanPickerSection(selectedCode: $selectedStateCanCode)
                    }

                    CustomOuncesSection(
                        useCustomOunces: $useCustomOunces,
                        customOuncesText: $customOuncesText,
                        defaultOunces: selectedType.ounces
                    )

                    NoteInputView(note: $note)

                    Button {
                        addDrink()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add \(effectiveBrand.shortName)")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canAddDrink
                                ? effectiveBrand.buttonGradient
                                : LinearGradient(
                                    colors: [Color.dietCokeSilver, Color.dietCokeSilver],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(
                            color: canAddDrink ? effectiveBrand.color.opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                    }
                    .disabled(!canAddDrink)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Add \(effectiveBrand.shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(effectiveBrand.color)
                }
            }
            .onAppear {
                let prefs = activityService.sharingPreferences
                if !prefs.shareDrinkLogs {
                    visibility = .onlyMe
                } else if prefs.sharePhotosGlobally && capturedPhoto != nil {
                    visibility = .public
                } else {
                    visibility = .friends
                }
            }
            .onChange(of: capturedPhoto) { _, newPhoto in
                let prefs = activityService.sharingPreferences
                if newPhoto == nil && visibility == .public {
                    visibility = .friends
                } else if newPhoto != nil,
                          prefs.shareDrinkLogs,
                          prefs.sharePhotosGlobally,
                          visibility != .public {
                    visibility = .public
                }
            }
            .alert("Too Fast!", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationAlertMessage)
            }
        }
    }

    private func addDrink() {
        let customOz: Double? = useCustomOunces ? Double(customOuncesText) : nil

        let validation = store.validateNewEntry(
            type: selectedType,
            customOunces: customOz
        )

        if !validation.isValid {
            validationAlertMessage = validation.errorMessage ?? "Please wait before adding another drink."
            showingValidationAlert = true
            return
        }

        // Only attach a state code if this is the qualifying America-250 mini-can.
        let entryStateCode: String? = (selectedSpecialEdition == .america250 && selectedType == .miniCan)
            ? selectedStateCanCode
            : nil

        store.addDrink(
            type: selectedType,
            brand: effectiveBrand,
            note: note.isEmpty ? nil : note,
            specialEdition: selectedSpecialEdition,
            customOunces: customOz,
            rating: selectedRating,
            photo: capturedPhoto,
            stateCode: entryStateCode,
            visibility: visibility
        )
        store.checkBadges(with: badgeStore)

        // The 52-state America 250 series is mini-can-only, so only auto-collect
        // when the logged drink is a mini can with that special edition. A photo
        // attached to the entry upgrades the collection to "verified" and is
        // stored as an independent copy so it survives drink-entry deletion.
        if selectedSpecialEdition == .america250,
           selectedType == .miniCan,
           let code = selectedStateCanCode {
            var stateCanFilename: String? = nil
            if let photo = capturedPhoto {
                let filename = PhotoStorage.generateFilename()
                if PhotoStorage.savePhoto(photo, filename: filename) {
                    stateCanFilename = filename
                }
            }
            stateCanStore.collect(code, photoFilename: stateCanFilename)
        }

        dismiss()
    }
}

#if DEBUG
#Preview {
    AddDrinkView().withPreviewEnvironment()
}
#endif
