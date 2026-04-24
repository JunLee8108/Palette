import SwiftUI
import WidgetKit
import PaletteShared

@main
struct PaletteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThisWeekWidget()
        ThisMonthWidget()
        ThisYearWidget()
        TodayCircularWidget()
        RecentDaysRectWidget()
    }
}

// MARK: - Shared

private enum WidgetPalette {
    static let background = Color(hex: "#FAF8F3")
    static let primary = Color(hex: "#2A2620")
    static let secondary = Color(hex: "#7A756E")
    static let tertiary = Color(hex: "#B8B2A7")
    static let emptyFill = Color(hex: "#E8E0D0").opacity(0.6)
}

private struct DayTile: Identifiable {
    let id: String
    let date: Date
    let colorHex: String?
    let isToday: Bool
}

private func recentDayTiles(count: Int, reference: Date = Date()) -> [DayTile] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: reference)
    let dates: [Date] = (0..<count).map { offset in
        cal.date(byAdding: .day, value: -(count - 1 - offset), to: today) ?? today
    }
    guard let first = dates.first, let last = dates.last else { return [] }
    let colors = WidgetDataReader.fetchColors(in: first...last)
    return dates.enumerated().map { idx, date in
        let key = DayKey.make(for: date)
        return DayTile(
            id: key,
            date: date,
            colorHex: colors[key],
            isToday: idx == count - 1
        )
    }
}

private func nextMidnight(after date: Date) -> Date {
    Calendar.current.nextDate(
        after: date,
        matching: DateComponents(hour: 0, minute: 0),
        matchingPolicy: .nextTime
    ) ?? date.addingTimeInterval(60 * 60 * 6)
}

// MARK: - This Week (systemSmall)

struct ThisWeekEntry: TimelineEntry {
    let date: Date
    let days: [DayTile]
}

struct ThisWeekTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThisWeekEntry {
        ThisWeekEntry(date: Date(), days: Self.placeholderDays())
    }

    func getSnapshot(in context: Context, completion: @escaping (ThisWeekEntry) -> Void) {
        completion(ThisWeekEntry(date: Date(), days: recentDayTiles(count: 7)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisWeekEntry>) -> Void) {
        let entry = ThisWeekEntry(date: Date(), days: recentDayTiles(count: 7))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight(after: Date()))))
    }

    private static func placeholderDays() -> [DayTile] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
            let hex: String? = offset == 6 ? nil : DefaultPalette.swatches[offset * 3 % DefaultPalette.swatches.count].hex
            return DayTile(
                id: "placeholder-\(offset)",
                date: date,
                colorHex: hex,
                isToday: offset == 6
            )
        }
    }
}

struct ThisWeekWidget: Widget {
    let kind: String = "ThisWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThisWeekTimelineProvider()) { entry in
            ThisWeekSmallView(entry: entry)
                .containerBackground(WidgetPalette.background, for: .widget)
        }
        .configurationDisplayName("This Week")
        .description("Your last 7 days of color.")
        .supportedFamilies([.systemSmall])
    }
}

struct ThisWeekSmallView: View {
    let entry: ThisWeekEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(WidgetPalette.secondary)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                ForEach(entry.days) { day in
                    WidgetDayTile(day: day)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "palette://today"))
    }
}

struct WidgetDayTile: View {
    let day: DayTile

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            shape(size: size)
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func shape(size: CGFloat) -> some View {
        let radius = size * 0.22
        if let hex = day.colorHex {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(hex: hex))
        } else if day.isToday {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(
                    WidgetPalette.secondary,
                    style: StrokeStyle(lineWidth: 1.2, dash: [2.5, 2])
                )
        } else {
            RoundedRectangle(cornerRadius: radius)
                .fill(WidgetPalette.emptyFill)
        }
    }
}

// MARK: - This Month (systemMedium)

struct ThisMonthEntry: TimelineEntry {
    let date: Date
    let year: Int
    let month: Int
    let firstWeekday: Int
    let colorsByKey: [String: String]
    let filledCount: Int
    let totalDays: Int
}

struct ThisMonthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThisMonthEntry { snapshot() }

    func getSnapshot(in context: Context, completion: @escaping (ThisMonthEntry) -> Void) {
        completion(snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisMonthEntry>) -> Void) {
        completion(Timeline(entries: [snapshot()], policy: .after(nextMidnight(after: Date()))))
    }

    private func snapshot() -> ThisMonthEntry {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let firstOfMonth = cal.date(from: comps) ?? now
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        let lastOfMonth = cal.date(byAdding: .day, value: daysInMonth - 1, to: firstOfMonth) ?? firstOfMonth
        let colors = WidgetDataReader.fetchColors(in: firstOfMonth...lastOfMonth)
        return ThisMonthEntry(
            date: now,
            year: year,
            month: month,
            firstWeekday: cal.firstWeekday,
            colorsByKey: colors,
            filledCount: colors.count,
            totalDays: daysInMonth
        )
    }
}

