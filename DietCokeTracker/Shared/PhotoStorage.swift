import Foundation
import UIKit
import os

struct PhotoStorage {
    private static let photosDirectoryName = "DrinkPhotos"
    private static let migrationKey = "PhotoStorageMigratedToAppSupport"

    /// Primary storage: main app container's Application Support (persisted and backed up)
    static var photosDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent(photosDirectoryName, isDirectory: true)
    }

    /// Legacy storage: app group container (photos may have been saved here previously)
    private static var legacyPhotosDirectory: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedDataManager.appGroupID
        ) else {
            return nil
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
    }

    /// Migrate photos from the legacy app group container to the main app container
    static func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        ensureDirectoryExists()

        guard let legacyDir = legacyPhotosDirectory else {
            defaults.set(true, forKey: migrationKey)
            return
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyDir.path) else {
            defaults.set(true, forKey: migrationKey)
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: legacyDir.path)
            var migratedCount = 0
            for file in files {
                let source = legacyDir.appendingPathComponent(file)
                let destination = photosDirectory.appendingPathComponent(file)
                // Only move if not already in the new location
                if !fileManager.fileExists(atPath: destination.path) {
                    try? fileManager.copyItem(at: source, to: destination)
                    migratedCount += 1
                }
            }
            if migratedCount > 0 {
                AppLogger.photos.info("Migrated \(migratedCount) photos to Application Support")
            }
        } catch {
            AppLogger.photos.error("Photo migration failed: \(error.localizedDescription)")
        }

        defaults.set(true, forKey: migrationKey)
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
        // Check primary location
        let fileURL = photosDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }

        // Fallback: check legacy app group location
        if let legacyDir = legacyPhotosDirectory {
            let legacyURL = legacyDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: legacyURL.path) {
                // Move to primary location for future access
                ensureDirectoryExists()
                try? FileManager.default.copyItem(at: legacyURL, to: fileURL)
                return UIImage(contentsOfFile: legacyURL.path)
            }
        }

        return nil
    }

    static func deletePhoto(filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            AppLogger.photos.error("Failed to delete photo: \(error.localizedDescription)")
        }

        // Also clean up legacy location if it exists there
        if let legacyDir = legacyPhotosDirectory {
            let legacyURL = legacyDir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: legacyURL)
        }
    }

    static func photoURL(for filename: String) -> URL {
        return photosDirectory.appendingPathComponent(filename)
    }
}
