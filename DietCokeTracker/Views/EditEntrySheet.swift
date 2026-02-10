import SwiftUI
import UIKit

struct EditEntrySheet: View {
    @EnvironmentObject var store: DrinkStore
    @Environment(\.dismiss) private var dismiss

    let entry: DrinkEntry
    @State private var selectedDateTime: Date
    @State private var selectedRating: DrinkRating?
    @State private var showingFullScreenPhoto = false
    @State private var showCalendar = false
    @State private var showingShareSheet = false
    @EnvironmentObject private var purchaseService: PurchaseService

    init(entry: DrinkEntry) {
        self.entry = entry
        _selectedDateTime = State(initialValue: entry.timestamp)
        _selectedRating = State(initialValue: entry.rating)
    }

    private var entryPhoto: UIImage? {
        guard let filename = entry.photoFilename else { return nil }
        return PhotoStorage.loadPhoto(filename: filename)
    }

    private var accentColor: Color {
        if let edition = entry.specialEdition {
            return edition.toBadge().rarity.color
        }
        return .dietCokeRed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Entry info header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.1))
                                .frame(width: 56, height: 56)

                            DrinkIconView(drinkType: entry.type, specialEdition: entry.specialEdition, size: DrinkIconSize.lg)
                                .foregroundColor(accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(entry.type.displayName)
                                    .font(.headline)
                                    .foregroundColor(.dietCokeCharcoal)

                                if let edition = entry.specialEdition {
                                    Text(edition.rawValue)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(edition.toBadge().rarity.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(edition.toBadge().rarity.color.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            HStack(spacing: 4) {
                                Text("\(String(format: "%.0f", entry.ounces)) oz")
                                    .font(.subheadline)
                                    .foregroundColor(.dietCokeDarkSilver)

                                if entry.hasCustomOunces {
                                    Text("(custom)")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeRed)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .dietCokeCard()

                    // Photo section (if entry has photo)
                    if let photo = entryPhoto {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.dietCokeRed)
                                Text("Photo")
                                    .font(.headline)
                                    .foregroundColor(.dietCokeCharcoal)
                            }

                            Button {
                                showingFullScreenPhoto = true
                            } label: {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            Text("Tap to view full size")
                                        }
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .padding(8),
                                        alignment: .bottomTrailing
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .dietCokeCard()
                    }

                    // Share section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.dietCokeRed)
                            Text("Share")
                                .font(.headline)
                                .foregroundColor(.dietCokeCharcoal)
                        }

                        Button {
                            showingShareSheet = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.hasPhoto ? "Share with Photo" : "Share Entry")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.dietCokeCharcoal)
                                    Text("Create a beautiful share card for social media")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeDarkSilver)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .dietCokeCard()

                    // Date & Time picker
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCalendar.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.dietCokeRed)
                                Text("Date & Time")
                                    .font(.headline)
                                    .foregroundColor(.dietCokeCharcoal)

                                Spacer()

                                Text(selectedDateTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.dietCokeDarkSilver)

                                Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.dietCokeDarkSilver)
                            }
                        }
                        .buttonStyle(.plain)

                        if showCalendar {
                            DatePicker(
                                "",
                                selection: $selectedDateTime,
                                in: ...Date(),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(.dietCokeRed)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .dietCokeCard()

                    // Rating section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rating")
                                .font(.headline)
                                .foregroundColor(.dietCokeCharcoal)

                            Spacer()

                            if selectedRating != nil {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedRating = nil
                                    }
                                } label: {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(.dietCokeRed)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(DrinkRating.allCases) { rating in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedRating == rating {
                                            selectedRating = nil
                                        } else {
                                            selectedRating = rating
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: rating.icon)
                                            .font(.title3)
                                        Text(rating.displayName)
                                            .font(.system(size: 9))
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedRating == rating ? rating.color : rating.color.opacity(0.1))
                                    .foregroundColor(selectedRating == rating ? .white : rating.color)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let rating = selectedRating {
                            Text(rating.description)
                                .font(.caption)
                                .foregroundColor(rating.color)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .dietCokeCard()

                    // Save button
                    Button {
                        store.updateTimestamp(for: entry, timestamp: selectedDateTime)
                        store.updateRating(for: entry, rating: selectedRating)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.dietCokePrimary)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dietCokeRed)
                }
            }
            .fullScreenCover(isPresented: $showingFullScreenPhoto) {
                if let photo = entryPhoto {
                    FullScreenPhotoView(image: photo)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                SharePreviewSheet(
                    content: entry,
                    isPresented: $showingShareSheet,
                    isPremium: purchaseService.isPremium,
                    initialTheme: .classic
                )
            }
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    EditEntrySheet(entry: DrinkEntry(type: .regularCan))
        .environmentObject(DrinkStore())
        .environmentObject(PurchaseService.shared)
}
