import SwiftUI

struct YearlyBoardView: View {
    let year: Int
    let firstWeekday: Int
    let entriesByKey: [String: ColorEntry]
    var onSelectDate: (Date) -> Void

    private let hPadding: CGFloat = 24
    private let cellSpacing: CGFloat = 4
    private let monthLabelWidth: CGFloat = 30

    private var jan1Column: Int {
        let jan1 = DayKey.january1(of: year)
        let weekday = Calendar.current.component(.weekday, from: jan1)
        return (weekday - firstWeekday + 7) % 7
    }

    private var totalRows: Int {
        let days = DayKey.daysInYear(year)
        return Int(ceil(Double(jan1Column + days) / 7.0))
    }

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(firstWeekday - 1 + $0) % 7] }
    }

    private var monthLabelByRow: [Int: String] {
        let cal = Calendar.current
        let symbols = cal.shortMonthSymbols
        var result: [Int: String] = [:]
        for month in 1...12 {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            guard let date = cal.date(from: comps),
                  let pos = gridPosition(for: date) else { continue }
            if result[pos.row] == nil {
                result[pos.row] = symbols[month - 1]
            }
        }
        return result
    }

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
        VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(0..<totalRows, id: \.self) { row in
                HStack(spacing: 8) {
                    Text(monthLabelByRow[row] ?? "")
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
        let offset = row * 7 + col - jan1Column
        if offset < 0 || offset >= DayKey.daysInYear(year) {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: DayKey.january1(of: year)
            ) ?? Date()
            let key = DayKey.make(for: date)
            let entry = entriesByKey[key]
            let isToday = DayKey.isToday(date)

            Button {
                onSelectDate(date)
            } label: {
                GridCell(
                    size: size,
                    colorHex: entry?.colorHex,
                    isToday: isToday,
                    isInYear: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func gridPosition(for date: Date) -> (row: Int, col: Int)? {
        let cal = Calendar.current
        guard let ord = cal.ordinality(of: .day, in: .year, for: date) else { return nil }
        let totalOffset = jan1Column + (ord - 1)
        return (row: totalOffset / 7, col: totalOffset % 7)
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
