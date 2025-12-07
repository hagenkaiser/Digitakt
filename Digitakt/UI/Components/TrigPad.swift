import SwiftUI

/// Horizontal row of 16 trig pads that scales to fit available width
struct TrigPadRow: View {
    @Binding var trigStates: [Bool]
    let availableWidth: CGFloat
    var onPadTap: ((Int) -> Void)? = nil

    // Calculate pad size based on available width
    // 16 pads + 15 gaps (2pt each) + 16pt horizontal padding
    private var padSize: CGFloat {
        let totalPadding: CGFloat = 16 + (15 * 2)
        let availableForPads = availableWidth - totalPadding
        let calculatedSize = availableForPads / 16
        // Cap maximum size
        return min(calculatedSize, 60)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<16, id: \.self) { index in
                TrigPad(
                    stepNumber: index + 1,
                    isActive: trigStates[index],
                    size: padSize,
                    onTap: {
                        trigStates[index].toggle()
                        onPadTap?(index)
                    }
                )
            }
        }
    }
}

/// Individual trig pad button (Elektron style)
struct TrigPad: View {
    let stepNumber: Int
    let isActive: Bool
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isActive ? Color.red : Color(white: 0.15))
                .frame(width: size, height: size)
                .overlay(
                    Text("\(stepNumber)")
                        .font(.system(size: max(8, size * 0.28), weight: .medium, design: .monospaced))
                        .foregroundColor(isActive ? .white : Color(white: 0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color(white: 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
