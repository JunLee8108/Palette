import SwiftUI
import PaletteShared

struct OnboardingWelcomePage: View {
    var animateIn: Bool

    @State private var tilesIn: Bool
    @State private var textIn: Bool

    private let heroColors: [Color] = [
        Color(hex: "#E8594A"),
        Color(hex: "#F4A74C"),
        Color(hex: "#2E6B9E")
    ]

    init(animateIn: Bool = true) {
        self.animateIn = animateIn
        _tilesIn = State(initialValue: !animateIn)
        _textIn = State(initialValue: !animateIn)
    }

    var body: some View {
        VStack(spacing: 56) {
            Spacer()

            HStack(spacing: 14) {
                ForEach(Array(heroColors.enumerated()), id: \.offset) { index, color in
                    ColorTile(color: color, size: 86)
                        .offset(y: tilesIn ? 0 : 20)
                        .opacity(tilesIn ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.72)
                            .delay(Double(index) * 0.1),
                            value: tilesIn
                        )
                }
            }

            VStack(spacing: 18) {
                Text(L10n.t("One color a day.", "매일 하나의 색."))
                    .font(.system(size: 34, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(L10n.t(
                    "Leave today as a single color.\nNo words. Just one tap.",
                    "오늘을 한 색으로 남기세요.\n말이 아닌, 한 번의 탭."
                ))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            }
            .opacity(textIn ? 1 : 0)
            .offset(y: textIn ? 0 : 12)
            .animation(.easeOut(duration: 0.6).delay(0.35), value: textIn)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard animateIn else { return }
            tilesIn = true
            textIn = true
        }
    }
}

#Preview {
    OnboardingWelcomePage()
        .background(PaletteTheme.background)
}
