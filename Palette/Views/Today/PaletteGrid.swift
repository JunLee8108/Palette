import SwiftUI

struct PaletteGrid: View {
    let swatches: [PaletteSwatch]
    let selectedId: String?
    var onSelect: (PaletteSwatch) -> Void

    private let columns: Int = 5
    private let rows: Int = 5
    private let spacing: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let tileSize = (proxy.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { col in
                            let idx = row * columns + col
                            if idx < swatches.count {
                                let swatch = swatches[idx]
                                PressablePaletteTile(
                                    color: swatch.color,
                                    size: tileSize,
                                    isSelected: swatch.id == selectedId,
                                    action: { onSelect(swatch) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    PaletteGrid(
        swatches: DefaultPalette.swatches,
        selectedId: "d1_12",
        onSelect: { _ in }
    )
    .padding(28)
    .background(PaletteTheme.background)
}
