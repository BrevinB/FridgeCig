import Foundation
import UIKit
import os

struct PhotoStorage {
    private static let photosDirectoryName = "DrinkPhotos"

    static var photosDirectory: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedDataManager.appGroupID
        ) else {
            // Fallback to documents directory if app group not available
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(photosDirectoryName)
        }

        return containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(photosDirectoryName, isDirectory: true)
    }

    static func ensureDirectoryExists() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
        // Exclude photos from iCloud backup
        var url = photosDirectory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? url.setResourceValues(resourceValues)
    }

    static func generateFilename() -> String {
        return UUID().uuidString + ".jpg"
    }

    static func savePhoto(_ image: UIImage, filename: String) -> Bool {
        ensureDirectoryExists()

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            AppLogger.photos.error("Failed to save photo: \(error.localizedDescription)")
            return false
        }
    }

    static func loadPhoto(filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    static func deletePhoto(filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            AppLogger.photos.error("Failed to delete photo: \(error.localizedDescription)")
        }
    }

    static func photoURL(for filename: String) -> URL {
        return photosDirectory.appendingPathComponent(filename)
    }
}
