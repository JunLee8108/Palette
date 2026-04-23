import SwiftUI

struct OnboardingReadyPage: View {
    var username: String = ""

    @State private var tileIn: Bool = false
    @State private var textIn: Bool = false

    private var heading: String {
        if username.isEmpty {
            return L10n.t("You're ready.", "준비 완료.")
        }
        return L10n.t("Ready, \(username).", "\(username)님, 준비 완료.")
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ColorTile(color: Color(hex: "#F5C84C"), size: 120)
                .scaleEffect(tileIn ? 1 : 0.6)
                .opacity(tileIn ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.7), value: tileIn)

            VStack(spacing: 16) {
                Text(heading)
                    .font(.system(size: 36, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(L10n.t(
                    "Your first color is today.\nThree seconds. That's all.",
                    "오늘의 첫 색이 기다려요.\n3초면 충분합니다."
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
        .onAppear {
            tileIn = true
            textIn = true
        }
    }
}

#Preview("with name") {
    OnboardingReadyPage(username: "Jun")
        .background(PaletteTheme.background)
}

#Preview("no name") {
    OnboardingReadyPage()
        .background(PaletteTheme.background)
}
