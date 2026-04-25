import SwiftUI

struct SwipeHintView: View {
    @State private var nudge: Bool = false

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 18, weight: .light))
            .foregroundStyle(PaletteTheme.tertiaryText)
            .offset(x: nudge ? 6 : 0)
            .opacity(nudge ? 0.2 : 0.55)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    nudge = true
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    SwipeHintView()
        .padding()
        .background(PaletteTheme.background)
}
