import SwiftUI

struct PaletteGrid: View {
    let swatches: [PaletteSwatch]
    let selectedId: String?
    var onSelect: (PaletteSwatch) -> Void

    private let columns: Int = 5
    private let spacing: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let tileSize = (proxy.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(swatches) { swatch in
                    PressableTile(
                        color: swatch.color,
                        size: tileSize,
                        isSelected: swatch.id == selectedId,
                        action: { onSelect(swatch) }
                    )
                    .frame(width: tileSize, height: tileSize)
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
    .padding(24)
    .background(PaletteTheme.background)
}
