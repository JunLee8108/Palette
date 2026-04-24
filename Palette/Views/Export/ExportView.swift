import SwiftUI
import SwiftData
import PaletteShared

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var options: ExportOptions
    @State private var shareURL: URL? = nil
    @State private var isRendering: Bool = false
    @State private var saveStatus: SaveStatus = .idle
    @State private var showSettingsAlert: Bool = false
    @State private var saveErrorMessage: String? = nil

    private enum SaveStatus: Equatable {
        case idle, saving, saved, failed
    }

    init(initialScope: ExportScope = .month) {
        var opts = ExportOptions()
        opts.scope = initialScope
        opts.firstWeekday = Calendar.current.firstWeekday
        _options = State(initialValue: opts)
    }

    private var data: ExportData {
        ExportData.load(options: options, context: context)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PaletteTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    preview
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    dateNavigator
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    ScrollView {
                        optionsPanel
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 120)
                    }
                    .scrollIndicators(.hidden)
                }

                bottomBar
            }
            .navigationTitle(L10n.t("Export", "내보내기"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.t("Close", "닫기")) { dismiss() }
                        .foregroundStyle(PaletteTheme.primaryText)
                }
            }
            .toolbarBackground(PaletteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(PaletteTheme.background)
        .alert(
            L10n.t("Photos access needed", "사진 접근 권한 필요"),
            isPresented: $showSettingsAlert
        ) {
            Button(L10n.t("Cancel", "취소"), role: .cancel) {}
            Button(L10n.t("Open Settings", "설정 열기")) { openAppSettings() }
        } message: {
            Text(L10n.t(
                "Enable Photos access in Settings to save your export.",
                "설정에서 사진 접근을 허용하면 저장할 수 있어요."
            ))
        }
        .alert(
            L10n.t("Save failed", "저장 실패"),
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button(L10n.t("OK", "확인"), role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
        .sensoryFeedback(.success, trigger: saveStatus == .saved)
    }

    // MARK: Preview

    private static let canvasSize: CGFloat = 1200

    private var preview: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                GeometryReader { proxy in
                    let scale = proxy.size.width / Self.canvasSize
                    ExportCanvas(options: options, data: data)
                        .frame(width: Self.canvasSize, height: Self.canvasSize)
                        .scaleEffect(scale, anchor: .topLeading)
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: Date navigator

    private var dateNavigator: some View {
        HStack(spacing: 8) {
            Button(action: goToPreviousPeriod) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(ExportText.header(for: options))
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.3)
                .foregroundStyle(PaletteTheme.primaryText)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .contentTransition(.opacity)

            Button(action: goToNextPeriod) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoNext
                                     ? PaletteTheme.secondaryText
                                     : PaletteTheme.tertiaryText.opacity(0.35))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)
        }
    }

    // MARK: Options

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            pickerRow(title: L10n.t("Scope", "범위")) {
                Picker("", selection: $options.scope) {
                    ForEach(ExportScope.allCases.filter { $0 != .year }) {
                        Text($0.label).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: options.scope) { _, newScope in
                    if newScope != .week, options.style == .stripes {
                        options.style = .grid
                    }
                }
            }

            if options.scope == .week {
                pickerRow(title: L10n.t("Style", "스타일")) {
                    Picker("", selection: $options.style) {
                        ForEach(ExportStyle.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if options.style == .grid {
                section(title: L10n.t("Grid options", "그리드 옵션")) {
                    toggleRow(L10n.t("Show header", "헤더"), $options.showHeader)
                    if options.scope != .year {
                        toggleRow(L10n.t("Show weekday labels", "요일 라벨"), $options.showWeekdayLabels)
                    }
                    toggleRow(L10n.t("Show day count", "일수 표시"), $options.showDayCount)
                }
            } else {
                section(title: L10n.t("Stripes options", "스트라이프 옵션")) {
                    pickerRow(title: L10n.t("Orientation", "방향")) {
                        Picker("", selection: $options.stripesOrientation) {
                            ForEach(StripesOrientation.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    toggleRow(L10n.t("Skip empty days", "빈 날 제외"), $options.skipEmpty)
                    toggleRow(L10n.t("Show header", "헤더"), $options.showHeader)
                }
            }

            section(title: L10n.t("Appearance", "배경")) {
                pickerRow(title: L10n.t("Background", "배경색")) {
                    Picker("", selection: $options.background) {
                        ForEach(ExportBackground.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                toggleRow(L10n.t("Show palette watermark", "워터마크"), $options.showWatermark)
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                if let shareURL {
                    Button(action: { saveToPhotos(shareURL) }) {
                        barLabel(saveButtonText, primary: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(saveStatus == .saving)

                    ShareLink(item: shareURL) {
                        barLabel(L10n.t("Share", "공유"), primary: true)
                    }
                } else {
                    Button(action: renderPNG) {
                        barLabel(
                            isRendering ? L10n.t("Rendering…", "생성 중…") : L10n.t("Render PNG", "PNG 만들기"),
                            primary: true
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRendering)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 12)
            .background(
                LinearGradient(
                    colors: [PaletteTheme.background.opacity(0), PaletteTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .onChange(of: options.style) { _, _ in resetRender() }
        .onChange(of: options.scope) { _, _ in resetRender() }
        .onChange(of: options.date) { _, _ in resetRender() }
        .onChange(of: options.stripesOrientation) { _, _ in resetRender() }
        .onChange(of: options.skipEmpty) { _, _ in resetRender() }
        .onChange(of: options.showHeader) { _, _ in resetRender() }
        .onChange(of: options.showWeekdayLabels) { _, _ in resetRender() }
        .onChange(of: options.showDayCount) { _, _ in resetRender() }
        .onChange(of: options.background) { _, _ in resetRender() }
        .onChange(of: options.showWatermark) { _, _ in resetRender() }
    }

    private var saveButtonText: String {
        switch saveStatus {
        case .idle: return L10n.t("Save", "저장")
        case .saving: return L10n.t("Saving…", "저장 중…")
        case .saved: return L10n.t("Saved", "저장됨")
        case .failed: return L10n.t("Save", "저장")
        }
    }

    private func barLabel(_ text: String, primary: Bool) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
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

    // MARK: Actions

    private func resetRender() {
        shareURL = nil
        saveStatus = .idle
    }

    @MainActor
    private func renderPNG() {
        isRendering = true
        let canvas = ExportCanvas(options: options, data: data)
        let url = ExportRenderer.writePNG(
            canvas,
            size: CGSize(width: Self.canvasSize, height: Self.canvasSize),
            scale: 2
        )
        isRendering = false
        shareURL = url
    }

    private func saveToPhotos(_ url: URL) {
        saveStatus = .saving
        Task {
            let result = await PhotoLibrarySaver.saveImage(at: url)
            await MainActor.run {
                switch result {
                case .saved:
                    saveStatus = .saved
                    Task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        if saveStatus == .saved { saveStatus = .idle }
                    }
                case .denied:
                    saveStatus = .idle
                    showSettingsAlert = true
                case .failed(let error):
                    saveStatus = .failed
                    saveErrorMessage = error.localizedDescription
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        if saveStatus == .failed { saveStatus = .idle }
                    }
                }
            }
        }
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    // MARK: Date navigation

    private func goToPreviousPeriod() {
        withAnimation(.easeInOut(duration: 0.25)) {
            options.date = shifted(options.date, forward: false)
        }
    }

    private func goToNextPeriod() {
        guard canGoNext else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            options.date = shifted(options.date, forward: true)
        }
    }

    private func shifted(_ date: Date, forward: Bool) -> Date {
        let cal = Calendar.current
        let comps: DateComponents = options.scope == .week
            ? DateComponents(day: forward ? 7 : -7)
            : DateComponents(month: forward ? 1 : -1)
        return cal.date(byAdding: comps, to: date) ?? date
    }

    private var canGoNext: Bool {
        !isCurrentPeriod(options.date)
    }

    private func isCurrentPeriod(_ date: Date) -> Bool {
        let cal = Calendar.current
        let today = Date()
        switch options.scope {
        case .week:
            return weekStart(of: date) == weekStart(of: today)
        case .month:
            return cal.component(.year, from: date) == cal.component(.year, from: today)
                && cal.component(.month, from: date) == cal.component(.month, from: today)
        case .year:
            return cal.component(.year, from: date) == cal.component(.year, from: today)
        }
    }

    private func weekStart(of date: Date) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: day)
        let offset = (weekday - options.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -offset, to: day) ?? day
    }

    // MARK: Row helpers

    private func pickerRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PaletteTheme.secondaryText)
            content()
        }
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.primaryText)
        }
        .tint(PaletteTheme.primaryText)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PaletteTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
        )
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(PaletteTheme.secondaryText)
            VStack(spacing: 10) { content() }
        }
    }
}

#Preview {
    ExportView(initialScope: .month)
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
