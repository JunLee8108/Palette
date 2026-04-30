import SwiftUI
import PaletteShared

// MARK: - Shared palette for export canvas

private enum ExportPalette {
    static let primary = Color(hex: "#2A2620")
    static let secondary = Color(hex: "#7A756E")
    static let tertiary = Color(hex: "#B8B2A7")
    static let emptyFill = Color(hex: "#E8E0D0").opacity(0.6)
    static let stripeEmpty = Color(hex: "#E8E0D0")
    static let cardSurface = Color(hex: "#F5F2EB")
    static let cardBorder = Color(hex: "#E8E0D0")
}

// MARK: - Top-level canvas

struct ExportCanvas: View {
    let options: ExportOptions
    let data: ExportData

    var body: some View {
        ZStack {
            options.background.color
            contentLayout
        }
    }

    @ViewBuilder
    private var contentLayout: some View {
        switch (options.style, options.scope) {
        case (.grid, .week):
            GridWeekLayout(options: options, data: data)
                .padding(.horizontal, 56)
                .padding(.vertical, 64)
        case (.grid, .month):
            GridMonthLayout(options: options, data: data)
                .padding(.horizontal, 48)
                .padding(.vertical, 56)
        case (.grid, .year):
            GridYearLayout(options: options, data: data)
                .padding(.horizontal, 40)
                .padding(.vertical, 48)
        case (.stripes, _):
            StripesLayout(options: options, data: data)
        case (.swatch, _):
            SwatchWeekLayout(options: options, data: data)
                .padding(.horizontal, 80)
                .padding(.vertical, 96)
        }
    }
}

// MARK: - Grid Week

