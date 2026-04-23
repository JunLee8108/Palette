import SwiftUI
import SwiftData

struct TodayView: View {
    var onSaved: () -> Void = {}

    @Environment(\.modelContext) private var context
    @AppStorage("palette.username") private var username: String = ""

    @State private var showSettings: Bool = false
    @State private var selectedSwatchId: String? = nil
    @State private var previewColorHex: String? = nil
    @State private var animatingFill: Bool = false

    @Query private var todayEntries: [ColorEntry]

    init(onSaved: @escaping () -> Void = {}) {
        self.onSaved = onSaved
        let key = DayKey.make(for: Date())
        _todayEntries = Query(
            filter: #Predicate<ColorEntry> { $0.dayKey == key }
        )
    }

    private var todayEntry: ColorEntry? { todayEntries.first }

    private var today: Date { Date() }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMMd")
        return f
    }

    private var greeting: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if todayEntry != nil {
            return L10n.t("Today's color.", "오늘의 색.")
        }
        if trimmed.isEmpty {
            return L10n.t("Pick a color for today.", "오늘의 색을 골라주세요.")
        }
        return L10n.t("Hi \(trimmed). Pick today's color.", "\(trimmed)님, 오늘의 색을 골라주세요.")
    }

    private var previewColor: Color? {
        if let hex = previewColorHex { return Color(hex: hex) }
        if let entry = todayEntry { return Color(hex: entry.colorHex) }
        return nil
    }

    var body: some View {
        ZStack {
            PaletteTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 8)

                Text(dayFormatter.string(from: today))
                    .font(.system(size: 44, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)

                previewTile

                Text(greeting)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer(minLength: 12)

                PaletteGrid(
                    swatches: DefaultPalette.swatches,
                    selectedId: selectedSwatchId ?? todayEntry?.swatchId,
                    onSelect: handleSelect
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }

            settingsButton
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedSwatchId)
    }

    // MARK: Preview tile

    private var previewTile: some View {
        ZStack {
            if let color = previewColor {
                ColorTile(color: color, size: 148)
                    .scaleEffect(animatingFill ? 1.06 : 1.0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.65), value: animatingFill)
            } else {
                ColorTile(color: .clear, size: 148, isEmpty: true)
            }
        }
        .frame(height: 148)
    }

    // MARK: Settings

    private var settingsButton: some View {
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

    // MARK: Actions

    private func handleSelect(_ swatch: PaletteSwatch) {
        selectedSwatchId = swatch.id
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            previewColorHex = swatch.hex
            animatingFill = true
        }

        ColorStore.upsertToday(swatch: swatch, in: context)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            animatingFill = false
            try? await Task.sleep(nanoseconds: 600_000_000)
            onSaved()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
