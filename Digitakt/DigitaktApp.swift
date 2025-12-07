import SwiftUI
import AVFoundation
import AudioKit

@main
struct DigitaktApp: App {

    init() {
#if os(iOS)
        do {
            // Configure audio session for instrument playback
            if #available(iOS 18.0, *) {
                if !ProcessInfo.processInfo.isMacCatalystApp && !ProcessInfo.processInfo.isiOSAppOnMac {
                    Settings.sampleRate = 48_000
                }
            }
            if #available(macOS 15.0, *) {
                Settings.sampleRate = 48_000
            }

            Settings.bufferLength = .medium
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print("Audio session setup error: \(err)")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
