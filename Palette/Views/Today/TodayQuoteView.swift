import SwiftUI

struct TodayQuoteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index: Int = 0

    private static let intervalSeconds: UInt64 = 5_500_000_000
    private static let transitionDuration: Double = 0.7

    private static let quotes: [(en: String, ko: String)] = [
        ("Don't think too hard.", "깊이 생각하지 마세요."),
        ("One color is enough.", "한 색이면 충분해요."),
        ("Today, in a single color.", "오늘, 한 색으로."),
        ("Red for spark. Blue for stillness.", "빨강은 설렘, 파랑은 고요."),
        ("The color you're drawn to is the right one.", "마음이 가는 색이 정답이에요."),
        ("No words. Just one tap.", "말이 아닌, 한 번의 탭."),
        ("Days, collected.", "쌓이는 하루들."),
        ("Color speaks first.", "색이 먼저 말해요.")
    ]

    var body: some View {
        let quote = Self.quotes[index]
        ZStack {
            Text(L10n.t(quote.en, quote.ko))
                .font(.system(size: 13, weight: .light, design: .serif))
                .italic()
                .tracking(0.4)
                .foregroundStyle(PaletteTheme.tertiaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 44)
                .id(index)
                .transition(transition)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.intervalSeconds)
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: Self.transitionDuration)) {
                    index = (index + 1) % Self.quotes.count
                }
            }
        }
    }

    private var transition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity.combined(with: .offset(y: -6))
        )
    }
}

#Preview {
    TodayQuoteView()
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(PaletteTheme.background)
}
