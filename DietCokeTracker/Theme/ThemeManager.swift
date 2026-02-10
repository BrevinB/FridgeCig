import SwiftUI
import Combine

/// Manages app-wide theme state and persistence
@MainActor
class ThemeManager: ObservableObject {
    private let themeKey = "selectedAppTheme"
    private var cancellables = Set<AnyCancellable>()

    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }

    /// Reference to purchase service for checking premium status
    weak var purchaseService: PurchaseService?

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataManager.appGroupID)
    }

    init() {
        // Load saved theme or default to classic
        if let savedTheme = UserDefaults(suiteName: SharedDataManager.appGroupID)?.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .classic
        }
    }

    /// Configure with purchase service to observe premium status changes
    func configure(purchaseService: PurchaseService) {
        self.purchaseService = purchaseService

        // Observe premium status changes
        purchaseService.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.handlePremiumStatusChange(isPremium: isPremium)
            }
            .store(in: &cancellables)

        // Check current status immediately
        handlePremiumStatusChange(isPremium: purchaseService.isPremium)
    }

    /// Select a theme (checks premium status for premium themes)
    func selectTheme(_ theme: AppTheme) {
        // If trying to select a premium theme without premium, don't allow
        if theme.isPremium && !(purchaseService?.isPremium ?? false) {
            return
        }
        currentTheme = theme
    }

    /// Check if a theme is available to the user
    func isThemeAvailable(_ theme: AppTheme) -> Bool {
        if !theme.isPremium {
            return true
        }
        return purchaseService?.isPremium ?? false
    }

    /// Handle premium status changes (reset to classic if Pro expires)
    private func handlePremiumStatusChange(isPremium: Bool) {
        if !isPremium && currentTheme.isPremium {
            // User lost premium status, reset to classic
            currentTheme = .classic
        }
    }

    private func saveTheme() {
        sharedDefaults?.set(currentTheme.rawValue, forKey: themeKey)
    }

    // MARK: - Convenience Accessors

    var primaryColor: Color {
        currentTheme.primaryColor
    }

    var secondaryColor: Color {
        currentTheme.secondaryColor
    }

    var accentColor: Color {
        currentTheme.accentColor
    }

    var primaryGradient: LinearGradient {
        currentTheme.primaryGradient
    }

    var buttonGradient: LinearGradient {
        currentTheme.buttonGradient
    }

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        currentTheme.backgroundColor(for: colorScheme)
    }

    func cardBackground(for colorScheme: ColorScheme) -> Color {
        currentTheme.cardBackground(for: colorScheme)
    }
}

// MARK: - App Theme Picker View

struct AppThemePicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showingPaywall = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(themeManager.primaryColor)
                Text("App Theme")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if !purchaseService.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                        Text("Pro")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    let isLocked = theme.isPremium && !purchaseService.isPremium
                    ThemePreviewSwatch(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        isPremium: purchaseService.isPremium,
                        isLocked: isLocked
                    ) {
                        if isLocked {
                            showingPaywall = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.selectTheme(theme)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.dietCokeCardBackground)
        .cornerRadius(12)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

