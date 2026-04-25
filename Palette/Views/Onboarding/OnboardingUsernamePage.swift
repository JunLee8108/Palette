import SwiftUI

struct OnboardingUsernamePage: View {
    @Binding var username: String

    @FocusState private var isFocused: Bool
    @State private var textIn: Bool = false

    static let maxLength: Int = 20

    var body: some View {
        VStack(spacing: 44) {
            Spacer()

            VStack(spacing: 14) {
                Text(L10n.t("Name?", "이름?"))
                    .font(.system(size: 32, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(L10n.t(
                    "Used for reminders and your grid.\nOptional, and editable anytime.",
                    "알림과 그리드에 사용돼요.\n선택 사항이고, 언제든 바꿀 수 있어요."
                ))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            }
            .opacity(textIn ? 1 : 0)
            .offset(y: textIn ? 0 : 10)
            .animation(.easeOut(duration: 0.6), value: textIn)

            VStack(spacing: 14) {
                TextField(
                    "",
                    text: $username,
                    prompt: Text(L10n.t("Your name", "이름"))
                        .foregroundStyle(PaletteTheme.tertiaryText)
                )
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(PaletteTheme.primaryText)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .padding(.vertical, 12)
                .onChange(of: username) { _, newValue in
                    if newValue.count > Self.maxLength {
                        username = String(newValue.prefix(Self.maxLength))
                    }
                }

                Rectangle()
                    .fill(isFocused ? PaletteTheme.primaryText : PaletteTheme.hairline)
                    .frame(height: 1)
                    .animation(.easeOut(duration: 0.2), value: isFocused)

                HStack {
                    Text(L10n.t("Optional", "선택 사항"))
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(PaletteTheme.tertiaryText)
                        .textCase(.uppercase)

                    Spacer()

                    Text("\(username.count) / \(Self.maxLength)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(PaletteTheme.tertiaryText)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 40)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
        .onAppear { textIn = true }
    }
}

#Preview {
    StatefulPreviewWrapper("") { binding in
        OnboardingUsernamePage(username: binding)
            .background(PaletteTheme.background)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
