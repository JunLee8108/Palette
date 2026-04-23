import Foundation
import SwiftData

@Model
final class ColorEntry {
    var dayKey: String = ""
    var date: Date = Date()
    var colorHex: String = ""
    var swatchId: String = ""
    var paletteId: String = "default_v1"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
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
