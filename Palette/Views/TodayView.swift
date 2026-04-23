import SwiftUI

struct TodayView: View {
    @AppStorage("palette.username") private var username: String = ""

    @State private var showSettings: Bool = false

    private var today: Date { Date() }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMMd")
        return f
    }

    private var greeting: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return L10n.t("Pick a color for today.", "오늘의 색을 골라주세요.")
        }
        return L10n.t("Hi \(trimmed). Pick today's color.", "\(trimmed)님, 오늘의 색을 골라주세요.")
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

                Text(greeting)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(PaletteTheme.secondaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.t("Settings", "설정"))
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    TodayView()
}
