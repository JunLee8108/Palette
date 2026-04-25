import SwiftUI
import PaletteShared

struct OnboardingGridPage: View {
    private let columns: Int = 7
    private let rows: Int = 12
    private let tileSize: CGFloat = 22
    private let spacing: CGFloat = 4

    @State private var filledCount: Int = 0
    @State private var textIn: Bool = false
    @State private var gridColors: [Color] = []
    @State private var revealPosition: [Int] = []

    var body: some View {
        VStack(spacing: 44) {
            Spacer()

            VStack(spacing: 28) {
                grid
                    .padding(.horizontal, 28)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(PaletteTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                    )
                    .padding(.horizontal, 28)

                Text(L10n.t(
                    "\(filledCount) days",
                    "\(filledCount)일"
                ))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(PaletteTheme.secondaryText)
                .tracking(1)
                .contentTransition(.numericText())
            }

            VStack(spacing: 16) {
                Text(L10n.t("A year of you.", "1년 후의 나."))
                    .font(.system(size: 34, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(L10n.t(
                    "Each tile is a day.\nStacked, they become your year.",
                    "각 타일은 하루.\n쌓일수록 당신만의 한 해가 됩니다."
                ))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            }
            .opacity(textIn ? 1 : 0)
            .offset(y: textIn ? 0 : 10)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: textIn)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .task { await runAnimation() }
    }

    private var grid: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        let revealIndex = revealPosition.indices.contains(index) ? revealPosition[index] : index
                        let isVisible = filledCount > revealIndex
                        let color = gridColors.indices.contains(index) ? gridColors[index] : .clear

                        ZStack {
                            RoundedRectangle(cornerRadius: tileSize * 0.22)
                                .strokeBorder(PaletteTheme.tertiaryText.opacity(0.25), lineWidth: 0.5)
                                .frame(width: tileSize, height: tileSize)

                            if isVisible {
                                ColorTile(color: color, size: tileSize)
                                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                            }
                        }
                        .frame(width: tileSize, height: tileSize)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isVisible)
                    }
                }
            }
        }
    }

    private func runAnimation() async {
        let total = columns * rows
        gridColors = (0..<total).map { _ in randomPaletteColor() }

        let order = Array(0..<total).shuffled()
        var positions = Array(repeating: 0, count: total)
        for (step, cellIndex) in order.enumerated() {
            positions[cellIndex] = step
        }
        revealPosition = positions

        try? await Task.sleep(nanoseconds: 250_000_000)
        textIn = true

        try? await Task.sleep(nanoseconds: 200_000_000)
        for i in 1...total {
            filledCount = i
            try? await Task.sleep(nanoseconds: 35_000_000)
        }
    }

    private func randomPaletteColor() -> Color {
        DefaultPalette.swatches.randomElement()!.color
    }
}

#Preview {
    OnboardingGridPage()
        .background(PaletteTheme.background)
}
