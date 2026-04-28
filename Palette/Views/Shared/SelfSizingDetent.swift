import SwiftUI

extension View {
    /// Sizes the enclosing sheet to its content's intrinsic height.
    ///
    /// - Parameters:
    ///   - additional: Extra detents the user can drag to (e.g. `.large`).
    ///   - initialEstimate: Height used for the very first frame, before the
    ///     content has been measured. A value close to the real height avoids
    ///     a one-frame visual jump.
    ///   - animateChanges: When true, content-driven height changes animate.
    func selfSizingDetent(
        additional: [PresentationDetent] = [],
        initialEstimate: CGFloat = 400,
        animateChanges: Bool = true
    ) -> some View {
        modifier(SelfSizingDetentModifier(
            additional: additional,
            initialEstimate: initialEstimate,
            animateChanges: animateChanges
        ))
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct SelfSizingDetentModifier: ViewModifier {
    let additional: [PresentationDetent]
    let initialEstimate: CGFloat
    let animateChanges: Bool

    @State private var measured: CGFloat? = nil

    func body(content: Content) -> some View {
        let height = measured ?? initialEstimate
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ContentHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(ContentHeightKey.self) { newValue in
                Task { @MainActor in
                    apply(newValue)
                }
            }
            .presentationDetents(Set([.height(height)] + additional))
    }

    @MainActor
    private func apply(_ newValue: CGFloat) {
        guard newValue > 0, abs(newValue - (measured ?? -1)) > 0.5 else { return }
        if animateChanges {
            withAnimation(.easeInOut(duration: 0.25)) { measured = newValue }
        } else {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { measured = newValue }
        }
    }
}
