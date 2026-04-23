import SwiftUI

struct TodayView: View {
    private var today: Date { Date() }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMMd")
        return f
    }

    var body: some View {
        ZStack {
            PaletteTheme.background.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text(dayFormatter.string(from: today))
                    .font(.system(size: 46, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)

                ColorTile(color: .clear, size: 180, isEmpty: true)

                Text(L10n.t("Pick a color for today.", "오늘의 색을 골라주세요."))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)

                Spacer()
            }
        }
    }
}

#Preview {
    TodayView()
}
