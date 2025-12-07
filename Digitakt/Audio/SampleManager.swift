import AudioKit
import AVFoundation

/// Manages sample loading and URL storage for audio playback.
/// Provides a centralized repository for sample URLs used across voice engines.
class SampleManager {
    static let shared = SampleManager()

    /// Storage for sample URLs, keyed by name
    private var sampleURLs: [String: URL] = [:]

    private init() {
        // Load bundled samples on initialization
        loadBundledSamples()
    }

    /// Register a sample URL with a given name
    /// - Parameters:
    ///   - url: File URL pointing to an audio file
    ///   - name: Unique identifier for this sample
    func registerSample(url: URL, named name: String) {
        sampleURLs[name] = url
        Log("SampleManager: Registered sample '\(name)' at \(url.lastPathComponent)")
    }

    /// Retrieve a sample URL by name
    /// - Parameter name: The name used when registering the sample
    /// - Returns: The URL if found, nil otherwise
    func getSampleURL(named name: String) -> URL? {
        guard let url = sampleURLs[name] else {
            Log("SampleManager: Sample '\(name)' not found")
            return nil
        }
        return url
    }

    /// Load bundled samples included with the app
    private func loadBundledSamples() {
        // Register Square.wav from the Sounds bundle directory
        if let squareURL = Bundle.main.url(forResource: "Square", withExtension: "wav", subdirectory: "Sounds") {
            registerSample(url: squareURL, named: "square")
        } else {
            Log("SampleManager: Could not find Square.wav in bundle")
        }
    }

    /// Get all loaded sample names (for debugging)
    var loadedSamples: [String] {
        return Array(sampleURLs.keys)
    }
}
