import SwiftUI
import UIKit

struct AddDrinkView: View {
    @EnvironmentObject var store: DrinkStore
    @EnvironmentObject var badgeStore: BadgeStore
    @EnvironmentObject var stateCanStore: StateCanStore
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var activityService: ActivityFeedService
    @Environment(\.dismiss) private var dismiss
    /// Overrides the last-logged prefill, e.g. the usual picked in onboarding.
    var initialType: DrinkType? = nil
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

    @State private var didApplyLastDrinkDefaults = false
    @State private var showingMoreDetails = false
    /// Where the user last posted a photo. Global is the starting default;
    /// picking Friends or Only Me once makes that their default.
    @AppStorage("lastPhotoVisibility") private var lastPhotoVisibility: PostVisibility = .public

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
                    // Photo leads: it's what makes a log worth posting.
                    PhotoSection(
                        capturedPhoto: $capturedPhoto,
                        showingCamera: $showingCamera,
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

                    DrinkTypesGrid(
                        selectedType: $selectedType,
                        selectedCategory: $selectedCategory
                    )

                    RatingSection(selectedRating: $selectedRating)

                    moreDetailsToggle

                    if showingMoreDetails {
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
                    }

                    // Sits right above the pinned button so where the post
                    // goes is the last thing decided.
                    VisibilityPicker(visibility: $visibility, hasPhoto: capturedPhoto != nil)
                }
                .padding()
            }
            .background(backgroundColor.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                // Pinned so a quick log never requires scrolling past the
                // optional fields.
                addButton
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .background(backgroundColor.ignoresSafeArea())
            }
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
                applyLastDrinkDefaults()

                let prefs = activityService.sharingPreferences
                if !prefs.shareDrinkLogs {
                    visibility = .onlyMe
                } else if prefs.sharePhotosGlobally && capturedPhoto != nil {
                    visibility = .public
                } else {
                    visibility = .friends
                }
            }
            .onChange(of: capturedPhoto) { oldPhoto, newPhoto in
                let prefs = activityService.sharingPreferences
                if newPhoto == nil && visibility == .public {
                    visibility = .friends
                } else if oldPhoto == nil, newPhoto != nil, prefs.shareDrinkLogs {
                    // Fresh photo: use their photo default. Global stays
                    // visibly labeled in the picker, so this is never silent.
                    if lastPhotoVisibility == .public && !prefs.sharePhotosGlobally {
                        visibility = .friends
                    } else {
                        visibility = lastPhotoVisibility
                    }
                }
            }
            .alert("Too Fast!", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationAlertMessage)
            }
        }
    }

    private var isPostingGlobally: Bool {
        visibility == .public && capturedPhoto != nil
    }

    private var hasMoreDetails: Bool {
        selectedSpecialEdition != nil || useCustomOunces || !note.isEmpty
    }

    private var moreDetailsToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingMoreDetails.toggle()
            }
        } label: {
            HStack {
                Text("More details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
                Text("Special edition, size, note")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
                Spacer()
                if hasMoreDetails && !showingMoreDetails {
                    Circle()
                        .fill(effectiveBrand.color)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dietCokeDarkSilver)
                    .rotationEffect(.degrees(showingMoreDetails ? 180 : 0))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(showingMoreDetails ? "Expanded" : "Collapsed")
    }

    private var addButton: some View {
        Button {
            addDrink()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text(isPostingGlobally ? "Post to Global" : "Add \(effectiveBrand.shortName)")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassSurface(
                in: RoundedRectangle(cornerRadius: 14),
                tint: canAddDrink ? effectiveBrand.color : nil,
                interactive: canAddDrink
            ) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        canAddDrink
                            ? effectiveBrand.buttonGradient
                            : LinearGradient(
                                colors: [Color.dietCokeSilver, Color.dietCokeSilver],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: canAddDrink ? effectiveBrand.color.opacity(0.3) : Color.clear,
                        radius: 8,
                        y: 4
                    )
            }
        }
        .disabled(!canAddDrink)
    }

    /// Most people log the same drink every time, so start from their last one
    /// (or the usual they picked in onboarding).
    private func applyLastDrinkDefaults() {
        guard !didApplyLastDrinkDefaults else { return }
        didApplyLastDrinkDefaults = true
        if let initialType {
            selectedType = initialType
            selectedCategory = initialType.category
            return
        }
        guard let last = store.mostRecentEntry else { return }
        selectedType = last.type
        selectedCategory = last.type.category
        if last.brand != preferences.defaultBrand {
            selectedBrand = last.brand
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

        if capturedPhoto != nil && activityService.sharingPreferences.shareDrinkLogs {
            lastPhotoVisibility = visibility
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
