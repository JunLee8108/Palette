import SwiftUI
import SwiftData
import PaletteShared
#if canImport(UIKit)
import UIKit
#endif

struct DayDetailSheet: View {
    let date: Date
    let entry: ColorEntry?
    var onChanged: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var page: Page = .detail
    @State private var detent: PresentationDetent = .height(400)
    @State private var measuredHeight: CGFloat? = nil
    @State private var selectedSwatchId: String? = nil
    @State private var pendingColorHex: String? = nil
    @State private var showChangeWarning: Bool = false
    @State private var showClearWarning: Bool = false
    @State private var entryWasCleared: Bool = false

    private enum Page { case detail, palette }

    private static let tileSize: CGFloat = 120
    private static let paletteSheetHeight: CGFloat = 460
    private static let pageTransition: Animation = .spring(response: 0.45, dampingFraction: 0.86)
    private static let contentTransition: AnyTransition = .asymmetric(
        insertion: .opacity.animation(.easeIn(duration: 0.22).delay(0.18)),
        removal: .opacity.animation(.easeOut(duration: 0.18))
    )

    init(date: Date, entry: ColorEntry?, onChanged: @escaping () -> Void = {}) {
        self.date = date
        self.entry = entry
        self.onChanged = onChanged
        _detent = State(initialValue: .height(Self.detailHeight(date: date, entry: entry)))
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("yMMMMd")
        return f
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f
    }

    private var isToday: Bool { DayKey.isToday(date) }
    private var isFuture: Bool { ColorStore.isFuture(date) }
    private var effectiveEntry: ColorEntry? { entryWasCleared ? nil : entry }
    private var displayColorHex: String? { pendingColorHex ?? effectiveEntry?.colorHex }
    private var needsOverrideConfirmation: Bool {
        ColorStore.requiresOverrideConfirmation(for: date, hasEntry: effectiveEntry != nil)
    }
    private var hasActions: Bool {
        ColorStore.canPickColor(for: date, hasEntry: effectiveEntry != nil)
            || (ColorStore.canDelete(for: date) && effectiveEntry != nil)
    }

    private var detailHeight: CGFloat {
        Self.detailHeight(date: date, entry: effectiveEntry)
    }

    private static func detailHeight(date: Date, entry: ColorEntry?) -> CGFloat {
        let hasEntry = entry != nil
        let hasStatus = ColorStore.isFuture(date) || !hasEntry
        let canPick = ColorStore.canPickColor(for: date, hasEntry: hasEntry)
        let canDelete = ColorStore.canDelete(for: date) && hasEntry
        let buttonCount = (canPick ? 1 : 0) + (canDelete ? 1 : 0)

        let topPad: CGFloat = 30
        let tileToDate: CGFloat = 28
        let dateText: CGFloat = 28
        let statusBlock: CGFloat = hasStatus ? 26 : 0
        let dateToActions: CGFloat = buttonCount > 0 ? 28 : 0
        let buttonH: CGFloat = 52
        let buttonGap: CGFloat = 12
        let bottomPad: CGFloat = 20

        let actionsH: CGFloat = buttonCount > 0
            ? CGFloat(buttonCount) * buttonH + CGFloat(max(0, buttonCount - 1)) * buttonGap
            : 0

        return topPad + tileSize + tileToDate + dateText + statusBlock + dateToActions + actionsH + bottomPad
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch page {
            case .detail:
                detailContent.transition(Self.contentTransition)
            case .palette:
                paletteContent.transition(Self.contentTransition)
            }
        }
        .frame(maxWidth: .infinity)
        .selfSizingDetent(
            selection: $detent,
            measured: $measuredHeight,
            additional: [.height(Self.paletteSheetHeight)],
            initialEstimate: detailHeight
        )
        .onChange(of: measuredHeight) { _, newValue in
            guard page != .palette, let newValue else { return }
            withAnimation(Self.pageTransition) {
                detent = .height(newValue)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(PaletteTheme.background)
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedSwatchId)
        .alert(
            L10n.t("Change this day's color?", "이 날의 색을 바꾸시겠어요?"),
            isPresented: $showChangeWarning
        ) {
            Button(L10n.t("Keep it", "그대로 두기"), role: .cancel) {}
            Button(L10n.t("Change", "바꾸기"), role: .destructive) {
                openPalette()
            }
        } message: {
            Text(L10n.t(
                "This color is this day's unique record. We suggest keeping it. Change anyway?",
                "이 색은 이날 하루를 기록한 유니크한 색이에요. 가능하면 그대로 두시길 추천드리지만, 정말 바꾸시겠어요?"
            ))
        }
        .alert(
            L10n.t("Clear this day's color?", "이 날의 색을 지우시겠어요?"),
            isPresented: $showClearWarning
        ) {
            Button(L10n.t("Keep it", "그대로 두기"), role: .cancel) {}
            Button(L10n.t("Clear", "지우기"), role: .destructive) {
                clearEntry()
            }
        } message: {
            Text(L10n.t(
                "This color is this day's unique record. We suggest keeping it. Clear anyway?",
                "이 색은 이날 하루를 기록한 유니크한 색이에요. 가능하면 그대로 두시길 추천드리지만, 정말 지우시겠어요?"
            ))
        }
    }

    // MARK: - Detail page

