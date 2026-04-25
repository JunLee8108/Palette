import SwiftUI

struct OnboardingReminderPage: View {
    @Binding var selectedTime: Date?
    var animateIn: Bool

    @State private var showPicker: Bool = false
    @State private var draftTime: Date = defaultDraftTime()
    @State private var textIn: Bool

    private static func defaultDraftTime() -> Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }

    init(selectedTime: Binding<Date?>, animateIn: Bool = true) {
        _selectedTime = selectedTime
        self.animateIn = animateIn
        _textIn = State(initialValue: !animateIn)
    }

    var body: some View {
        VStack(spacing: 44) {
            Spacer()

            VStack(spacing: 14) {
                Text(L10n.t("Reminder?", "알림?"))
                    .font(.system(size: 32, weight: .thin, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(L10n.t(
                    "Choose a daily reminder time.\nA quiet nudge, once a day.",
                    "매일 알림을 받을 시간을 골라주세요.\n하루에 한 번, 조용한 노크."
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

            VStack(spacing: 12) {
                timeButton

                HStack {
                    Text(L10n.t("Optional", "선택 사항"))
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(PaletteTheme.tertiaryText)
                        .textCase(.uppercase)
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard animateIn else { return }
            textIn = true
        }
        .sheet(isPresented: $showPicker) {
            TimePickerSheet(
                draftTime: $draftTime,
                onConfirm: {
                    selectedTime = draftTime
                    showPicker = false
                },
                onCancel: { showPicker = false }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
            .presentationBackground(PaletteTheme.background)
        }
    }

    private var timeButton: some View {
        Button {
            showPicker = true
        } label: {
            VStack(spacing: 10) {
                Text(L10n.t("Daily reminder", "매일 알림"))
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(PaletteTheme.secondaryText)
                    .textCase(.uppercase)

                if let time = selectedTime {
                    Text(timeString(time))
                        .font(.system(size: 54, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(PaletteTheme.primaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    Text("--:--")
                        .font(.system(size: 54, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(PaletteTheme.tertiaryText)
                        .monospacedDigit()
                }

                Text(selectedTime == nil
                     ? L10n.t("Tap to set", "탭하여 설정")
                     : L10n.t("Tap to change", "탭하여 변경"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(PaletteTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        return formatter.string(from: date)
    }
}

private struct TimePickerSheet: View {
    @Binding var draftTime: Date
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.t("Cancel", "취소"), action: onCancel)
                    .foregroundStyle(PaletteTheme.secondaryText)
                Spacer()
                Text(L10n.t("Reminder time", "알림 시간"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PaletteTheme.primaryText)
                Spacer()
                Button(L10n.t("Set", "설정"), action: onConfirm)
                    .foregroundStyle(PaletteTheme.primaryText)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 15))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().overlay(PaletteTheme.hairline)

            DatePicker("",
                       selection: $draftTime,
                       displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 20)
        }
        .background(PaletteTheme.background)
    }
}

#Preview {
    StatefulPreviewWrapper(Date?.none) { binding in
        OnboardingReminderPage(selectedTime: binding, animateIn: true)
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
