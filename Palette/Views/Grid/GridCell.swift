import SwiftUI

struct GridCell: View {
    let size: CGFloat
    let colorHex: String?
    let isToday: Bool
    let isInYear: Bool

    private var radius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            if let hex = colorHex {
                ColorTile(color: Color(hex: hex), size: size)
            } else if isInYear {
                emptySlot

                if isToday {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(
                            PaletteTheme.secondaryText.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1, dash: [2.5, 2.5])
                        )
                        .frame(width: size, height: size)
                }
            } else {
                Color.clear.frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(PaletteTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 0.5)
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 6) {
        GridCell(size: 40, colorHex: "#E8594A", isToday: false, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: true, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: false, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: false, isInYear: false)
    }
    .padding()
    .background(PaletteTheme.background)
}
