import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var pageIndex: Int = 0
    @State private var reminderTime: Date? = nil

    var body: some View {
        ZStack {
            PaletteTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                pageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        ZStack {
            switch pageIndex {
            case 0:
                OnboardingWelcomePage()
                    .transition(.opacity)
            case 1:
                OnboardingGridPage()
                    .transition(.opacity)
            case 2:
                OnboardingReminderPage(selectedTime: $reminderTime)
                    .transition(.opacity)
            default:
                OnboardingReadyPage()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: pageIndex)
    }

    private var footer: some View {
        VStack(spacing: 20) {
            pageIndicator

            Button(action: advance) {
                Text(primaryButtonTitle)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(isPrimaryEnabled ? PaletteTheme.background : PaletteTheme.background.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isPrimaryEnabled ? PaletteTheme.primaryText : PaletteTheme.primaryText.opacity(0.25))
                    )
            }
            .disabled(!isPrimaryEnabled)
            .animation(.easeOut(duration: 0.2), value: isPrimaryEnabled)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == pageIndex ? PaletteTheme.primaryText : PaletteTheme.tertiaryText.opacity(0.5))
                    .frame(width: i == pageIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pageIndex)
            }
        }
    }

    private var primaryButtonTitle: String {
        switch pageIndex {
        case 0, 1:
            return L10n.t("Continue", "계속")
        case 2:
            return reminderTime == nil
                ? L10n.t("Set a time to continue", "시간을 설정해주세요")
                : L10n.t("Enable reminder", "알림 설정")
        default:
            return L10n.t("Start", "시작하기")
        }
    }

    private var isPrimaryEnabled: Bool {
        if pageIndex == 2 { return reminderTime != nil }
        return true
    }

    private func advance() {
        switch pageIndex {
        case 2:
            guard let time = reminderTime else { return }
            Task {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    NotificationManager.shared.scheduleDailyReminder(at: time)
                }
                UserDefaults.standard.set(time, forKey: "palette.reminderTime")
                withAnimation { pageIndex = 3 }
            }
        case 3:
            onComplete()
        default:
            withAnimation { pageIndex += 1 }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
