import Foundation
import CoreGraphics

// MARK: - Share Format

/// Defines the dimensions and aspect ratios for different social media platforms
enum ShareFormat: String, CaseIterable, Identifiable, Codable {
    case instagramStory   // 9:16 vertical (1080x1920)
    case instagramPost    // 1:1 square (1080x1080)
    case twitterCard      // 16:9 horizontal (1200x675)
    case tiktok           // 9:16 vertical (1080x1920)

    var id: String { rawValue }

    // MARK: - Dimensions

    var width: CGFloat {
        switch self {
        case .instagramStory, .tiktok:
            return 1080
        case .instagramPost:
            return 1080
        case .twitterCard:
            return 1200
        }
    }

    var height: CGFloat {
        switch self {
        case .instagramStory, .tiktok:
            return 1920
        case .instagramPost:
            return 1080
        case .twitterCard:
            return 675
        }
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var aspectRatio: CGFloat {
        width / height
    }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .instagramStory:
            return "Story"
        case .instagramPost:
            return "Post"
        case .twitterCard:
            return "Twitter"
        case .tiktok:
            return "TikTok"
        }
    }

    var icon: String {
        switch self {
        case .instagramStory:
            return "rectangle.portrait.fill"
        case .instagramPost:
            return "square.fill"
        case .twitterCard:
            return "rectangle.fill"
        case .tiktok:
            return "play.rectangle.fill"
        }
    }

    var platformName: String {
        switch self {
        case .instagramStory, .instagramPost:
            return "Instagram"
        case .twitterCard:
            return "Twitter"
        case .tiktok:
            return "TikTok"
        }
    }

    /// Whether this format requires premium subscription
    var isPremium: Bool {
        switch self {
        case .instagramStory:
            return false
        case .instagramPost, .twitterCard, .tiktok:
            return true
        }
    }

    // MARK: - Preview Scale

    /// Scale factor for preview display (to fit in UI)
    var previewScale: CGFloat {
        switch self {
        case .instagramStory, .tiktok:
            return 0.2
        case .instagramPost:
            return 0.25
        case .twitterCard:
            return 0.3
        }
    }
}

// MARK: - Format Category

extension ShareFormat {
    enum Category {
        case vertical   // Stories, TikTok
        case square     // Feed posts
        case horizontal // Twitter cards
    }

    var category: Category {
        switch self {
        case .instagramStory, .tiktok:
            return .vertical
        case .instagramPost:
            return .square
        case .twitterCard:
            return .horizontal
        }
    }
}
