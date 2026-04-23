import SwiftUI

struct LaunchView: View {
    var onFinish: () -> Void

    @State private var tileProgress: Int = 0
    @State private var showWordmark: Bool = false
    @State private var fadeOut: Bool = false

    private let tileSize: CGFloat = 44
    private let spacing: CGFloat = 8

    private let tileColors: [Color] = [
        Color(hex: "#E8594A"), Color(hex: "#F5C84C"), Color(hex: "#2E6B9E"),
        Color(hex: "#8FC06E"), Color(hex: "#D96E7C"), Color(hex: "#F4A74C"),
        Color(hex: "#2A2824"), Color(hex: "#6FB3D2"), Color(hex: "#A04A5C")
    ]

    private let sequence: [Int] = [4, 1, 3, 5, 7, 0, 2, 6, 8]

    var body: some View {
        ZStack {
            PaletteTheme.background
                .ignoresSafeArea()

            VStack(spacing: 44) {
                Spacer()

                grid

                VStack(spacing: 10) {
                    Text("Palette")
                        .font(.system(size: 42, weight: .thin, design: .serif))
                        .foregroundStyle(PaletteTheme.primaryText)
                        .tracking(1.5)
                        .opacity(showWordmark ? 1 : 0)
                        .offset(y: showWordmark ? 0 : 6)
                        .animation(.easeOut(duration: 0.7), value: showWordmark)

                    Text(L10n.t("one color a day", "하루 한 색"))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(PaletteTheme.secondaryText)
                        .tracking(1.2)
                        .opacity(showWordmark ? 0.9 : 0)
                        .animation(.easeOut(duration: 0.7).delay(0.15), value: showWordmark)
                }

                Spacer()
                Spacer()
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .animation(.easeInOut(duration: 0.45), value: fadeOut)
        .task { await runIntro() }
    }

    private var grid: some View {
        VStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        let revealOrder = sequence.firstIndex(of: index) ?? 0
                        let isVisible = tileProgress > revealOrder

                        ColorTile(color: tileColors[index], size: tileSize)
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1 : 0.6)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.68),
                                value: isVisible
                            )
                    }
                }
            }
        }
    }

    private func runIntro() async {
        try? await Task.sleep(nanoseconds: 180_000_000)
        for i in 0..<sequence.count {
            tileProgress = i + 1
            try? await Task.sleep(nanoseconds: 90_000_000)
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
        showWordmark = true
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        fadeOut = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        onFinish()
    }
}

#Preview {
    LaunchView(onFinish: {})
}
