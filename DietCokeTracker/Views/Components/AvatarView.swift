import SwiftUI
import CloudKit

struct AvatarView: View {
    let displayName: String
    var profilePhotoID: String?
    var profileEmoji: String?
    var size: CGFloat = 44
    var showGradientRing: Bool = false

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        ZStack {
            if showGradientRing {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.6), Color.dietCokeRed.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: size + 6, height: size + 6)
            }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = profileEmoji, !emoji.isEmpty {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.15), Color.dietCokeRed.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Text(emoji)
                    .font(.system(size: size * 0.5))
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dietCokeRed.opacity(0.2), Color.dietCokeRed.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.dietCokeRed)
            }
        }
        .onChange(of: profilePhotoID) { _, _ in
            didAttemptLoad = false
            image = nil
        }
        .task(id: profilePhotoID) {
            guard let photoID = profilePhotoID, !photoID.isEmpty, !didAttemptLoad else {
                if profilePhotoID == nil || profilePhotoID?.isEmpty == true {
                    image = nil
                }
                return
            }
            didAttemptLoad = true
            image = await ProfilePhotoCache.shared.photo(for: photoID)
        }
    }
}

@MainActor
class ProfilePhotoCache {
    static let shared = ProfilePhotoCache()

    private var cache: [String: UIImage] = [:]
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func photo(for recordName: String) async -> UIImage? {
        if let cached = cache[recordName] {
            return cached
        }

        if let existing = inFlight[recordName] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            do {
                let recordID = CKRecord.ID(recordName: recordName)
                let container = CKContainer.default()
                let database = container.publicCloudDatabase
                let record = try await database.record(for: recordID)
                guard let asset = record["photo"] as? CKAsset,
                      let fileURL = asset.fileURL,
                      let data = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: data) else {
                    return nil
                }
                cache[recordName] = image
                return image
            } catch {
                return nil
            }
        }

        inFlight[recordName] = task
        let result = await task.value
        inFlight.removeValue(forKey: recordName)
        return result
    }

    func setPhoto(_ image: UIImage, for recordName: String) {
        cache[recordName] = image
    }

    func clearAll() {
        cache.removeAll()
        for task in inFlight.values { task.cancel() }
        inFlight.removeAll()
    }
}