struct ThisMonthWidget: Widget {
    let kind: String = "ThisMonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThisMonthTimelineProvider()) { entry in
            ThisMonthMediumView(entry: entry)
                .containerBackground(WidgetPalette.background, for: .widget)
        }
        .configurationDisplayName("This Month")
        .description("A calendar view of this month's colors.")
        .supportedFamilies([.systemMedium])
    }
}

struct ThisMonthMediumView: View {
    let entry: ThisMonthEntry

    private var weekdaySymbols: [String] {
        let base = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { base[(entry.firstWeekday - 1 + $0) % 7] }
    }

    private var monthSymbol: String {
        Calendar.current.standaloneMonthSymbols[entry.month - 1]
    }

    private var firstOfMonth: Date {
        var comps = DateComponents()
        comps.year = entry.year
        comps.month = entry.month
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }

    private var startOffset: Int {
        let weekday = Calendar.current.component(.weekday, from: firstOfMonth)
        return (weekday - entry.firstWeekday + 7) % 7
    }

    private var rows: Int {
        Int(ceil(Double(startOffset + entry.totalDays) / 7.0))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(monthSymbol)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetPalette.primary)
                Text("\(entry.filledCount) / \(entry.totalDays)")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(WidgetPalette.secondary)
                Spacer(minLength: 0)
            }
            .frame(width: 70, alignment: .leading)

            GeometryReader { proxy in
                let spacing: CGFloat = 2.5
                let tile = (proxy.size.width - spacing * 6) / 7
                VStack(spacing: 3) {
                    HStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { i in
                            Text(weekdaySymbols[i])
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(WidgetPalette.tertiary)
                                .frame(width: tile)
                        }
                    }

                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { col in
                                    monthCell(row: row, col: col, size: tile)
                                }
                            }
                        }
                    }
                }
            }
        }
        .widgetURL(URL(string: "palette://month"))
    }

    @ViewBuilder
    private func monthCell(row: Int, col: Int, size: CGFloat) -> some View {
        let idx = row * 7 + col
        let dayOfMonth = idx - startOffset + 1
        if dayOfMonth < 1 || dayOfMonth > entry.totalDays {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(byAdding: .day, value: dayOfMonth - 1, to: firstOfMonth) ?? firstOfMonth
            let key = DayKey.make(for: date)
            let hex = entry.colorsByKey[key]
            let isToday = DayKey.isToday(date)
            let radius = size * 0.22
            Group {
                if let hex {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color(hex: hex))
                } else if isToday {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(
                            WidgetPalette.secondary,
                            style: StrokeStyle(lineWidth: 1, dash: [2, 1.5])
                        )
                } else {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(WidgetPalette.emptyFill)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - This Year (systemLarge)

struct ThisYearEntry: TimelineEntry {
    let date: Date
    let year: Int
    let firstWeekday: Int
    let colorsByKey: [String: String]
    let filledCount: Int
    let totalDays: Int
}

struct ThisYearTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThisYearEntry { snapshot() }

    func getSnapshot(in context: Context, completion: @escaping (ThisYearEntry) -> Void) {
        completion(snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisYearEntry>) -> Void) {
        completion(Timeline(entries: [snapshot()], policy: .after(nextMidnight(after: Date()))))
    }

    private func snapshot() -> ThisYearEntry {
        let now = Date()
        let year = DayKey.year(of: now)
        let colors = WidgetDataReader.fetchColors(year: year)
        return ThisYearEntry(
            date: now,
            year: year,
            firstWeekday: Calendar.current.firstWeekday,
            colorsByKey: colors,
            filledCount: colors.count,
            totalDays: DayKey.daysInYear(year)
        )
    }
}

struct ThisYearWidget: Widget {
    let kind: String = "ThisYearWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThisYearTimelineProvider()) { entry in
            ThisYearLargeView(entry: entry)
                .containerBackground(WidgetPalette.background, for: .widget)
        }
        .configurationDisplayName("This Year")
        .description("Every day of the year at a glance.")
        .supportedFamilies([.systemLarge])
    }
}

struct ThisYearLargeView: View {
    let entry: ThisYearEntry

