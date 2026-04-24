import SwiftUI
import SwiftData
import PaletteShared

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var options: ExportOptions
    @State private var shareURL: URL? = nil
    @State private var isRendering: Bool = false

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
            ZStack {
                PaletteTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        preview
                        optionsPanel
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 80)
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
    }

    // MARK: Preview

    private var preview: some View {
        ExportCanvas(options: options, data: data)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: Options

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            pickerRow(title: L10n.t("Style", "스타일")) {
                Picker("", selection: $options.style) {
                    ForEach(ExportStyle.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            pickerRow(title: L10n.t("Scope", "범위")) {
                Picker("", selection: $options.scope) {
                    ForEach(ExportScope.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
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
                    ShareLink(item: shareURL) {
                        barLabel(L10n.t("Share", "공유"), primary: true)
                    }
                } else {
                    Button(action: renderAndShare) {
                        barLabel(
                            isRendering ? L10n.t("Rendering…", "생성 중…") : L10n.t("Render PNG", "PNG 만들기"),
                            primary: true
                        )
                    }
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
        .onChange(of: options.style) { _, _ in shareURL = nil }
        .onChange(of: options.scope) { _, _ in shareURL = nil }
        .onChange(of: options.stripesOrientation) { _, _ in shareURL = nil }
        .onChange(of: options.skipEmpty) { _, _ in shareURL = nil }
        .onChange(of: options.showHeader) { _, _ in shareURL = nil }
        .onChange(of: options.showWeekdayLabels) { _, _ in shareURL = nil }
        .onChange(of: options.showDayCount) { _, _ in shareURL = nil }
        .onChange(of: options.background) { _, _ in shareURL = nil }
        .onChange(of: options.showWatermark) { _, _ in shareURL = nil }
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

    @MainActor
    private func renderAndShare() {
        isRendering = true
        let canvas = ExportCanvas(options: options, data: data)
        let url = ExportRenderer.writePNG(canvas, size: CGSize(width: 1200, height: 1200), scale: 2)
        isRendering = false
        shareURL = url
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
