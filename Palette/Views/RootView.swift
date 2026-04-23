import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ColorEntry.date) private var allEntries: [ColorEntry]

    @State private var selectedTab: Int = 0
    @State private var selectedDay: SelectedDay? = nil

    private struct SelectedDay: Identifiable {
        let id: String
        let date: Date
    }

    private let year: Int
    private let firstWeekday: Int
    private let tabCount: Int = 4

    init() {
        self.year = DayKey.year(of: Date())
        self.firstWeekday = Calendar.current.firstWeekday
    }

    private var entriesByKey: [String: ColorEntry] {
        var dict: [String: ColorEntry] = [:]
        dict.reserveCapacity(allEntries.count)
        for entry in allEntries where DayKey.year(of: entry.date) == year {
            dict[entry.dayKey] = entry
        }
        return dict
    }

    private var filledCount: Int { entriesByKey.count }

    private var isGallery: Bool { selectedTab >= 1 }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                TodayView(onSaved: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        selectedTab = 1
                    }
                })
                .tag(0)

                WeeklyBoardView(
                    year: year,
                    firstWeekday: firstWeekday,
                    entriesByKey: entriesByKey,
                    onSelectDate: handleSelect
                )
                .padding(.top, galleryTopInset)
                .tag(1)

                MonthlyBoardView(
                    year: year,
                    firstWeekday: firstWeekday,
                    entriesByKey: entriesByKey,
                    onSelectDate: handleSelect
                )
                .padding(.top, galleryTopInset)
                .tag(2)

                YearlyBoardView(
                    year: year,
                    firstWeekday: firstWeekday,
                    entriesByKey: entriesByKey,
                    onSelectDate: handleSelect
                )
                .padding(.top, galleryTopInset)
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            galleryHeader
                .opacity(isGallery ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: isGallery)
                .allowsHitTesting(isGallery)

            pageIndicator
                .padding(.top, 8)
        }
        .background(PaletteTheme.background.ignoresSafeArea())
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(
                date: day.date,
                entry: entriesByKey[day.id],
                onChanged: { selectedDay = nil }
            )
        }
    }

    // MARK: - Gallery header (Week / Month / Year)

    private var galleryTopInset: CGFloat { 110 }

    private var galleryHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: "\(year)")
                    .font(.system(size: 30, weight: .thin, design: .serif))
                    .tracking(1)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .monospacedDigit()

                Spacer()

                Text(countText)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .monospacedDigit()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            modeSwitcher
                .padding(.top, 20)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var countText: String {
        let n = filledCount
        return L10n.t(
            n == 1 ? "1 day" : "\(n) days",
            "\(n)일"
        )
    }

    private var modeSwitcher: some View {
        HStack(spacing: 28) {
            modeButton(tab: 1, label: L10n.t("Week", "주"))
            modeButton(tab: 2, label: L10n.t("Month", "월"))
            modeButton(tab: 3, label: L10n.t("Year", "연"))
        }
    }

    private func modeButton(tab: Int, label: String) -> some View {
        let isActive = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .tracking(0.5)
                    .foregroundStyle(isActive ? PaletteTheme.primaryText : PaletteTheme.tertiaryText)

                Rectangle()
                    .fill(isActive ? PaletteTheme.primaryText : .clear)
                    .frame(width: 14, height: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabCount, id: \.self) { i in
                Capsule()
                    .fill(i == selectedTab
                          ? PaletteTheme.primaryText
                          : PaletteTheme.tertiaryText.opacity(0.5))
                    .frame(width: i == selectedTab ? 16 : 5, height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            }
        }
    }

    // MARK: - Actions

    private func handleSelect(_ date: Date) {
        selectedDay = SelectedDay(id: DayKey.make(for: date), date: date)
    }
}

#Preview {
    RootView()
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
