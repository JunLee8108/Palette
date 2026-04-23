import SwiftUI
import SwiftData

struct RootView: View {
    @State private var selectedTab: Int = 0

    private let tabCount: Int = 2

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                TodayView(onSaved: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        selectedTab = 1
                    }
                })
                .tag(0)

                YearGridView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .padding(.top, 8)
        }
        .background(PaletteTheme.background.ignoresSafeArea())
    }

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
}

#Preview {
    RootView()
        .modelContainer(for: ColorEntry.self, inMemory: true)
}
