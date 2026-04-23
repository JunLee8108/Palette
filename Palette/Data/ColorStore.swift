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
    static func upsert(
        swatch: PaletteSwatch,
        for date: Date,
        in context: ModelContext
    ) -> ColorEntry {
        let key = DayKey.make(for: date)

        if let existing = entry(for: date, in: context) {
            existing.colorHex = swatch.hex
            existing.swatchId = swatch.id
            existing.paletteId = DefaultPalette.id
            existing.updatedAt = Date()
            try? context.save()
            return existing
        }

        let entry = ColorEntry(
            dayKey: key,
            date: DayKey.startOfDay(date),
            colorHex: swatch.hex,
            swatchId: swatch.id,
            paletteId: DefaultPalette.id
        )
        context.insert(entry)
        try? context.save()
        return entry
    }

    @discardableResult
    static func upsertToday(
        swatch: PaletteSwatch,
        in context: ModelContext
    ) -> ColorEntry {
        upsert(swatch: swatch, for: Date(), in: context)
    }

    static func delete(for date: Date, in context: ModelContext) {
        guard let entry = entry(for: date, in: context) else { return }
        context.delete(entry)
        try? context.save()
    }

    static func deleteToday(in context: ModelContext) {
        delete(for: Date(), in: context)
    }

    // MARK: Rules (Option B)
    //
    // - Future: always read-only.
    // - Today: always editable (pick, change, delete).
    // - Past + empty: can pick a color.
    // - Past + already has a color: read-only (preserves record integrity).

    static func isFuture(_ date: Date) -> Bool {
        DayKey.startOfDay(date) > DayKey.startOfDay(Date())
    }

    static func canPickColor(for date: Date, hasEntry: Bool) -> Bool {
        if isFuture(date) { return false }
        if DayKey.isToday(date) { return true }
        return !hasEntry
    }

    static func canDelete(for date: Date) -> Bool {
        DayKey.isToday(date)
    }
}
