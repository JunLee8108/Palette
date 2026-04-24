import Foundation
import SwiftData

public enum WidgetDataReader {
    public static func fetchColors(in range: ClosedRange<Date>) -> [String: String] {
        let cal = Calendar.current
        let lower = cal.startOfDay(for: range.lowerBound)
        let upper = cal.startOfDay(for: range.upperBound)

        do {
            let container = try SharedModelContainer.make(readOnly: true)
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<ColorEntry>(
                predicate: #Predicate<ColorEntry> { entry in
                    entry.date >= lower && entry.date <= upper
                }
            )
            let entries = try context.fetch(descriptor)
            var dict: [String: String] = [:]
            dict.reserveCapacity(entries.count)
            for entry in entries {
                dict[entry.dayKey] = entry.colorHex
            }
            return dict
        } catch {
            return [:]
        }
    }

    public static func fetchColors(year: Int) -> [String: String] {
        let start = DayKey.january1(of: year)
        let end = DayKey.december31(of: year)
        return fetchColors(in: start...end)
    }

    public static func todayColor(on date: Date = Date()) -> String? {
        let day = Calendar.current.startOfDay(for: date)
        return fetchColors(in: day...day)[DayKey.make(for: day)]
    }
}
