import SwiftUI
import PaletteShared

struct MonthlyBoardView: View {
    let year: Int
    let firstWeekday: Int
    let entriesByKey: [String: ColorEntry]
    let scrollToTodayTick: Int
    var onSelectDate: (Date) -> Void

    @State private var didAutoScroll: Bool = false

    private let hPadding: CGFloat = 24
    private let tileSpacing: CGFloat = 6
    private let monthSpacing: CGFloat = 36

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(firstWeekday - 1 + $0) % 7] }
    }

    private var monthSymbols: [String] {
        Calendar.current.standaloneMonthSymbols
    }

    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - hPadding * 2
            let tileSize = (availableWidth - tileSpacing * 6) / 7

            VStack(spacing: 0) {
                weekdayHeader(tileSize: tileSize)
                    .padding(.horizontal, hPadding)
                    .padding(.vertical, 10)

                Divider().overlay(PaletteTheme.hairline.opacity(0.6))

                ScrollViewReader { scroller in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: monthSpacing) {
                            ForEach(1...12, id: \.self) { month in
                                monthBlock(month: month, tileSize: tileSize)
                                    .id(month)
                            }
                        }
                        .padding(.horizontal, hPadding)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                    .onAppear {
                        guard !didAutoScroll else { return }
                        didAutoScroll = true
                        let target = currentMonth
                        DispatchQueue.main.async {
                            withAnimation(.none) {
                                scroller.scrollTo(target, anchor: .top)
                            }
                        }
                    }
                    .onChange(of: scrollToTodayTick) { _, _ in
                        let target = currentMonth
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scroller.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func weekdayHeader(tileSize: CGFloat) -> some View {
        HStack(spacing: tileSpacing) {
            ForEach(0..<7, id: \.self) { i in
                Text(weekdaySymbols[i])
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.tertiaryText)
                    .frame(width: tileSize)
            }
        }
    }

    @ViewBuilder
    private func monthBlock(month: Int, tileSize: CGFloat) -> some View {
        let cal = Calendar.current
        let firstOfMonth: Date = {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            return cal.date(from: comps) ?? Date()
        }()

        let firstWeekdayOfMonth = cal.component(.weekday, from: firstOfMonth)
        let startOffset = (firstWeekdayOfMonth - firstWeekday + 7) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        let totalCells = startOffset + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))
        let isCurrent = (month == currentMonth)

        VStack(alignment: .leading, spacing: 14) {
            Text(monthSymbols[month - 1])
                .font(.system(size: 17, weight: isCurrent ? .semibold : .regular, design: .serif))
                .foregroundStyle(
                    isCurrent ? PaletteTheme.primaryText : PaletteTheme.secondaryText
                )

            VStack(spacing: tileSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: tileSpacing) {
                        ForEach(0..<7, id: \.self) { col in
                            let idx = row * 7 + col
                            let dayOfMonth = idx - startOffset + 1
                            if dayOfMonth < 1 || dayOfMonth > daysInMonth {
                                Color.clear.frame(width: tileSize, height: tileSize)
                            } else {
                                let date = cal.date(byAdding: .day, value: dayOfMonth - 1, to: firstOfMonth) ?? firstOfMonth
                                cell(for: date, size: tileSize)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for date: Date, size: CGFloat) -> some View {
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
    }
}

#Preview {
    MonthlyBoardView(
        year: DayKey.year(of: Date()),
        firstWeekday: Calendar.current.firstWeekday,
        entriesByKey: [:],
        scrollToTodayTick: 0,
        onSelectDate: { _ in }
    )
    .background(PaletteTheme.background)
}
