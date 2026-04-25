import SwiftUI
import PaletteShared

struct WeeklyBoardView: View {
    let year: Int
    let firstWeekday: Int
    let entriesByKey: [String: ColorEntry]
    let scrollToTodayTick: Int
    var onSelectDate: (Date) -> Void

    @State private var didAutoScroll: Bool = false

    private let hPadding: CGFloat = 24
    private let tileSpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 24

    private struct WeeksKey: Hashable {
        let year: Int
        let firstWeekday: Int
    }

    private static let weeksMemo = Memo<WeeksKey, [WeekSlot]>()

    private var weeks: [WeekSlot] {
        Self.weeksMemo.get(WeeksKey(year: year, firstWeekday: firstWeekday)) {
            WeekSlot.all(in: year, firstWeekday: firstWeekday)
        }
    }

    private var todayKey: String { DayKey.make(for: Date()) }

    private var anchorWeekId: String? {
        let cal = Calendar.current
        let today = cal.dateComponents([.month, .day], from: Date())
        var target = DateComponents()
        target.year = year
        target.month = today.month
        target.day = today.day
        guard let anchorDate = cal.date(from: target) else { return nil }
        let anchorKey = DayKey.make(for: anchorDate)
        return weeks.first { week in
            week.dates.contains { date in
                guard let date else { return false }
                return DayKey.make(for: date) == anchorKey
            }
        }?.id
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - hPadding * 2
            let tileSize = (availableWidth - tileSpacing * 6) / 7

            ScrollViewReader { scroller in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: rowSpacing) {
                        let anchor = anchorWeekId
                        ForEach(weeks) { week in
                            weekRow(week, tileSize: tileSize, isCurrent: week.id == anchor)
                                .id(week.id)
                        }
                    }
                    .padding(.horizontal, hPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    guard !didAutoScroll, let id = anchorWeekId else { return }
                    didAutoScroll = true
                    DispatchQueue.main.async {
                        withAnimation(.none) {
                            scroller.scrollTo(id, anchor: .top)
                        }
                    }
                }
                .onChange(of: scrollToTodayTick) { _, _ in
                    guard let id = anchorWeekId else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scroller.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func weekRow(_ week: WeekSlot, tileSize: CGFloat, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(week.label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(
                    isCurrent
                        ? PaletteTheme.primaryText
                        : PaletteTheme.secondaryText
                )
                .textCase(.uppercase)

            HStack(spacing: tileSpacing) {
                ForEach(0..<7, id: \.self) { i in
                    cell(for: week.dates[i], size: tileSize)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for date: Date?, size: CGFloat) -> some View {
        if let date {
            let key = DayKey.make(for: date)
            let entry = entriesByKey[key]
            Button {
                onSelectDate(date)
            } label: {
                GridCell(
                    size: size,
                    colorHex: entry?.colorHex,
                    isToday: key == todayKey,
                    isInYear: true
                )
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}

struct WeekSlot: Identifiable {
    let id: String
    let dates: [Date?]
    let label: String

    static func all(in year: Int, firstWeekday: Int) -> [WeekSlot] {
        let cal = Calendar.current
        let jan1 = DayKey.january1(of: year)
        let jan1Weekday = cal.component(.weekday, from: jan1)
        let daysBeforeJan1 = (jan1Weekday - firstWeekday + 7) % 7
        guard let firstWeekStart = cal.date(byAdding: .day, value: -daysBeforeJan1, to: jan1) else {
            return []
        }

        let totalDays = DayKey.daysInYear(year)
        let totalWeeks = Int(ceil(Double(daysBeforeJan1 + totalDays) / 7.0))

        let interval = DateIntervalFormatter()
        interval.locale = .current
        interval.dateTemplate = "MMMd"

        let single = DateFormatter()
        single.locale = .current
        single.setLocalizedDateFormatFromTemplate("MMMd")

        var weeks: [WeekSlot] = []
        for w in 0..<totalWeeks {
            guard let weekStart = cal.date(byAdding: .day, value: w * 7, to: firstWeekStart) else { continue }
            var dates: [Date?] = []
            for i in 0..<7 {
                let date = cal.date(byAdding: .day, value: i, to: weekStart)
                if let date, DayKey.year(of: date) == year {
                    dates.append(date)
                } else {
                    dates.append(nil)
                }
            }

            let inYear = dates.compactMap { $0 }
            let label: String
            if inYear.count >= 2, let first = inYear.first, let last = inYear.last {
                label = interval.string(from: first, to: last)
            } else if let only = inYear.first {
                label = single.string(from: only)
            } else {
                label = ""
            }

            weeks.append(WeekSlot(id: "w-\(year)-\(w)", dates: dates, label: label))
        }
        return weeks
    }
}

#Preview {
    WeeklyBoardView(
        year: DayKey.year(of: Date()),
        firstWeekday: Calendar.current.firstWeekday,
        entriesByKey: [:],
        scrollToTodayTick: 0,
        onSelectDate: { _ in }
    )
    .background(PaletteTheme.background)
}