    private var detailContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)

            currentTile

            Spacer().frame(height: 28)

            VStack(spacing: 8) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(PaletteTheme.primaryText)

                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(PaletteTheme.secondaryText)
                }
            }

            if hasActions {
                Spacer().frame(height: 28)

                actionButtons
                    .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private var currentTile: some View {
        let canPick = ColorStore.canPickColor(for: date, hasEntry: effectiveEntry != nil)
        if canPick {
            Button(action: handlePickTap) {
                tileVisual
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(pickLabel)
        } else {
            tileVisual
        }
    }

    @ViewBuilder
    private var tileVisual: some View {
        if let hex = displayColorHex {
            ColorTile(color: Color(hex: hex), size: Self.tileSize)
        } else if isToday {
            ColorTile(color: .clear, size: Self.tileSize, isEmpty: true)
        } else {
            RoundedRectangle(cornerRadius: Self.tileSize * 0.22)
                .fill(PaletteTheme.surface)
                .frame(width: Self.tileSize, height: Self.tileSize)
                .overlay(
                    RoundedRectangle(cornerRadius: Self.tileSize * 0.22)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        let canPick = ColorStore.canPickColor(for: date, hasEntry: effectiveEntry != nil)
        let canDelete = ColorStore.canDelete(for: date) && effectiveEntry != nil

        if canPick || canDelete {
            VStack(spacing: 12) {
                if canDelete {
                    Button(action: handleClearTap) {
                        actionLabel(clearLabel, primary: false)
                    }
                    .buttonStyle(.plain)
                }

                if canPick {
                    Button(action: handlePickTap) {
                        actionLabel(pickLabel, primary: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var pickLabel: String {
        if effectiveEntry != nil {
            return L10n.t("Change color", "색 바꾸기")
        }
        if isToday {
            return L10n.t("Pick today's color", "오늘의 색 고르기")
        }
        return L10n.t("Pick a color", "색 고르기")
    }

    private var clearLabel: String {
        if isToday {
            return L10n.t("Clear today", "오늘 색 지우기")
        }
        return L10n.t("Clear color", "색 지우기")
    }

    private var statusText: String {
        if isFuture {
            return L10n.t("Not yet.", "아직이에요.")
        }
        if effectiveEntry == nil {
            if isToday {
                return L10n.t("No color picked yet.", "아직 색을 고르지 않았어요.")
            }
            return L10n.t("A missed day you can still color.", "놓친 날, 지금도 채울 수 있어요.")
        }
        return ""
    }

    private func actionLabel(_ text: String, primary: Bool) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(primary ? PaletteTheme.background : PaletteTheme.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(primary ? PaletteTheme.primaryText : PaletteTheme.surface)
            )
            .overlay(
                primary
                ? nil
                : RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
    }

    // MARK: - Palette page

    private var paletteContent: some View {
        VStack(spacing: 16) {
            paletteHeader

            Spacer(minLength: 24)

            PaletteGrid(
                swatches: DefaultPalette.swatches,
                selectedId: selectedSwatchId ?? effectiveEntry?.swatchId,
                onSelect: handleSelect
            )
            .padding(.horizontal, 28)

            Spacer(minLength: 24)
        }
    }

    private var paletteHeader: some View {
        HStack {
            Button(action: closePalette) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L10n.t("Back", "뒤로"))
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundStyle(PaletteTheme.secondaryText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(shortDateFormatter.string(from: date))
                .font(.system(size: 13, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(PaletteTheme.tertiaryText)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Actions

    private func handlePickTap() {
        if needsOverrideConfirmation {
            showChangeWarning = true
        } else {
            openPalette()
        }
    }

    private func handleClearTap() {
        if needsOverrideConfirmation {
            showClearWarning = true
        } else {
            clearEntry()
        }
    }

    private func openPalette() {
        withAnimation(Self.pageTransition) {
            page = .palette
            detent = .height(Self.paletteSheetHeight)
        }
    }

    private func closePalette() {
        // The current measured height belongs to the palette content; if we
        // reuse it as the detent, the sheet barely shrinks. Drop it so the
        // modifier falls back to detailHeight as the initial estimate, then
        // onChange refines once the detail page actually renders.
        measuredHeight = nil
        withAnimation(Self.pageTransition) {
            page = .detail
            detent = .height(detailHeight)
        }
    }

    private func clearEntry() {
        ColorStore.delete(for: date, in: context)
        // Don't call onChanged() — the parent uses it as a "close sheet"
        // signal. The calendar grid is backed by a @Query that updates
        // from the SwiftData delete on its own, so we can safely keep
        // this sheet open and morph its content in place.
        let postClearHeight = Self.detailHeight(date: date, entry: nil)
        withAnimation(Self.pageTransition) {
            entryWasCleared = true
            pendingColorHex = nil
            selectedSwatchId = nil
            detent = .height(postClearHeight)
            measuredHeight = postClearHeight
        }
    }

    private func handleSelect(_ swatch: PaletteSwatch) {
        selectedSwatchId = swatch.id
        pendingColorHex = swatch.hex

        ColorStore.upsert(swatch: swatch, for: date, in: context)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            onChanged()
            dismiss()
        }
    }
}

#Preview("today, empty") {
    DayDetailSheet(date: Date(), entry: nil)
        .frame(height: 520)
        .background(PaletteTheme.background)
        .modelContainer(for: ColorEntry.self, inMemory: true)
}

#Preview("past, no color") {
    DayDetailSheet(
        date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        entry: nil
    )
    .frame(height: 520)
    .background(PaletteTheme.background)
    .modelContainer(for: ColorEntry.self, inMemory: true)
}
