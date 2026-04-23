import Foundation
import SwiftData

enum ColorStore {
    static func entry(for date: Date, in context: ModelContext) -> ColorEntry? {
        let key = DayKey.make(for: date)
        let descriptor = FetchDescriptor<ColorEntry>(
            predicate: #Predicate { $0.dayKey == key }
        )
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    static func upsertToday(
        swatch: PaletteSwatch,
        in context: ModelContext
    ) -> ColorEntry {
        let now = Date()
        let key = DayKey.make(for: now)

        if let existing = entry(for: now, in: context) {
            existing.colorHex = swatch.hex
            existing.swatchId = swatch.id
            existing.paletteId = DefaultPalette.id
            existing.updatedAt = Date()
            try? context.save()
            return existing
        }

        let entry = ColorEntry(
            dayKey: key,
            date: DayKey.startOfDay(now),
            colorHex: swatch.hex,
            swatchId: swatch.id,
            paletteId: DefaultPalette.id
        )
        context.insert(entry)
        try? context.save()
        return entry
    }

    static func deleteToday(in context: ModelContext) {
        guard let entry = entry(for: Date(), in: context) else { return }
        context.delete(entry)
        try? context.save()
    }

    static func canEdit(_ date: Date) -> Bool {
        DayKey.isToday(date)
    }
}
