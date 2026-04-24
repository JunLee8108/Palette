import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ColorEntry.date) private var allEntries: [ColorEntry]

    @State private var scrollId: Int? = 0
    @State private var selectedDay: SelectedDay? = nil
    @State private var weekScrollTick: Int = 0
    @State private var monthScrollTick: Int = 0
    @State private var year: Int

    private struct SelectedDay: Identifiable {
        let id: String
        let date: Date
    }

    private let firstWeekday: Int
    private let tabCount: Int = 4

    init() {
        _year = State(initialValue: DayKey.year(of: Date()))
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

    private var availableYears: [Int] {
        let current = DayKey.year(of: Date())
        var set = Set(allEntries.map { DayKey.year(of: $0.date) })
        set.insert(current)
        return set.sorted(by: >)
    }

    private var currentTab: Int { scrollId ?? 0 }
    private var isGallery: Bool { currentTab >= 1 }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        TodayView(onSaved: {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                scrollId = 1
                            }
                        })
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .fadeOnPage()
                        .id(0)

                        ZStack {
                            WeeklyBoardView(
                                year: year,
                                firstWeekday: firstWeekday,
                                entriesByKey: entriesByKey,
                                scrollToTodayTick: weekScrollTick,
                                onSelectDate: handleSelect
                            )
                            .id(year)
                            .transition(.opacity)
                        }
                        .padding(.top, galleryTopInset)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .fadeOnPage()
                        .id(1)

                        ZStack {
                            MonthlyBoardView(
                                year: year,
                                firstWeekday: firstWeekday,
                                entriesByKey: entriesByKey,
                                scrollToTodayTick: monthScrollTick,
                                onSelectDate: handleSelect
                            )
                            .id(year)
                            .transition(.opacity)
                        }
                        .padding(.top, galleryTopInset)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .fadeOnPage()
                        .id(2)

                        ZStack {
                            YearlyBoardView(
                                year: year,
                                firstWeekday: firstWeekday,
                                entriesByKey: entriesByKey,
                                onSelectDate: handleSelect
                            )
                            .id(year)
                            .transition(.opacity)
                        }
                        .padding(.top, galleryTopInset)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .fadeOnPage()
                        .id(3)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollId)
                .scrollIndicators(.hidden)

                galleryHeader
                    .opacity(isGallery ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: isGallery)
                    .allowsHitTesting(isGallery)

                pageIndicator
                    .padding(.top, 8)
            }
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

    private var galleryTopInset: CGFloat { 130 }

    private var galleryHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                yearLabel

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

    private var yearLabel: some View {
        Menu {
            ForEach(availableYears, id: \.self) { y in
                Button {
                    changeYear(to: y)
                } label: {
                    if y == year {
                        Label("\(y)", systemImage: "checkmark")
                    } else {
                        Text(verbatim: "\(y)")
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(verbatim: "\(year)")
                    .font(.system(size: 30, weight: .thin, design: .serif))
                    .tracking(1)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PaletteTheme.tertiaryText)
            }
        }
    }

    private var countText: String {
        let n = filledCount
        return L10n.t(
            n == 1 ? "1 day" : "\(n) days",
            "\(n)일"
        )
    }

    private var modeSwitcher: some View {
        HStack(spacing: 8) {
            modeButton(tab: 1, label: L10n.t("Week", "주"))
            modeButton(tab: 2, label: L10n.t("Month", "월"))
            modeButton(tab: 3, label: L10n.t("Year", "연"))
        }
    }

    private func modeButton(tab: Int, label: String) -> some View {
        let isActive = currentTab == tab
        return Button {
            if isActive {
                switch tab {
                case 1: weekScrollTick += 1
                case 2: monthScrollTick += 1
                default: break
                }
            } else {
                withAnimation(.snappy) {
                    scrollId = tab
                }
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
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<tabCount, id: \.self) { i in
                Capsule()
                    .fill(i == currentTab
                          ? PaletteTheme.primaryText
                          : PaletteTheme.tertiaryText.opacity(0.5))
                    .frame(width: i == currentTab ? 16 : 5, height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentTab)
            }
        }
    }

    // MARK: - Actions

    private func handleSelect(_ date: Date) {
        selectedDay = SelectedDay(id: DayKey.make(for: date), date: date)
    }

    private func changeYear(to newYear: Int) {
        guard newYear != year else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            year = newYear
        }
    }
}

private extension View {
    func fadeOnPage() -> some View {
        self.scrollTransition(.interactive, axis: .horizontal) { content, phase in
            content.opacity(1 - min(1, abs(phase.value)))
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
