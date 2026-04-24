import SwiftUI
import WidgetKit
import PaletteShared

@main
struct PaletteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThisWeekWidget()
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
