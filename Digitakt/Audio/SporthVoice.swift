import AudioKit
import AVFoundation
import Foundation

/// A single voice for sample playback with envelope.
/// Uses AudioKit's AudioPlayer for sample playback.
/// Phase 1B: Minimal implementation - just plays a sample when triggered.
class SporthVoice {
    private var player: AudioPlayer?
    private let sampleURL: URL?

    /// Initialize a voice with a sample URL
    /// - Parameter sampleURL: The URL of the audio file to play
    init(sampleURL: URL?) {
        self.sampleURL = sampleURL

        if let url = sampleURL {
            do {
                let file = try AVAudioFile(forReading: url)
                player = AudioPlayer(file: file)
                player?.isLooping = false
            } catch {
                Log("Failed to load sample: \(error)")
            }
        }
    }

    /// Trigger the voice to play the sample
    func trigger() {
        player?.stop()       // Stop first to ensure clean retrigger
        player?.seek(time: 0)
        player?.play()
    }

    /// Set playback rate (1.0 = original speed)
    /// - Parameter rate: Playback speed multiplier (0.25 - 4.0 recommended)
    func setPlaybackRate(_ rate: Float) {
        // AudioPlayer rate control - will implement in future phase
        // For now, just plays at original speed
    }

    /// Start the player
    func start() {
        // AudioPlayer doesn't need explicit start - it plays on trigger
    }

    /// Stop the player
    func stop() {
        player?.stop()
    }

    /// Access the underlying node for audio routing
    var node: Node? {
        return player
    }
}
