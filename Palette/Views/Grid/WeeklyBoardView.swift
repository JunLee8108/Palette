import SwiftUI

struct WeeklyBoardView: View {
    let year: Int
    let firstWeekday: Int
    let entriesByKey: [String: ColorEntry]
    var onSelectDate: (Date) -> Void

    private let hPadding: CGFloat = 24
    private let tileSpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 24

    private var weeks: [WeekSlot] {
        WeekSlot.all(in: year, firstWeekday: firstWeekday)
    }

    private var currentWeekId: String? {
        weeks.first(where: { $0.contains(Date()) })?.id
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - hPadding * 2
            let tileSize = (availableWidth - tileSpacing * 6) / 7

            ScrollViewReader { scroller in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(weeks) { week in
                            weekRow(week, tileSize: tileSize)
                                .id(week.id)
                        }
                    }
                    .padding(.horizontal, hPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    if let id = currentWeekId {
                        DispatchQueue.main.async {
                            withAnimation(.none) {
                                scroller.scrollTo(id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func weekRow(_ week: WeekSlot, tileSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(week.label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(
                    week.isCurrent
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
                    isToday: DayKey.isToday(date),
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

    func contains(_ date: Date) -> Bool {
        let key = DayKey.make(for: date)
        return dates.contains { d in
            guard let d else { return false }
            return DayKey.make(for: d) == key
        }
    }

    var isCurrent: Bool { contains(Date()) }

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
                label = interval.string(from: first, to: last) ?? ""
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
        onSelectDate: { _ in }
    )
    .background(PaletteTheme.background)
}
