import SwiftUI
import SwiftData
import WidgetKit
import PaletteShared

@main
struct PaletteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThisWeekWidget()
    }
}

// MARK: - This Week Widget

struct ThisWeekEntry: TimelineEntry {
    let date: Date
    let days: [DayTile]
}

struct DayTile: Identifiable {
    let id: String
    let date: Date
    let colorHex: String?
    let isToday: Bool
}

struct ThisWeekTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThisWeekEntry {
        ThisWeekEntry(date: Date(), days: Self.placeholderDays())
    }

    func getSnapshot(in context: Context, completion: @escaping (ThisWeekEntry) -> Void) {
        completion(fetchEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisWeekEntry>) -> Void) {
        let entry = fetchEntry(at: Date())
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60 * 6)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func fetchEntry(at now: Date) -> ThisWeekEntry {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let dates: [Date] = (0..<7).map { offset in
            cal.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
        }
        let dayKeys = dates.map { DayKey.make(for: $0) }
        let colorsByKey = colorMap(for: dayKeys)

        let days = dates.enumerated().map { idx, date -> DayTile in
            let key = DayKey.make(for: date)
            return DayTile(
                id: key,
                date: date,
                colorHex: colorsByKey[key],
                isToday: idx == 6
            )
        }
        return ThisWeekEntry(date: now, days: days)
    }

    private func colorMap(for keys: [String]) -> [String: String] {
        do {
            let container = try SharedModelContainer.make(readOnly: true)
            let context = ModelContext(container)
            let keySet = Set(keys)
            let descriptor = FetchDescriptor<ColorEntry>(
                predicate: #Predicate<ColorEntry> { keySet.contains($0.dayKey) }
            )
            let entries = try context.fetch(descriptor)
            var dict: [String: String] = [:]
            for entry in entries {
                dict[entry.dayKey] = entry.colorHex
            }
            return dict
        } catch {
            return [:]
        }
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
                .containerBackground(Color(hex: "#FAF8F3"), for: .widget)
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
                .foregroundStyle(Color(hex: "#7A756E"))
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
                    Color(hex: "#7A756E"),
                    style: StrokeStyle(lineWidth: 1.2, dash: [2.5, 2])
                )
        } else {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(hex: "#E8E0D0").opacity(0.6))
        }
    }
}
