import Foundation
import SwiftData

@Model
public final class ColorEntry {
    public var dayKey: String = ""
    public var date: Date = Date()
    public var colorHex: String = ""
    public var swatchId: String = ""
    public var paletteId: String = "default_v1"
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        dayKey: String,
        date: Date,
        colorHex: String,
        swatchId: String,
        paletteId: String = "default_v1"
    ) {
        self.dayKey = dayKey
        self.date = date
        self.colorHex = colorHex
        self.swatchId = swatchId
        self.paletteId = paletteId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
