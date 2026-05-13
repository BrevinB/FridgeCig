import SwiftUI

struct StateCansView: View {
    @EnvironmentObject var store: StateCanStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCode: String?
    @State private var filter: StateCanFilter = .all

    private var backgroundColor: Color {
        themeManager.backgroundColor(for: colorScheme)
    }

    private var filteredStates: [StateCan] {
        let cans = StateCan.all
        switch filter {
        case .all:
            return cans.sorted { lhs, rhs in
                let lCollected = store.isCollected(lhs.code)
                let rCollected = store.isCollected(rhs.code)
                if lCollected != rCollected { return lCollected }
                return lhs.name < rhs.name
            }
        case .collected:
            return cans.filter { store.isCollected($0.code) }
                .sorted { (store.collectionDate($0.code) ?? .distantPast) > (store.collectionDate($1.code) ?? .distantPast) }
        case .remaining:
            return cans.filter { !store.isCollected($0.code) }
                .sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StateCanProgressHeader(
                        collected: store.collectedCount,
                        total: store.totalCount,
                        percentage: store.completionPercentage
                    )
                    .padding(.horizontal)

                    USMapView(onTapState: { code in
                        selectedCode = code
                    })
                    .padding(.horizontal, 8)

                    StateCanFilterBar(selected: $filter)
                        .padding(.horizontal)

                    LazyVStack(spacing: 10) {
                        ForEach(filteredStates) { can in
                            StateCanRow(
                                can: can,
                                collectedDate: store.collectionDate(can.code),
                                isVerified: store.isVerified(can.code)
                            ) {
                                selectedCode = can.code
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("State Cans")
            .sheet(item: Binding(
                get: { selectedCode.flatMap { StateCan.byCode[$0] } },
                set: { newValue in selectedCode = newValue?.code }
            )) { can in
                StateCanDetailSheet(can: can)
            }
        }
    }
}

// MARK: - Filter

enum StateCanFilter: String, CaseIterable {
    case all = "All"
    case collected = "Collected"
    case remaining = "Remaining"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .collected: return "checkmark.seal.fill"
        case .remaining: return "circle.dashed"
        }
    }
}

struct StateCanFilterBar: View {
    @Binding var selected: StateCanFilter
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            ForEach(StateCanFilter.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = option
                    }
                    HapticManager.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.caption)
                        Text(option.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if selected == option {
                                themeManager.primaryGradient
                            } else {
                                Color.dietCokeCardBackground
                            }
                        }
                    )
                    .foregroundColor(selected == option ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - Progress Header

struct StateCanProgressHeader: View {
    let collected: Int
    let total: Int
    let percentage: Double
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.primaryGradient)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("America 250 Cans")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.85))

                        Text("\(collected) of \(total)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("states collected")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: percentage / 100)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(percentage))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .accessibilityHidden(true)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * (percentage / 100), height: 10)
                    }
                }
                .frame(height: 10)
                .accessibilityHidden(true)
            }
            .padding(20)
        }
        .frame(height: 180)
        .shadow(color: themeManager.primaryColor.opacity(0.4), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("State cans: \(collected) of \(total) collected, \(Int(percentage)) percent complete")
    }
}

// MARK: - Row

struct StateCanRow: View {
    let can: StateCan
    let collectedDate: Date?
    let isVerified: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    private var isCollected: Bool { collectedDate != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isCollected ? themeManager.primaryColor.opacity(0.18) : Color.dietCokeSilver.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: can.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isCollected ? themeManager.primaryColor : .dietCokeDarkSilver)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(can.name)
                            .font(.headline)
                            .foregroundColor(.dietCokeCharcoal)
                        Text(can.code)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.dietCokeDarkSilver)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dietCokeSilver.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    Text(can.symbol)
                        .font(.subheadline)
                        .foregroundColor(.dietCokeDarkSilver)
                }

                Spacer()

                if isCollected {
                    HStack(spacing: 6) {
                        if isVerified {
                            Image(systemName: "camera.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(themeManager.primaryColor)
                                .padding(5)
                                .background(themeManager.primaryColor.opacity(0.15))
                                .clipShape(Circle())
                                .accessibilityLabel("Photo verified")
                        }
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.primaryColor)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.dietCokeSilver)
                }
            }
            .padding(14)
            .background(Color.dietCokeCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(can.name), \(can.symbol)\(isCollected ? ", collected" : "")\(isVerified ? ", photo verified" : "")")
    }
}