struct GridWeekLayout: View {
    let options: ExportOptions
    let data: ExportData

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(options.firstWeekday - 1 + $0) % 7] }
    }

    var body: some View {
        VStack(spacing: 0) {
            if options.showHeader {
                ExportHeaderText(text: ExportText.header(for: options))
                    .padding(.bottom, 32)
            }

            GeometryReader { proxy in
                VStack(spacing: 12) {
                    if options.showWeekdayLabels {
                        HStack(spacing: 10) {
                            ForEach(0..<7, id: \.self) { i in
                                Text(weekdaySymbols[i])
                                    .font(.system(size: 20, weight: .semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(ExportPalette.tertiary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    let spacing: CGFloat = 10
                    let tile = (proxy.size.width - spacing * 6) / 7
                    HStack(spacing: spacing) {
                        ForEach(data.dates, id: \.self) { date in
                            ExportTile(
                                hex: data.colorsByKey[DayKey.make(for: date)],
                                size: tile
                            )
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }

            if options.showDayCount || options.showWatermark {
                ExportFooter(options: options, data: data)
                    .padding(.top, 32)
            }
        }
    }
}

// MARK: - Swatch Week (gallery card)

struct SwatchWeekLayout: View {
    let options: ExportOptions
    let data: ExportData

    private var stripeColors: [Color] {
        data.dates.map { date in
            if let hex = data.colorsByKey[DayKey.make(for: date)] {
                return Color(hex: hex)
            }
            return ExportPalette.stripeEmpty
        }
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer(minLength: 0)
            card
                .aspectRatio(1.85, contentMode: .fit)
                .frame(maxWidth: .infinity)
            if options.showWatermark {
                Text("palette")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(ExportPalette.tertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var card: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ForEach(Array(stripeColors.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(color)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 64)
            .padding(.top, 64)
            .padding(.bottom, options.showHeader || options.showDayCount ? 36 : 64)

            if options.showHeader || options.showDayCount {
                cardFooter
                    .padding(.horizontal, 64)
                    .padding(.bottom, 56)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(ExportPalette.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 36)
                .strokeBorder(ExportPalette.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, y: 12)
    }

    private var cardFooter: some View {
        HStack(alignment: .firstTextBaseline) {
            if options.showHeader {
                Text(ExportText.header(for: options))
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(ExportPalette.primary)
            }
            Spacer(minLength: 24)
            if options.showDayCount {
                Text(ExportText.dayCount(filled: data.filledCount, total: 7))
                    .font(.system(size: 18, weight: .medium))
                    .monospacedDigit()
                    .tracking(0.6)
                    .foregroundStyle(ExportPalette.secondary)
            }
        }
    }
}

// MARK: - Grid Month

struct GridMonthLayout: View {
    let options: ExportOptions
    let data: ExportData

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(options.firstWeekday - 1 + $0) % 7] }
    }

    private var monthInfo: (firstOfMonth: Date, daysInMonth: Int, startOffset: Int, rows: Int)? {
        guard case let .month(_, _, first, _) = data.range else { return nil }
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: first)
        let startOffset = (weekday - options.firstWeekday + 7) % 7
        let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let rows = Int(ceil(Double(startOffset + days) / 7.0))
        return (first, days, startOffset, rows)
    }

    var body: some View {
        VStack(spacing: 0) {
            if options.showHeader {
                ExportHeaderText(text: ExportText.header(for: options))
                    .padding(.bottom, 36)
            }

            if let info = monthInfo {
                GeometryReader { proxy in
                    let spacing: CGFloat = 8
                    let tileW = (proxy.size.width - spacing * 6) / 7
                    let headerH: CGFloat = options.showWeekdayLabels ? 28 : 0
                    let headerGap: CGFloat = options.showWeekdayLabels ? 18 : 0
                    let availH = proxy.size.height - headerH - headerGap
                    let tileH = (availH - CGFloat(info.rows - 1) * spacing) / CGFloat(info.rows)
                    let tile = max(0, min(tileW, tileH))
                    let gridW = tile * 7 + spacing * 6

                    VStack(spacing: headerGap) {
                        if options.showWeekdayLabels {
                            HStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { i in
                                    Text(weekdaySymbols[i])
                                        .font(.system(size: 18, weight: .semibold))
                                        .tracking(0.6)
                                        .foregroundStyle(ExportPalette.tertiary)
                                        .frame(width: tile)
                                }
                            }
                            .frame(width: gridW)
                        }

                        VStack(spacing: spacing) {
                            ForEach(0..<info.rows, id: \.self) { row in
                                HStack(spacing: spacing) {
                                    ForEach(0..<7, id: \.self) { col in
                                        cell(row: row, col: col, size: tile, info: info)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if options.showDayCount || options.showWatermark {
                ExportFooter(options: options, data: data)
                    .padding(.top, 36)
            }
        }
    }

    @ViewBuilder
    private func cell(row: Int, col: Int, size: CGFloat, info: (firstOfMonth: Date, daysInMonth: Int, startOffset: Int, rows: Int)) -> some View {
        let idx = row * 7 + col
        let day = idx - info.startOffset + 1
        if day < 1 || day > info.daysInMonth {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(byAdding: .day, value: day - 1, to: info.firstOfMonth) ?? info.firstOfMonth
            let hex = data.colorsByKey[DayKey.make(for: date)]
            ExportTile(hex: hex, size: size)
        }
    }
}

// MARK: - Grid Year

struct GridYearLayout: View {
    let options: ExportOptions
    let data: ExportData

    private var year: Int {
        if case .year(let y, _, _) = data.range { return y }
        return Calendar.current.component(.year, from: options.date)
    }

    private var jan1Column: Int {
        let jan1 = DayKey.january1(of: year)
        let weekday = Calendar.current.component(.weekday, from: jan1)
        return (weekday - options.firstWeekday + 7) % 7
    }

    private var totalDays: Int { DayKey.daysInYear(year) }

    private var totalRows: Int {
        Int(ceil(Double(jan1Column + totalDays) / 7.0))
    }

    var body: some View {
        VStack(spacing: 0) {
            if options.showHeader {
                ExportHeaderText(text: ExportText.header(for: options), size: 44)
                    .padding(.bottom, 32)
            }

            GeometryReader { proxy in
                let spacing: CGFloat = 3
                let cellW = (proxy.size.width - spacing * 6) / 7
                let cellH = (proxy.size.height - CGFloat(totalRows - 1) * spacing) / CGFloat(totalRows)
                let cell = max(0, min(cellW, cellH))
                let totalW = cell * 7 + spacing * 6
                let totalH = cell * CGFloat(totalRows) + spacing * CGFloat(totalRows - 1)

                VStack(spacing: spacing) {
                    ForEach(0..<totalRows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { col in
                                yearCell(row: row, col: col, size: cell)
                            }
                        }
                    }
                }
                .frame(width: totalW, height: totalH)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if options.showDayCount || options.showWatermark {
                ExportFooter(options: options, data: data)
                    .padding(.top, 28)
            }
        }
    }

    @ViewBuilder
    private func yearCell(row: Int, col: Int, size: CGFloat) -> some View {
        let offset = row * 7 + col - jan1Column
        if offset < 0 || offset >= totalDays {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: DayKey.january1(of: year)
            ) ?? Date()
            let hex = data.colorsByKey[DayKey.make(for: date)]
            ExportTile(hex: hex, size: size, tight: true)
        }
    }
}

// MARK: - Stripes

struct StripesLayout: View {
    let options: ExportOptions
    let data: ExportData

    private var stripeColors: [Color] {
        let hexes = data.dates.map { data.colorsByKey[DayKey.make(for: $0)] }
        if options.skipEmpty {
            return hexes.compactMap { $0 }.map { Color(hex: $0) }
        } else {
            return hexes.map { hex in
                hex.map { Color(hex: $0) } ?? ExportPalette.stripeEmpty
            }
        }
    }

    private var isFullyEmpty: Bool {
        data.colorsByKey.isEmpty
    }

    var body: some View {
        Group {
            if isFullyEmpty {
                options.background.color
            } else if options.stripesOrientation == .horizontal {
                HStack(spacing: 0) {
                    ForEach(Array(stripeColors.enumerated()), id: \.offset) { _, color in
                        color.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(stripeColors.enumerated()), id: \.offset) { _, color in
                        color.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if options.showHeader {
                Text(ExportText.header(for: options))
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.black.opacity(0.35))
                    )
                    .padding(32)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if options.showWatermark {
                Text("palette")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.black.opacity(0.25))
                    )
                    .padding(32)
            }
        }
    }
}

// MARK: - Reusable pieces

struct ExportTile: View {
    let hex: String?
    let size: CGFloat
    var tight: Bool = false

    var body: some View {
        let radius = size * (tight ? 0.2 : 0.22)
        Group {
            if let hex {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color(hex: hex))
            } else {
                RoundedRectangle(cornerRadius: radius)
                    .fill(ExportPalette.emptyFill)
            }
        }
        .frame(width: size, height: size)
    }
}

struct ExportHeaderText: View {
    let text: String
    var size: CGFloat = 32

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .serif))
            .tracking(size >= 40 ? 2 : (size >= 28 ? 1.6 : 1.2))
            .foregroundStyle(ExportPalette.primary)
    }
}

struct ExportFooter: View {
    let options: ExportOptions
    let data: ExportData

    private var totalForScope: Int {
        switch data.range {
        case .week: return 7
        case .month(_, _, _, let last):
            return Calendar.current.component(.day, from: last)
        case .year(let y, _, _): return DayKey.daysInYear(y)
        }
    }

    var body: some View {
        HStack {
            if options.showWatermark {
                Text("palette")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(ExportPalette.secondary)
            }
            Spacer()
            if options.showDayCount {
                Text(ExportText.dayCount(filled: data.filledCount, total: totalForScope))
                    .font(.system(size: 18, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(ExportPalette.secondary)
            }
        }
    }
}
