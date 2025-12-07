import AudioKit
import AVFoundation

/// Main audio conductor for the Digitakt instrument.
/// Manages the audio engine and voice playback.
class Conductor: ObservableObject {
    let engine = AudioEngine()

    // Voice engine
    private var voice: SporthVoice?

    @Published var isRunning = false

    init() {
        setupAudioChain()
    }

    private func setupAudioChain() {
        // Get sample URL from SampleManager
        let sampleURL = SampleManager.shared.getSampleURL(named: "square")

        // Create voice with sample URL
        voice = SporthVoice(sampleURL: sampleURL)

        // Connect voice to engine output
        if let voiceNode = voice?.node {
            engine.output = voiceNode
        } else {
            Log("Conductor: No voice node available, using silent mixer")
            engine.output = Mixer() // Silent fallback
        }
    }

    func start() {
        do {
            try engine.start()

            // Start the voice (if needed)
            voice?.start()

            isRunning = true
            Log("Digitakt engine started")
        } catch {
            Log("Could not start engine: \(error)")
        }
    }

    func stop() {
        voice?.stop()
        engine.stop()
        isRunning = false
    }

    /// Trigger the voice to play the loaded sample
    func triggerVoice() {
        voice?.trigger()
    }

    /// Set playback rate (1.0 = original speed, 2.0 = double speed, etc.)
    func setPlaybackRate(_ rate: Float) {
        voice?.setPlaybackRate(rate)
    }
}
