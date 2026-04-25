import SwiftUI
import PaletteShared

struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex: Int = 0

    private let totalPages: Int = 4

    var body: some View {
        ZStack {
            PaletteTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $pageIndex) {
                    InfoPageOne()
                        .tag(0)
                    InfoPageTwo()
                        .tag(1)
                    InfoPageThree()
                        .tag(2)
                    InfoPageFour()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))

                pageIndicator
                    .padding(.top, 12)
                    .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.t("Close", "닫기"))
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == pageIndex ? PaletteTheme.primaryText : PaletteTheme.tertiaryText.opacity(0.5))
                    .frame(width: i == pageIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pageIndex)
            }
        }
    }
}

// MARK: - Page 1: Don't think too hard

private struct InfoPageOne: View {
    @State private var visualIn: Bool = false
    @State private var textIn: Bool = false

    private let heroColor = Color(hex: "#F4A74C")

    var body: some View {
        InfoPageScaffold(
            visual: {
                ColorTile(color: heroColor, size: 168)
                    .scaleEffect(visualIn ? 1.0 : 0.92)
                    .opacity(visualIn ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.72), value: visualIn)
            },
            headline: L10n.t("Don't think too hard.", "오늘을 고민하지 마세요."),
            subtitle: L10n.t(
                "No words, no right answer.\nOne color is enough for today.",
                "긴 글도, 정답도 없습니다.\n그저 마음에 닿는 색 하나면 충분해요."
            ),
            textIn: textIn
        )
        .onAppear {
            visualIn = true
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                textIn = true
            }
        }
    }
}

// MARK: - Page 2: One tap, color speaks

private struct InfoPageTwo: View {
    @State private var tilesIn: Bool = false
    @State private var textIn: Bool = false

    private let palette: [Color] = [
        Color(hex: "#E8594A"),
        Color(hex: "#F4A74C"),
        Color(hex: "#E8DC6F"),
        Color(hex: "#5AA874"),
        Color(hex: "#4A8FBD"),
        Color(hex: "#9B7EBD"),
        Color(hex: "#C85A94"),
        Color(hex: "#7A756E")
    ]

    var body: some View {
        InfoPageScaffold(
            visual: {
                let columns: [GridItem] = Array(
                    repeating: GridItem(.fixed(48), spacing: 10),
                    count: 4
                )
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(palette.enumerated()), id: \.offset) { index, color in
                        ColorTile(color: color, size: 48)
                            .scaleEffect(tilesIn ? 1.0 : 0.6)
                            .opacity(tilesIn ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.04),
                                value: tilesIn
                            )
                    }
                }
            },
            headline: L10n.t("Just one tap.", "한 번의 탭으로."),
            subtitle: L10n.t(
                "Pick a color for how today feels.\nRed for spark, blue for stillness.",
                "오늘의 기분을 색으로 골라보세요.\n빨강은 설렘, 파랑은 고요함처럼."
            ),
            textIn: textIn
        )
        .onAppear {
            tilesIn = true
            withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
                textIn = true
            }
        }
    }
}

// MARK: - Page 3: Days collected

private struct InfoPageThree: View {
    @State private var gridIn: Bool = false
    @State private var textIn: Bool = false

    private let columns: Int = 7
    private let rows: Int = 7
    private let tileSize: CGFloat = 22
    private let spacing: CGFloat = 4

    private let gridColors: [Color] = {
        let palette = DefaultPalette.swatches
        var generator = SeededGenerator(seed: 42)
        return (0..<49).map { _ in
            palette.randomElement(using: &generator)!.color
        }
    }()

    var body: some View {
        InfoPageScaffold(
            visual: {
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                let color = gridColors.indices.contains(index)
                                    ? gridColors[index]
                                    : .clear
                                RoundedRectangle(cornerRadius: tileSize * 0.22)
                                    .fill(color)
                                    .frame(width: tileSize, height: tileSize)
                                    .opacity(gridIn ? 1 : 0)
                                    .scaleEffect(gridIn ? 1 : 0.5)
                                    .animation(
                                        .spring(response: 0.45, dampingFraction: 0.75)
                                            .delay(Double(index) * 0.012),
                                        value: gridIn
                                    )
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(PaletteTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                )
            },
            headline: L10n.t("Days collected.", "쌓이는 하루들."),
            subtitle: L10n.t(
                "Week by week, month by month —\nyour year becomes a palette.",
                "주, 월, 그리고 일 년이 모이면\n당신만의 컬러 다이어리가 됩니다."
            ),
            textIn: textIn
        )
        .onAppear {
            gridIn = true
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textIn = true
            }
        }
    }
}

// MARK: - Page 4: Keep it as a photo

private struct InfoPageFour: View {
    @State private var cardIn: Bool = false
    @State private var textIn: Bool = false

    private let stripe: [Color] = [
        Color(hex: "#E8594A"),
        Color(hex: "#F4A74C"),
        Color(hex: "#E8DC6F"),
        Color(hex: "#5AA874"),
        Color(hex: "#4A8FBD"),
        Color(hex: "#9B7EBD"),
        Color(hex: "#C85A94")
    ]

    var body: some View {
        InfoPageScaffold(
            visual: {
                VStack(spacing: 14) {
                    HStack(spacing: 6) {
                        ForEach(Array(stripe.enumerated()), id: \.offset) { _, color in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(height: 56)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    HStack {
                        Text(L10n.t("My week", "나의 한 주"))
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .tracking(1.2)
                            .foregroundStyle(PaletteTheme.secondaryText)
                            .textCase(.uppercase)
                        Spacer()
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(PaletteTheme.tertiaryText)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .frame(width: 240)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(PaletteTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                .scaleEffect(cardIn ? 1.0 : 0.94)
                .opacity(cardIn ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.72), value: cardIn)
            },
            headline: L10n.t("Keep it as a photo.", "사진으로 간직하기."),
            subtitle: L10n.t(
                "Pick any span of days\nand save it as a single image.",
                "마음에 드는 기간을 골라\n한 장의 그림으로 저장해보세요."
            ),
            textIn: textIn
        )
        .onAppear {
            cardIn = true
            withAnimation(.easeOut(duration: 0.6).delay(0.25)) {
                textIn = true
            }
        }
    }
}

// MARK: - Shared scaffold

private struct InfoPageScaffold<Visual: View>: View {
    @ViewBuilder var visual: () -> Visual
    let headline: String
    let subtitle: String
    let textIn: Bool

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            visual()
                .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                Text(headline)
                    .font(.system(size: 30, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(textIn ? 1 : 0)
            .offset(y: textIn ? 0 : 10)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Tiny seeded RNG so the page-3 grid is stable across renders

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

#Preview {
    InfoSheetView()
}
