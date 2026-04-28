import SwiftUI
import SwiftData
import PhotosUI
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
    @State private var detent: PresentationDetent
    @State private var selectedSwatchId: String? = nil
    @State private var pendingColorHex: String? = nil
    @State private var showChangeWarning: Bool = false
    @State private var showClearWarning: Bool = false
    @State private var photoSelection: PhotosPickerItem? = nil
    @State private var photoImage: UIImage? = nil
    @State private var candidateSwatches: [PaletteSwatch] = []
    @State private var photoLoadFailed: Bool = false
    @State private var showFullPhoto: Bool = false
    @State private var thumbFrame: CGRect = .zero

    private enum Page { case detail, palette, preview }

    private static let tileSize: CGFloat = 120
    private static let candidateCount: Int = 5
    private static let candidateTileSize: CGFloat = 56
    private static let candidateSpacing: CGFloat = 10

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
    private var displayColorHex: String? { pendingColorHex ?? entry?.colorHex }
    private var needsOverrideConfirmation: Bool {
        ColorStore.requiresOverrideConfirmation(for: date, hasEntry: entry != nil)
    }
    private var hasActions: Bool {
        ColorStore.canPickColor(for: date, hasEntry: entry != nil)
            || (ColorStore.canDelete(for: date) && entry != nil)
    }

    private var detailHeight: CGFloat {
        Self.detailHeight(date: date, entry: entry)
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
        ZStack {
            switch page {
            case .detail:
                detailContent.transition(.opacity)
            case .palette:
                paletteContent.transition(.opacity)
            case .preview:
                previewContent.transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: page)
        .presentationDetents([.height(detailHeight), .large], selection: $detent)
        .presentationDragIndicator(showFullPhoto ? .hidden : .visible)
        .presentationBackground(PaletteTheme.background)
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedSwatchId)
        .onChange(of: photoSelection) { _, newItem in
            guard let newItem else { return }
            Task { await processPhoto(item: newItem) }
        }
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
        let canPick = ColorStore.canPickColor(for: date, hasEntry: entry != nil)
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
        let canPick = ColorStore.canPickColor(for: date, hasEntry: entry != nil)
        let canDelete = ColorStore.canDelete(for: date) && entry != nil

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
        if entry != nil {
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
        if entry == nil {
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

            Spacer(minLength: 4)

            PaletteGrid(
                swatches: DefaultPalette.swatches,
                selectedId: selectedSwatchId ?? entry?.swatchId,
                onSelect: handleSelect
            )
            .padding(.horizontal, 28)

            photoEntryLink

            Spacer(minLength: 16)
        }
    }

    private var photoEntryLink: some View {
        PhotosPicker(
            selection: $photoSelection,
            matching: .images,
            photoLibrary: .shared()
        ) {
            captionLabel(L10n.t("From a photo", "사진에서"))
        }
        .buttonStyle(.plain)
    }

    private func captionLabel(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(PaletteTheme.hairline)
                .frame(width: 32, height: 1)
            Text(text)
                .font(.system(size: 12, weight: .regular))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(PaletteTheme.tertiaryText)
            Rectangle()
                .fill(PaletteTheme.hairline)
                .frame(width: 32, height: 1)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
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

    // MARK: - Preview page

    private var previewContent: some View {
        VStack(spacing: 0) {
            previewHeader

            Spacer().frame(height: 28)

            photoThumb

            Spacer().frame(height: 28)

            candidatesRow

            Spacer().frame(height: 28)

            rePickPhotoLink

            Spacer(minLength: 24)
        }
        .fullScreenCover(isPresented: $showFullPhoto) {
            if let image = photoImage {
                PhotoFullScreenView(image: image, sourceFrame: thumbFrame) {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { showFullPhoto = false }
                }
            }
        }
    }

    private var previewHeader: some View {
        HStack {
            Button(action: closePreview) {
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

    @ViewBuilder
    private var photoThumb: some View {
        if let image = photoImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                        .opacity(showFullPhoto ? 0 : 1)
                )
                .shadow(color: .black.opacity(showFullPhoto ? 0 : 0.06), radius: 4, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .opacity(showFullPhoto ? 0 : 1)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { thumbFrame = geo.frame(in: .global) }
                            .onChange(of: geo.frame(in: .global)) { _, newValue in
                                thumbFrame = newValue
                            }
                    }
                )
                .onTapGesture {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { showFullPhoto = true }
                }
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(PaletteTheme.surface)
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                )
        }
    }

    private var candidatesRow: some View {
        HStack(spacing: Self.candidateSpacing) {
            ForEach(0..<Self.candidateCount, id: \.self) { index in
                if index < candidateSwatches.count {
                    let swatch = candidateSwatches[index]
                    PressableTile(
                        color: swatch.color,
                        size: Self.candidateTileSize,
                        isSelected: selectedSwatchId == swatch.id,
                        action: { handleSelect(swatch) }
                    )
                } else {
                    placeholderTile
                }
            }
        }
    }

    private var placeholderTile: some View {
        RoundedRectangle(cornerRadius: Self.candidateTileSize * 0.22)
            .fill(PaletteTheme.surface)
            .frame(width: Self.candidateTileSize, height: Self.candidateTileSize)
            .overlay(
                RoundedRectangle(cornerRadius: Self.candidateTileSize * 0.22)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var rePickPhotoLink: some View {
        if photoLoadFailed {
            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text(L10n.t("Couldn't read · Try another", "읽지 못했어요 · 다른 사진"))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                captionLabel(L10n.t("Another photo", "다른 사진"))
            }
            .buttonStyle(.plain)
        }
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
        withAnimation(.easeInOut(duration: 0.3)) {
            detent = .large
            page = .palette
        }
    }

    private func closePalette() {
        withAnimation(.easeInOut(duration: 0.3)) {
            detent = .height(detailHeight)
            page = .detail
        }
    }

    private func closePreview() {
        photoImage = nil
        candidateSwatches = []
        photoLoadFailed = false
        showFullPhoto = false
        withAnimation(.easeInOut(duration: 0.3)) {
            detent = .large
            page = .palette
        }
    }

    @MainActor
    private func processPhoto(item: PhotosPickerItem) async {
        photoLoadFailed = false
        if page != .preview {
            withAnimation(.easeInOut(duration: 0.3)) {
                detent = .large
                page = .preview
            }
        } else {
            photoImage = nil
            candidateSwatches = []
        }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            photoSelection = nil
            photoLoadFailed = true
            return
        }

        photoImage = UIImage(data: data)

        let buckets = await ColorExtractor.extract(from: data)
        let matches = SwatchMatcher.top(Self.candidateCount, from: buckets, in: DefaultPalette.swatches)

        withAnimation(.easeInOut(duration: 0.2)) {
            candidateSwatches = matches
        }

        if matches.isEmpty { photoLoadFailed = true }
        photoSelection = nil
    }

    private func clearEntry() {
        ColorStore.delete(for: date, in: context)
        onChanged()
        dismiss()
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

private struct PhotoFullScreenView: View {
    let image: UIImage
    let sourceFrame: CGRect
    var onClose: () -> Void

    @State private var presented: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isPinching: Bool = false
    @State private var controlsVisible: Bool = false

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    private let heroAnimation: Animation = .spring(response: 0.42, dampingFraction: 0.86)
    private let heroDuration: TimeInterval = 0.42

    private func fittedSize(in container: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0,
              container.width > 0, container.height > 0 else { return .zero }
        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height
        if imageAspect > containerAspect {
            let w = container.width
            return CGSize(width: w, height: w / imageAspect)
        } else {
            let h = container.height
            return CGSize(width: h * imageAspect, height: h)
        }
    }

    private func clampOffset(_ proposed: CGSize, container: CGSize, scale: CGFloat) -> CGSize {
        let fitted = fittedSize(in: container)
        let scaledW = fitted.width * scale
        let scaledH = fitted.height * scale
        let maxX = max(0, (scaledW - container.width) / 2)
        let maxY = max(0, (scaledH - container.height) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func magnification(container: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                isPinching = true
                let proposed = lastScale * value
                scale = min(max(proposed, minScale * 0.8), maxScale)
                offset = clampOffset(offset, container: container, scale: scale)
            }
            .onEnded { _ in
                isPinching = false
                let clamped = min(max(scale, minScale), maxScale)
                let clampedOffset = clamped == minScale
                    ? .zero
                    : clampOffset(offset, container: container, scale: clamped)
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = clamped
                    offset = clampedOffset
                }
                lastScale = clamped
                lastOffset = clampedOffset
            }
    }

    private func drag(container: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isPinching, scale > minScale else { return }
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampOffset(proposed, container: container, scale: scale)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func handleClose() {
        if scale > minScale {
            withAnimation(.easeOut(duration: 0.18)) {
                scale = minScale
                offset = .zero
            }
            lastScale = minScale
            lastOffset = .zero
        }
        withAnimation(.easeOut(duration: 0.15)) { controlsVisible = false }
        withAnimation(heroAnimation) {
            presented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + heroDuration) {
            onClose()
        }
    }

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            let safeSource = sourceFrame == .zero
                ? CGRect(x: screen.width / 2, y: screen.height / 2, width: 1, height: 1)
                : sourceFrame
            let imageSize = aspectFitSize(for: image.size, in: screen)
            let targetCenter = CGPoint(x: screen.width / 2, y: screen.height / 2)

            let currentSize = presented ? imageSize : CGSize(width: safeSource.width, height: safeSource.height)
            let currentCenter = presented
                ? targetCenter
                : CGPoint(x: safeSource.midX, y: safeSource.midY)
            let currentCorner: CGFloat = presented ? 0 : 14

            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(presented ? 1 : 0)

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: currentSize.width, height: currentSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: currentCorner))
                    .scaleEffect(scale)
                    .offset(offset)
                    .position(x: currentCenter.x, y: currentCenter.y)
                    .gesture(magnification(container: screen))
                    .simultaneousGesture(drag(container: screen))
                    .onTapGesture(count: 2) {
                        guard presented else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if scale > minScale {
                                scale = minScale
                                offset = .zero
                            } else {
                                scale = 2.5
                            }
                        }
                        lastScale = scale
                        lastOffset = offset
                    }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: handleClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.45), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
                .opacity(presented ? 1 : 0)
            }
            .ignoresSafeArea()
        }
        .statusBarHidden()
        .onAppear {
            withAnimation(heroAnimation) {
                presented = true
            }
        }
    }

    private func aspectFitSize(for imageSize: CGSize, in container: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let ratio = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
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
