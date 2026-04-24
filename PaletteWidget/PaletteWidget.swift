import SwiftUI
import WidgetKit
import PaletteShared

@main
struct PaletteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThisWeekWidget()
        ThisMonthWidget()
    }
}

// MARK: - Shared

enum WidgetPalette {
    static let background = Color(hex: "#FAF8F3")
    static let primary = Color(hex: "#2A2620")
    static let secondary = Color(hex: "#7A756E")
    static let tertiary = Color(hex: "#B8B2A7")
    static let emptyFill = Color(hex: "#E8E0D0").opacity(0.6)
}

struct DayTile: Identifiable {
    let id: String
    let date: Date
    let colorHex: String?
    let isToday: Bool
}

func currentWeekTiles(firstWeekday: Int = Calendar.current.firstWeekday, reference: Date = Date()) -> [DayTile] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: reference)
    let todayWeekday = cal.component(.weekday, from: today)
    let offsetFromWeekStart = (todayWeekday - firstWeekday + 7) % 7
    let weekStart = cal.date(byAdding: .day, value: -offsetFromWeekStart, to: today) ?? today

    let dates: [Date] = (0..<7).map { offset in
        cal.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
    }
    guard let first = dates.first, let last = dates.last else { return [] }
    let colors = WidgetDataReader.fetchColors(in: first...last)
    return dates.map { date in
        let key = DayKey.make(for: date)
        return DayTile(
            id: key,
            date: date,
            colorHex: colors[key],
            isToday: cal.isDate(date, inSameDayAs: today)
        )
    }
}

func nextMidnight(after date: Date) -> Date {
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
        completion(ThisWeekEntry(date: Date(), days: currentWeekTiles()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisWeekEntry>) -> Void) {
        let entry = ThisWeekEntry(date: Date(), days: currentWeekTiles())
        completion(Timeline(entries: [entry], policy: .after(nextMidnight(after: Date()))))
    }

    private static func placeholderDays() -> [DayTile] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today)
        let offsetFromWeekStart = (todayWeekday - cal.firstWeekday + 7) % 7
        let weekStart = cal.date(byAdding: .day, value: -offsetFromWeekStart, to: today) ?? today

        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let isPastOrToday = offset <= offsetFromWeekStart
            let hex: String? = isPastOrToday ? DefaultPalette.swatches[offset * 3 % DefaultPalette.swatches.count].hex : nil
            return DayTile(
                id: "placeholder-\(offset)",
                date: date,
                colorHex: hex,
                isToday: offset == offsetFromWeekStart
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
        .description("Your current week of color.")
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
        .widgetURL(URL(string: "palette://week"))
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
