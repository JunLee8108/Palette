import Foundation
import SwiftData

@Model
public final class ColorEntry {
    public var dayKey: String = ""
    public var date: Date = Date()
    public var colorHex: String = ""
    public var swatchId: String = ""
    public var paletteId: String = "default_v1"
    public var note: String = ""
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        dayKey: String,
        date: Date,
        colorHex: String,
        swatchId: String,
        paletteId: String = "default_v1",
        note: String = ""
    ) {
        self.dayKey = dayKey
        self.date = date
        self.colorHex = colorHex
        self.swatchId = swatchId
        self.paletteId = paletteId
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
