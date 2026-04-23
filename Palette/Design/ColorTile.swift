import SwiftUI

struct ColorTile: View {
    let color: Color
    var size: CGFloat = 64
    var isSelected: Bool = false
    var isEmpty: Bool = false

    private var radius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            if isEmpty {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(
                        PaletteTheme.tertiaryText.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
            } else {
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)

                RoundedRectangle(cornerRadius: radius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.32), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: radius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.22)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.42), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )

                if isSelected {
                    RoundedRectangle(cornerRadius: radius + 3)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                        .padding(-3)
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: isEmpty ? .clear : .black.opacity(0.08), radius: 4, y: 2)
    }
}

struct PressableTile: View {
    let color: Color
    var size: CGFloat = 64
    var isSelected: Bool = false
    var action: () -> Void = {}

    @State private var isPressed: Bool = false

    var body: some View {
        ColorTile(color: color, size: size, isSelected: isSelected)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .shadow(color: isPressed ? .black.opacity(0.04) : .black.opacity(0.08),
                    radius: isPressed ? 2 : 4, y: isPressed ? 1 : 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture { action() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

#Preview {
    VStack(spacing: 24) {
        ColorTile(color: Color(hex: "#E8594A"), size: 120)
        ColorTile(color: Color(hex: "#4A8FBD"), size: 80, isSelected: true)
        ColorTile(color: .clear, size: 60, isEmpty: true)
    }
    .padding()
    .background(PaletteTheme.background)
}