// MARK: - Detail Sheet

struct StateCanDetailSheet: View {
    let can: StateCan
    @EnvironmentObject var store: StateCanStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isCollected: Bool { store.isCollected(can.code) }
    private var isVerified: Bool { store.isVerified(can.code) }
    private var collectionDate: Date? { store.collectionDate(can.code) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(themeManager.primaryGradient)
                            .overlay(
                                AmbientBubblesBackground(bubbleCount: 8)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .opacity(0.6)
                            )

                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                Circle()
                                    .stroke(Color.white.opacity(0.35), lineWidth: 3)
                                    .frame(width: 120, height: 120)
                                Image(systemName: can.icon)
                                    .font(.system(size: 54, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text(can.name)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text(can.symbol)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.85))

                            if isCollected, let date = collectionDate {
                                HStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Collected \(date.formatted(date: .abbreviated, time: .omitted))")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())

                                    if isVerified {
                                        HStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                            Text("Photo")
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 28)
                    }
                    .frame(minHeight: 300)
                    .padding(.horizontal)

                    // Photo strip (only when verified with photos)
                    if isVerified {
                        StateCanPhotoStrip(code: can.code)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if isCollected {
                            Button {
                                store.uncollect(can.code)
                                HapticManager.lightImpact()
                            } label: {
                                Label("Mark as Uncollected", systemImage: "xmark.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.dietCokeCharcoal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.dietCokeSilver.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        } else {
                            Button {
                                store.collect(can.code)
                                HapticManager.success()
                            } label: {
                                Label("Mark as Collected", systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(themeManager.primaryGradient)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
            .navigationTitle(can.code)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Photo Strip

struct StateCanPhotoStrip: View {
    let code: String
    @EnvironmentObject var store: StateCanStore
    @State private var fullscreenFilename: String?

    private var filenames: [String] {
        store.photoFilenames(for: code)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeRed)
                Text("PHOTOS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)
                Spacer()
                Text("\(filenames.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filenames, id: \.self) { filename in
                        StateCanPhotoTile(filename: filename) {
                            fullscreenFilename = filename
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 12)
        .fullScreenCover(item: Binding(
            get: { fullscreenFilename.map(PhotoIdentifier.init) },
            set: { newValue in fullscreenFilename = newValue?.filename }
        )) { id in
            StateCanPhotoFullscreen(
                filename: id.filename,
                code: code,
                onDismiss: { fullscreenFilename = nil }
            )
        }
    }
}

private struct PhotoIdentifier: Identifiable {
    let filename: String
    var id: String { filename }
}

struct StateCanPhotoTile: View {
    let filename: String
    let onTap: () -> Void
    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dietCokeSilver.opacity(0.15))
                    .frame(width: 140, height: 140)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.dietCokeDarkSilver)
                }
            }
        }
        .buttonStyle(.plain)
        .task(id: filename) {
            image = PhotoStorage.loadPhoto(filename: filename)
        }
    }
}

struct StateCanPhotoFullscreen: View {
    let filename: String
    let code: String
    let onDismiss: () -> Void
    @EnvironmentObject var store: StateCanStore
    @State private var image: UIImage?
    @State private var showingDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.4))
                    }
                    Spacer()
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.4))
                    }
                }
                .padding()
                Spacer()
            }
        }
        .task(id: filename) {
            image = PhotoStorage.loadPhoto(filename: filename)
        }
        .confirmationDialog("Delete this photo?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.removePhoto(filename, from: code)
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
