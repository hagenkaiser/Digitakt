import CoreAudioKit
import SwiftUI

/// Observable wrapper for AUParameter values
class AudioParameter: ObservableObject {
    @Published var value: AUValue
    var auParameter: AUParameter

    init(auParameter: AUParameter, initialValue: AUValue) {
        self.auParameter = auParameter
        self.value = initialValue
    }

    func updateValue(_ newValue: AUValue) {
        DispatchQueue.main.async {
            self.value = newValue
            self.auParameter.setValue(newValue, originator: nil)
        }
    }
}

/// AUv3 view for the Digitakt instrument.
/// This is the view shown when the AU is loaded in a host (AUM, GarageBand, etc.)
/// Uses fixed 16:9 aspect ratio.
struct DigitaktAUv3View: View {
    @Environment(\.colorScheme) var colorScheme

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
                Color.black

                DigitaktAUv3ContentView(size: fittedSize)
                    .frame(width: fittedSize.width, height: fittedSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
    }
}

/// Main content view for AUv3 with fixed aspect ratio
struct DigitaktAUv3ContentView: View {
    let size: CGSize

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack {
                Spacer()

                Text("DIGITAKT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("AUv3 Instrument")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 16 Trig Pads - horizontal row at bottom
            TrigPadRow(availableWidth: size.width)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// Horizontal row of 16 trig pads that scales to fit available width
struct TrigPadRow: View {
    let availableWidth: CGFloat

    // Calculate pad size based on available width
    // 16 pads + 15 gaps (2pt each) + 16pt horizontal padding
    private var padSize: CGFloat {
        let totalPadding: CGFloat = 16 + (15 * 2)
        let availableForPads = availableWidth - totalPadding
        let calculatedSize = availableForPads / 16
        // Cap maximum size
        return min(calculatedSize, 50)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<16, id: \.self) { index in
                TrigPadButton(stepNumber: index + 1, size: padSize)
            }
        }
    }
}

/// Individual trig pad button
struct TrigPadButton: View {
    let stepNumber: Int
    let size: CGFloat
    @State private var isActive = false

    var body: some View {
        Button(action: {
            isActive.toggle()
        }) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? Color.red : Color(white: 0.15))
                .frame(width: size, height: size)
                .overlay(
                    Text("\(stepNumber)")
                        .font(.system(size: max(8, size * 0.3), weight: .medium, design: .monospaced))
                        .foregroundColor(isActive ? .white : Color(white: 0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(white: 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
