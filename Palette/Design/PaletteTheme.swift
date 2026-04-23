import SwiftUI

enum PaletteTheme {
    static let background = Color(hex: "#FAF8F3")
    static let surface = Color(hex: "#F5F2EB")
    static let primaryText = Color(hex: "#2A2824")
    static let secondaryText = Color(hex: "#7A756E")
    static let tertiaryText = Color(hex: "#C8BBA8")
    static let hairline = Color(hex: "#E8E0D0")
    static let accent = Color(hex: "#2A2824")
}

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)
        let r, g, b, a: Double
        switch trimmed.count {
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
