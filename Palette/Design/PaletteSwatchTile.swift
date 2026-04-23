import SwiftUI

struct PaletteSwatchTile: View {
    let color: Color
    let size: CGFloat
    var isSelected: Bool = false

    private var radius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(color)

            RoundedRectangle(cornerRadius: radius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            if isSelected {
                RoundedRectangle(cornerRadius: radius + 3)
                    .strokeBorder(
                        PaletteTheme.primaryText.opacity(0.85),
                        lineWidth: 1.5
                    )
                    .padding(-3)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PressablePaletteTile: View {
    let color: Color
    let size: CGFloat
    var isSelected: Bool = false
    var action: () -> Void = {}

    @State private var isPressed: Bool = false

    var body: some View {
        PaletteSwatchTile(color: color, size: size, isSelected: isSelected)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .contentShape(Rectangle())
            .onTapGesture { action() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isPressed { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        PaletteSwatchTile(color: Color(hex: "#E8594A"), size: 60)
        PaletteSwatchTile(color: Color(hex: "#4A8FBD"), size: 60, isSelected: true)
        PaletteSwatchTile(color: Color(hex: "#2A2824"), size: 60)
    }
    .padding()
    .background(PaletteTheme.background)
}
