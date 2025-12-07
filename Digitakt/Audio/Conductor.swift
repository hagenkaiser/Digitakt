import AudioKit
import AVFoundation

/// Main audio conductor for the Digitakt instrument.
/// This will be expanded to include custom voice engine, sample slicing, and sequencer.
class Conductor: ObservableObject {
    let engine = AudioEngine()

    // Placeholder for future audio chain
    // Phase 1B will add: Voice engine with AVAudioPlayerNode
    // Phase 1D will add: Sample slicing (Grid machine)
    // Phase 1E will add: Filter and envelope

    @Published var isRunning = false

    init() {
        // For now, just set up a silent output
        // This will be replaced with actual audio chain in Phase 1B
        engine.output = Mixer()
    }

    func start() {
        do {
            try engine.start()
            isRunning = true
            Log("Digitakt engine started")
        } catch {
            Log("Could not start engine: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }
}