    private var jan1Column: Int {
        let jan1 = DayKey.january1(of: entry.year)
        let weekday = Calendar.current.component(.weekday, from: jan1)
        return (weekday - entry.firstWeekday + 7) % 7
    }

    private var totalRows: Int {
        Int(ceil(Double(jan1Column + entry.totalDays) / 7.0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(entry.year))
                    .font(.system(size: 22, weight: .thin, design: .serif))
                    .tracking(1)
                    .foregroundStyle(WidgetPalette.primary)
                    .monospacedDigit()
                Spacer()
                Text("\(entry.filledCount) / \(entry.totalDays)")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(WidgetPalette.secondary)
            }

            GeometryReader { proxy in
                let spacing: CGFloat = 1.5
                let cell = (proxy.size.height - spacing * 6) / 7
                HStack(spacing: spacing) {
                    ForEach(0..<totalRows, id: \.self) { row in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { col in
                                yearCell(row: row, col: col, size: cell)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .widgetURL(URL(string: "palette://year"))
    }

    @ViewBuilder
    private func yearCell(row: Int, col: Int, size: CGFloat) -> some View {
        let offset = row * 7 + col - jan1Column
        if offset < 0 || offset >= entry.totalDays {
            Color.clear.frame(width: size, height: size)
        } else {
            let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: DayKey.january1(of: entry.year)
            ) ?? Date()
            let key = DayKey.make(for: date)
            let hex = entry.colorsByKey[key]
            let isToday = DayKey.isToday(date)
            let radius = max(1.5, size * 0.25)
            Group {
                if let hex {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color(hex: hex))
                } else if isToday {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(WidgetPalette.secondary, lineWidth: 0.9)
                } else {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(WidgetPalette.emptyFill)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Today Circular (accessoryCircular)

struct TodayCircularEntry: TimelineEntry {
    let date: Date
    let colorHex: String?
}

struct TodayCircularTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayCircularEntry {
        TodayCircularEntry(date: Date(), colorHex: DefaultPalette.swatches.first?.hex)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayCircularEntry) -> Void) {
        completion(snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayCircularEntry>) -> Void) {
        completion(Timeline(entries: [snapshot()], policy: .after(nextMidnight(after: Date()))))
    }

    private func snapshot() -> TodayCircularEntry {
        TodayCircularEntry(date: Date(), colorHex: WidgetDataReader.todayColor())
    }
}

struct TodayCircularWidget: Widget {
    let kind: String = "TodayCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayCircularTimelineProvider()) { entry in
            TodayCircularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("A tap to pick today's color.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct TodayCircularView: View {
    let entry: TodayCircularEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let hex = entry.colorHex {
                Circle()
                    .fill(Color(hex: hex))
                    .padding(4)
                    .widgetAccentable()
            } else {
                Circle()
                    .strokeBorder(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 1.8, dash: [3, 2])
                    )
                    .padding(5)
                    .widgetAccentable()
            }
        }
        .widgetURL(URL(string: "palette://today"))
    }
}

// MARK: - Recent Days Rectangular (accessoryRectangular)

struct RecentDaysRectEntry: TimelineEntry {
    let date: Date
    let days: [DayTile]
}

struct RecentDaysRectTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentDaysRectEntry {
        RecentDaysRectEntry(date: Date(), days: recentDayTiles(count: 5))
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentDaysRectEntry) -> Void) {
        completion(RecentDaysRectEntry(date: Date(), days: recentDayTiles(count: 5)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentDaysRectEntry>) -> Void) {
        let entry = RecentDaysRectEntry(date: Date(), days: recentDayTiles(count: 5))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight(after: Date()))))
    }
}

struct RecentDaysRectWidget: Widget {
    let kind: String = "RecentDaysRectWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentDaysRectTimelineProvider()) { entry in
            RecentDaysRectView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recent Days")
        .description("Your last 5 days of color.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct RecentDaysRectView: View {
    let entry: RecentDaysRectEntry

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("PALETTE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .widgetAccentable()

            HStack(spacing: 3) {
                ForEach(entry.days) { day in
                    tile(for: day)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "palette://today"))
    }

    @ViewBuilder
    private func tile(for day: DayTile) -> some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let radius = side * 0.22
            ZStack {
                if let hex = day.colorHex {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color(hex: hex))
                        .widgetAccentable()
                } else if day.isToday {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(
                            Color.primary,
                            style: StrokeStyle(lineWidth: 1.2, dash: [2, 1.5])
                        )
                        .widgetAccentable()
                } else {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(Color.primary.opacity(0.4), lineWidth: 0.8)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
