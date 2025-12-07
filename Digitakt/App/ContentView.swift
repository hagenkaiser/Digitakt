import SwiftUI
import AudioKit

/// Main view for the Digitakt instrument standalone app.
/// Shows 16 trig pads in a horizontal row at the bottom (Elektron style).
/// Uses fixed 16:9 aspect ratio.
struct ContentView: View {
    @StateObject private var conductor = Conductor()
    @Environment(\.scenePhase) var scenePhase

    // 16 steps, tracking which are active (have trigs)
    @State private var trigStates: [Bool] = Array(repeating: false, count: 16)

    var body: some View {
        GeometryReader { geometry in
            // Calculate dimensions for 16:9 aspect ratio that fits within available space
            let availableSize = geometry.size
            let targetAspect: CGFloat = 16.0 / 9.0

            let fittedSize: CGSize = {
                let widthBasedHeight = availableSize.width / targetAspect
                let heightBasedWidth = availableSize.height * targetAspect

                if widthBasedHeight <= availableSize.height {
                    return CGSize(width: availableSize.width, height: widthBasedHeight)
                } else {
                    return CGSize(width: heightBasedWidth, height: availableSize.height)
                }
            }()

            ZStack {
                Color.black.ignoresSafeArea()

                DigitaktMainView(
                    conductor: conductor,
                    trigStates: $trigStates,
                    size: fittedSize
                )
                .frame(width: fittedSize.width, height: fittedSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .onAppear {
            conductor.start()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !conductor.isRunning {
                conductor.start()
            }
        }
    }
}

/// Main Digitakt UI content with fixed aspect ratio
struct DigitaktMainView: View {
    @ObservedObject var conductor: Conductor
    @Binding var trigStates: [Bool]
    let size: CGSize

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DIGITAKT")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(conductor.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(conductor.isRunning ? "Running" : "Stopped")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Transport controls
            HStack(spacing: 16) {
                Button(action: {
                    // Play will be implemented in Phase 1C
                }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                Button(action: {
                    // Stop
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }

                Spacer()

                Text("120.0 BPM")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Main content area (placeholder for future controls)
            Spacer()

            // 16 Trig Pads - horizontal row at bottom
            TrigPadRow(
                trigStates: $trigStates,
                availableWidth: size.width,
                onPadTap: { _ in
                    // Send MIDI note-on (note 60 = middle C, velocity 127 = full)
                    conductor.receiveMIDINoteOn(noteNumber: 60, velocity: 127)
                }
            )
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
        }
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
