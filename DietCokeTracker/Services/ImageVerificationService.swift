import Foundation
import UIKit
import Vision

/// Service to verify photos contain a beverage using Vision framework
@MainActor
class ImageVerificationService: ObservableObject {
    @Published var isVerifying = false
    @Published var lastVerificationResult: VerificationResult?

    struct VerificationResult {
        let isValid: Bool
        let confidence: Double
        let message: String
        let detectedLabels: [String]
    }

    /// Keywords that indicate a beverage image
    private static let beverageKeywords: Set<String> = [
        "beverage", "drink", "soda", "pop", "cola", "coke",
        "can", "bottle", "cup", "glass", "container",
        "aluminum", "carbonated", "soft drink",
        "refreshment", "liquid", "water", "juice",
        "plastic", "tin", "drinking", "straw"
    ]

    /// Keywords/patterns that indicate NOT a beverage - be very broad
    private static let nonBeveragePatterns: [String] = [
        // Animals
        "dog", "cat", "pet", "animal", "puppy", "kitten", "bird", "fish",
        "retriever", "terrier", "poodle", "bulldog", "shepherd", "labrador",
        "spaniel", "beagle", "husky", "corgi", "chihuahua", "dachshund",
        "persian", "siamese", "tabby", "mammal", "canine", "feline",
        // People
        "person", "people", "face", "human", "man", "woman", "child", "baby",
        "portrait", "selfie", "head", "body",
        // Vehicles
        "car", "vehicle", "truck", "motorcycle", "bicycle", "bus", "train",
        "airplane", "boat", "ship",
        // Places/Nature
        "building", "house", "room", "landscape", "mountain", "tree", "flower",
        "beach", "ocean", "sky", "grass", "forest", "garden",
        // Objects (non-drink)
        "phone", "computer", "laptop", "screen", "television", "furniture",
        "chair", "table", "bed", "couch", "book", "toy"
    ]

    /// Check if Vision-based image verification is available
    static var isAvailable: Bool {
        return true
    }

    /// Verify that an image likely contains a beverage
    func verifyImage(_ image: UIImage) async -> VerificationResult {
        isVerifying = true
        defer { isVerifying = false }

        guard let cgImage = image.cgImage else {
            return VerificationResult(
                isValid: true,
                confidence: 0.5,
                message: "Could not process image",
                detectedLabels: []
            )
        }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { [weak self] request, error in
                guard let self = self else {
                    continuation.resume(returning: VerificationResult(
                        isValid: true,
                        confidence: 0.5,
                        message: "Verification cancelled",
                        detectedLabels: []
                    ))
                    return
                }

                if let error = error {
                    print("Vision classification error: \(error)")
                    continuation.resume(returning: VerificationResult(
                        isValid: true,
                        confidence: 0.5,
                        message: "Verification failed",
                        detectedLabels: []
                    ))
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: VerificationResult(
                        isValid: true,
                        confidence: 0.5,
                        message: "No classifications found",
                        detectedLabels: []
                    ))
                    return
                }

                let result = self.analyzeClassifications(observations)
                continuation.resume(returning: result)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform Vision request: \(error)")
                    continuation.resume(returning: VerificationResult(
                        isValid: true,
                        confidence: 0.5,
                        message: "Verification failed",
                        detectedLabels: []
                    ))
                }
            }
        }
    }

    private func analyzeClassifications(_ observations: [VNClassificationObservation]) -> VerificationResult {
        // Get top classifications with confidence > 0.05 (lower threshold to catch more)
        let topClassifications = observations
            .filter { $0.confidence > 0.05 }
            .prefix(30)
            .map { (identifier: $0.identifier.lowercased(), confidence: Double($0.confidence)) }

        let detectedLabels = topClassifications.map { $0.identifier }

        // Debug: print what Vision detected
        print("🔍 Vision detected: \(detectedLabels.prefix(10).joined(separator: ", "))")

        // Check for beverage-related terms
        var beverageScore: Double = 0
        var nonBeverageScore: Double = 0
        var matchedBeverageTerms: [String] = []
        var matchedNonBeverageTerms: [String] = []

        for (identifier, confidence) in topClassifications {
            // Check beverage keywords
            for keyword in Self.beverageKeywords {
                if identifier.contains(keyword) {
                    beverageScore += confidence
                    matchedBeverageTerms.append("\(keyword)(\(String(format: "%.2f", confidence)))")
                    break
                }
            }

            // Check non-beverage patterns - use contains for partial matching
            for pattern in Self.nonBeveragePatterns {
                if identifier.contains(pattern) {
                    nonBeverageScore += confidence
                    matchedNonBeverageTerms.append("\(pattern)(\(String(format: "%.2f", confidence)))")
                    break
                }
            }
        }

        print("🥤 Beverage score: \(beverageScore) - matches: \(matchedBeverageTerms)")
        print("🚫 Non-beverage score: \(nonBeverageScore) - matches: \(matchedNonBeverageTerms)")

        // Decision logic - be stricter about non-beverages
        let result: VerificationResult

        if beverageScore > 0.2 {
            // Found beverage indicators
            result = VerificationResult(
                isValid: true,
                confidence: min(beverageScore, 1.0),
                message: "Looks like a drink!",
                detectedLabels: detectedLabels
            )
        } else if nonBeverageScore > 0.15 {
            // Found non-beverage with low/no beverage score - REJECT
            let topMatch = matchedNonBeverageTerms.first ?? "something else"
            result = VerificationResult(
                isValid: false,
                confidence: min(nonBeverageScore, 1.0),
                message: "That looks like \(topMatch.components(separatedBy: "(").first ?? "something else"), not a Diet Coke! 📸",
                detectedLabels: detectedLabels
            )
        } else {
            // Uncertain - accept but note it
            result = VerificationResult(
                isValid: true,
                confidence: 0.5,
                message: "We'll take your word for it!",
                detectedLabels: detectedLabels
            )
        }

        lastVerificationResult = result
        return result
    }
}
