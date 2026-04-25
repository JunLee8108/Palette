import SwiftUI
import SwiftData
import PaletteShared
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Enums

enum ExportStyle: String, CaseIterable, Identifiable {
    case grid, stripes, swatch
    var id: String { rawValue }
    var label: String {
        switch self {
        case .grid: return "Grid"
        case .stripes: return "Stripes"
        case .swatch: return "Swatch"
        }
    }
}

enum ExportScope: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }
    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

enum StripesOrientation: String, CaseIterable, Identifiable {
    case horizontal, vertical
    var id: String { rawValue }
    var label: String { self == .horizontal ? "Horizontal" : "Vertical" }
}

enum ExportBackground: String, CaseIterable, Identifiable {
    case cream, white
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .cream: return Color(hex: "#FAF8F3")
        case .white: return .white
        }
    }
    var label: String { self == .cream ? "Cream" : "White" }
}

// MARK: - Options

struct ExportOptions {
    var style: ExportStyle = .grid
    var scope: ExportScope = .month
    var date: Date = Date()
    var firstWeekday: Int = Calendar.current.firstWeekday

    var showHeader: Bool = true
    var showWeekdayLabels: Bool = true
    var showDayCount: Bool = false

    var stripesOrientation: StripesOrientation = .horizontal
    var skipEmpty: Bool = true

    var background: ExportBackground = .cream
    var showWatermark: Bool = true
}

// MARK: - Date range for scope

enum ExportRange {
    case week(start: Date, end: Date)
    case month(year: Int, month: Int, first: Date, last: Date)
    case year(Int, first: Date, last: Date)

    static func from(_ options: ExportOptions) -> ExportRange {
        let cal = Calendar.current
        switch options.scope {
        case .week:
            let today = cal.startOfDay(for: options.date)
            let weekday = cal.component(.weekday, from: today)
            let offset = (weekday - options.firstWeekday + 7) % 7
            let start = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
            return .week(start: start, end: end)
        case .month:
            let year = cal.component(.year, from: options.date)
            let month = cal.component(.month, from: options.date)
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            let first = cal.date(from: comps) ?? options.date
            let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
            let last = cal.date(byAdding: .day, value: days - 1, to: first) ?? first
            return .month(year: year, month: month, first: first, last: last)
        case .year:
            let y = cal.component(.year, from: options.date)
            return .year(y, first: DayKey.january1(of: y), last: DayKey.december31(of: y))
        }
    }

    var closedRange: ClosedRange<Date> {
        switch self {
        case .week(let s, let e): return s...e
        case .month(_, _, let f, let l): return f...l
        case .year(_, let f, let l): return f...l
        }
    }
}

// MARK: - Data

struct ExportData {
    let range: ExportRange
    let dates: [Date]
    let colorsByKey: [String: String]

    var filledCount: Int { colorsByKey.count }

    static func load(options: ExportOptions, context: ModelContext) -> ExportData {
        let range = ExportRange.from(options)
        let cal = Calendar.current

        var dates: [Date] = []
        var cursor = range.closedRange.lowerBound
        while cursor <= range.closedRange.upperBound {
            dates.append(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }

        let lower = cal.startOfDay(for: range.closedRange.lowerBound)
        let upper = cal.startOfDay(for: range.closedRange.upperBound)
        let descriptor = FetchDescriptor<ColorEntry>(
            predicate: #Predicate<ColorEntry> { $0.date >= lower && $0.date <= upper }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        var dict: [String: String] = [:]
        for entry in entries {
            dict[entry.dayKey] = entry.colorHex
        }

        return ExportData(range: range, dates: dates, colorsByKey: dict)
    }
}

// MARK: - Header text

enum ExportText {
    static func header(for options: ExportOptions) -> String {
        let cal = Calendar.current
        let range = ExportRange.from(options)
        switch range {
        case .week(let s, let e):
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "MMM d"
            let yf = DateFormatter()
            yf.locale = Locale(identifier: "en_US_POSIX")
            yf.dateFormat = "yyyy"
            return "\(f.string(from: s).uppercased()) – \(f.string(from: e).uppercased()), \(yf.string(from: e))"
        case .month(let y, let m, _, _):
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "LLLL"
            var comps = DateComponents()
            comps.year = y
            comps.month = m
            comps.day = 1
            let date = cal.date(from: comps) ?? Date()
            return "\(f.string(from: date).uppercased()) \(y)"
        case .year(let y, _, _):
            return String(y)
        }
    }

    static func dayCount(filled: Int, total: Int) -> String {
        "\(filled) / \(total) days"
    }
}

// MARK: - Renderer

#if canImport(UIKit)
@MainActor
enum ExportRenderer {
    static func writePNG<V: View>(_ view: V, size: CGSize, scale: CGFloat = 2) -> URL? {
        let renderer = ImageRenderer(content:
            view.frame(width: size.width, height: size.height)
        )
        renderer.scale = scale
        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("palette-export-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
#endif
