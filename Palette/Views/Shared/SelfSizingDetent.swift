import SwiftUI

extension View {
    /// Sizes the enclosing sheet to its content's intrinsic height, alongside
    /// any additional fixed-height detents the caller wants to make available.
    ///
    /// - Parameters:
    ///   - selection: When provided, the caller controls which detent is
    ///     active. Wrap the binding's mutations in `withAnimation` to share a
    ///     single animation curve with surrounding view changes.
    ///   - measured: Optional outbound binding that receives the most recent
    ///     intrinsic content height. Useful when the caller wants to build a
    ///     `.height(measured)` detent that stays in sync as content changes.
    ///   - additional: Extra fixed-height detents (e.g. `.height(540)` for a
    ///     roomier page or `.large`).
    ///   - initialEstimate: Height used for the very first frame, before the
    ///     content has been measured. A value close to the real height avoids
    ///     a one-frame visual jump.
    ///   - animateChanges: When true, height changes from new measurements
    ///     animate. Caller-driven `selection` changes always honor whatever
    ///     animation transaction the caller is in.
    func selfSizingDetent(
        selection: Binding<PresentationDetent>? = nil,
        measured: Binding<CGFloat?>? = nil,
        additional: [PresentationDetent] = [],
        initialEstimate: CGFloat = 400,
        animateChanges: Bool = true
    ) -> some View {
        modifier(SelfSizingDetentModifier(
            selection: selection,
            measuredBinding: measured,
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
    let selection: Binding<PresentationDetent>?
    let measuredBinding: Binding<CGFloat?>?
    let additional: [PresentationDetent]
    let initialEstimate: CGFloat
    let animateChanges: Bool

    @State private var localMeasured: CGFloat? = nil

    private var currentHeight: CGFloat {
        (measuredBinding?.wrappedValue ?? localMeasured) ?? initialEstimate
    }

    func body(content: Content) -> some View {
        let detents = Set([.height(currentHeight)] + additional)

        return content
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
            .applyDetents(detents, selection: selection)
    }

    @MainActor
    private func apply(_ newValue: CGFloat) {
        let prev = (measuredBinding?.wrappedValue ?? localMeasured) ?? -1
        guard newValue > 0, abs(newValue - prev) > 0.5 else { return }

        let assign: () -> Void = {
            if let binding = measuredBinding {
                binding.wrappedValue = newValue
            } else {
                localMeasured = newValue
            }
        }

        if animateChanges {
            withAnimation(.easeInOut(duration: 0.25), assign)
        } else {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t, assign)
        }
    }
}

private extension View {
    @ViewBuilder
    func applyDetents(
        _ detents: Set<PresentationDetent>,
        selection: Binding<PresentationDetent>?
    ) -> some View {
        if let selection {
            self.presentationDetents(detents, selection: selection)
        } else {
            self.presentationDetents(detents)
        }
    }
}
