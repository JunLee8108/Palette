import SwiftUI
import SwiftData

struct DayDetailSheet: View {
    let date: Date
    let entry: ColorEntry?
    var onChanged: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("yMMMMd")
        return f
    }

    private var isToday: Bool { DayKey.isToday(date) }
    private var isFuture: Bool { date > Date() && !isToday }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 8)

            if let entry {
                ColorTile(color: Color(hex: entry.colorHex), size: 140)
            } else if isToday {
                ColorTile(color: .clear, size: 140, isEmpty: true)
            } else {
                RoundedRectangle(cornerRadius: 140 * 0.22)
                    .fill(PaletteTheme.surface)
                    .frame(width: 140, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 140 * 0.22)
                            .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                    )
            }

            VStack(spacing: 6) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(PaletteTheme.primaryText)

                Text(statusText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
            }

            Spacer()

            if isToday {
                VStack(spacing: 10) {
                    if entry != nil {
                        Button(action: deleteToday) {
                            Text(L10n.t("Clear today", "오늘 색 지우기"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PaletteTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(PaletteTheme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        dismiss()
                        onChanged()
                    } label: {
                        Text(entry == nil
                             ? L10n.t("Pick today's color", "오늘의 색 고르기")
                             : L10n.t("Change color", "색 바꾸기"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PaletteTheme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(PaletteTheme.primaryText)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusText: String {
        if isFuture {
            return L10n.t("Not yet.", "아직이에요.")
        }
        if entry == nil {
            return isToday
                ? L10n.t("No color picked yet.", "아직 색을 고르지 않았어요.")
                : L10n.t("No color on this day.", "이 날엔 색이 없어요.")
        }
        return ""
    }

    private func deleteToday() {
        ColorStore.deleteToday(in: context)
        dismiss()
        onChanged()
    }
}

#Preview("today, empty") {
    DayDetailSheet(date: Date(), entry: nil)
        .frame(height: 420)
        .background(PaletteTheme.background)
        .modelContainer(for: ColorEntry.self, inMemory: true)
}

#Preview("past, no color") {
    DayDetailSheet(
        date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        entry: nil
    )
    .frame(height: 420)
    .background(PaletteTheme.background)
    .modelContainer(for: ColorEntry.self, inMemory: true)
}
