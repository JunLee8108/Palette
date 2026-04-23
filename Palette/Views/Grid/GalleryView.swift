import SwiftUI
import SwiftData

enum GalleryMode: Hashable {
    case weekly, monthly, yearly
}

struct GalleryView: View {
    @Query(sort: \ColorEntry.date) private var allEntries: [ColorEntry]

    @State private var mode: GalleryMode = .weekly
    @State private var selectedDay: SelectedDay? = nil

    private struct SelectedDay: Identifiable {
        let id: String
        let date: Date
    }

    private let year: Int
    private let firstWeekday: Int

    init() {
        self.year = DayKey.year(of: Date())
        self.firstWeekday = Calendar.current.firstWeekday
    }

    private var entriesByKey: [String: ColorEntry] {
        var dict: [String: ColorEntry] = [:]
        for entry in allEntries where DayKey.year(of: entry.date) == year {
            dict[entry.dayKey] = entry
        }
        return dict
    }

    private var filledCount: Int { entriesByKey.count }

    var body: some View {
        ZStack {
            PaletteTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                modeSwitcher
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(
                date: day.date,
                entry: entriesByKey[day.id],
                onChanged: { selectedDay = nil }
            )
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(year)")
                .font(.system(size: 30, weight: .thin, design: .serif))
                .tracking(1)
                .foregroundStyle(PaletteTheme.primaryText)
                .monospacedDigit()

            Spacer()

            Text(countText)
                .font(.system(size: 12, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(PaletteTheme.secondaryText)
                .monospacedDigit()
        }
    }

    private var countText: String {
        let n = filledCount
        return L10n.t(
            n == 1 ? "1 day" : "\(n) days",
            "\(n)일"
        )
    }

    // MARK: Mode switcher

    private var modeSwitcher: some View {
        HStack(spacing: 28) {
            modeButton(.weekly, label: L10n.t("Week", "주"))
            modeButton(.monthly, label: L10n.t("Month", "월"))
            modeButton(.yearly, label: L10n.t("Year", "연"))
        }
    }

    private func modeButton(_ m: GalleryMode, label: String) -> some View {
        let isActive = mode == m
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                mode = m
            }
        } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .tracking(0.5)
                    .foregroundStyle(isActive ? PaletteTheme.primaryText : PaletteTheme.tertiaryText)

                Rectangle()
                    .fill(isActive ? PaletteTheme.primaryText : .clear)
                    .frame(width: 14, height: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .weekly:
            WeeklyBoardView(
                year: year,
                firstWeekday: firstWeekday,
                entriesByKey: entriesByKey,
                onSelectDate: handleSelect
            )
            .transition(.opacity)
        case .monthly:
            MonthlyBoardView(
                year: year,
                firstWeekday: firstWeekday,
                entriesByKey: entriesByKey,
                onSelectDate: handleSelect
            )
            .transition(.opacity)
        case .yearly:
            YearlyBoardView(
                year: year,
                firstWeekday: firstWeekday,
                entriesByKey: entriesByKey,
                onSelectDate: handleSelect
            )
            .transition(.opacity)
        }
    }

    private func handleSelect(_ date: Date) {
        selectedDay = SelectedDay(id: DayKey.make(for: date), date: date)
    }
}

#Preview {
    GalleryView()
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
