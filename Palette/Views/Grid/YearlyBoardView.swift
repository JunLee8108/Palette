import SwiftUI
import PaletteShared

struct YearlyBoardView: View {
    let year: Int
    let firstWeekday: Int
    let entriesByKey: [String: ColorEntry]
    var onSelectDate: (Date) -> Void

    private let hPadding: CGFloat = 24
    private let cellSpacing: CGFloat = 4
    private let monthLabelWidth: CGFloat = 30

    struct YearLayout {
        let jan1Column: Int
        let totalRows: Int
        let totalDays: Int
        let monthLabelByRow: [Int: String]
    }

    private struct YearLayoutKey: Hashable {
        let year: Int
        let firstWeekday: Int
    }

    private static let layoutMemo = Memo<YearLayoutKey, YearLayout>()

    private var layout: YearLayout {
        Self.layoutMemo.get(YearLayoutKey(year: year, firstWeekday: firstWeekday)) {
            let cal = Calendar.current
            let jan1 = DayKey.january1(of: year)
            let weekday = cal.component(.weekday, from: jan1)
            let jan1Col = (weekday - firstWeekday + 7) % 7
            let totalDays = DayKey.daysInYear(year)
            let totalRows = Int(ceil(Double(jan1Col + totalDays) / 7.0))

            let symbols = cal.shortMonthSymbols
            var labels: [Int: String] = [:]
            for month in 1...12 {
                var comps = DateComponents()
                comps.year = year
                comps.month = month
                comps.day = 1
                guard let date = cal.date(from: comps),
                      let ord = cal.ordinality(of: .day, in: .year, for: date) else { continue }
                let totalOffset = jan1Col + (ord - 1)
                let row = totalOffset / 7
                if labels[row] == nil {
                    labels[row] = symbols[month - 1]
                }
            }

            return YearLayout(
                jan1Column: jan1Col,
                totalRows: totalRows,
                totalDays: totalDays,
                monthLabelByRow: labels
            )
        }
    }

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(firstWeekday - 1 + $0) % 7] }
    }

    private var todayKey: String { DayKey.make(for: Date()) }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - hPadding * 2 - monthLabelWidth - 8
            let cellSize = max(14, (availableWidth - cellSpacing * 6) / 7)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    weekdayHeader(cellSize: cellSize)
                        .padding(.leading, monthLabelWidth + 8)

                    gridBody(cellSize: cellSize)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, hPadding)
                .padding(.top, 10)
            }
        }
    }

    private func weekdayHeader(cellSize: CGFloat) -> some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { i in
                Text(weekdaySymbols[i])
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.tertiaryText)
                    .frame(width: cellSize)
            }
        }
    }

    private func gridBody(cellSize: CGFloat) -> some View {
        LazyVStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(0..<layout.totalRows, id: \.self) { row in
                HStack(spacing: 8) {
                    Text(layout.monthLabelByRow[row] ?? "")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(PaletteTheme.secondaryText)
                        .frame(width: monthLabelWidth, alignment: .leading)

                    HStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { col in
                            cellAt(row: row, col: col, size: cellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellAt(row: Int, col: Int, size: CGFloat) -> some View {
        let offset = row * 7 + col - layout.jan1Column
        if offset < 0 || offset >= layout.totalDays {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: DayKey.january1(of: year)
            ) ?? Date()
            let key = DayKey.make(for: date)
            let entry = entriesByKey[key]
            let isToday = key == todayKey
            let hasEntry = entry != nil

            GridCell(
                size: size,
                colorHex: entry?.colorHex,
                isToday: isToday,
                isInYear: true
            )
            .contentShape(Rectangle())
            .onTapGesture { onSelectDate(date) }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(CellAccessibility.label(date: date, isToday: isToday))
            .accessibilityValue(CellAccessibility.value(hasEntry: hasEntry))
            .accessibilityHint(CellAccessibility.hint(date: date, hasEntry: hasEntry))
            .accessibilityAction(.default) { onSelectDate(date) }
        }
    }
}

#Preview {
    YearlyBoardView(
        year: DayKey.year(of: Date()),
        firstWeekday: Calendar.current.firstWeekday,
        entriesByKey: [:],
        onSelectDate: { _ in }
    )
    .background(PaletteTheme.background)
}
