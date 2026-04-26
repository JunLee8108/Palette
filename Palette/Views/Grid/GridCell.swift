import SwiftUI
import PaletteShared

struct GridCell: View {
    let size: CGFloat
    let colorHex: String?
    let isToday: Bool
    let isInYear: Bool

    private var radius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            if let hex = colorHex {
                ColorTile(color: Color(hex: hex), size: size, flat: true)
            } else if isInYear {
                emptySlot

                if isToday {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(
                            PaletteTheme.secondaryText.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1, dash: [2.5, 2.5])
                        )
                        .frame(width: size, height: size)
                        .allowsHitTesting(false)
                }
            } else {
                Color.clear.frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(PaletteTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 0.5)
            )
            .frame(width: size, height: size)
    }
}

// MARK: - Accessibility helpers shared by week / month / year boards

enum CellAccessibility {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMMd")
        return f
    }()

    static func label(date: Date, isToday: Bool) -> String {
        let dateString = dateFormatter.string(from: date)
        if isToday {
            return L10n.t("Today, \(dateString)", "오늘, \(dateString)")
        }
        return dateString
    }

    static func value(hasEntry: Bool) -> String {
        hasEntry
            ? L10n.t("Color set", "색 있음")
            : L10n.t("No color", "색 없음")
    }

    static func hint(date: Date, hasEntry: Bool) -> String {
        if ColorStore.isFuture(date) { return "" }
        return hasEntry
            ? L10n.t("Change color", "색 바꾸기")
            : L10n.t("Pick a color", "색 고르기")
    }
}

#Preview {
    HStack(spacing: 6) {
        GridCell(size: 40, colorHex: "#E8594A", isToday: false, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: true, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: false, isInYear: true)
        GridCell(size: 40, colorHex: nil, isToday: false, isInYear: false)
    }
    .padding()
    .background(PaletteTheme.background)
}
