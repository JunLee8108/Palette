import Foundation

enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func make(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    static func year(of date: Date) -> Int {
        Calendar.current.component(.year, from: date)
    }

    static func january1(of year: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = 1
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }

    static func december31(of year: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = 12
        comps.day = 31
        return Calendar.current.date(from: comps) ?? Date()
    }

    static func daysInYear(_ year: Int) -> Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .year, for: january1(of: year))
        return range?.count ?? 365
    }
}
