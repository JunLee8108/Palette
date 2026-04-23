import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("palette.username") private var storedUsername: String = ""
    @AppStorage("palette.reminderTime") private var reminderTimeInterval: Double = 0

    @State private var draftName: String = ""
    @FocusState private var nameFocused: Bool

    @State private var showTimePicker: Bool = false
    @State private var draftTime: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                PaletteTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        section(title: L10n.t("Profile", "프로필")) {
                            nameRow
                        }

                        section(title: L10n.t("Reminder", "알림")) {
                            reminderRow
                        }

                        section(title: L10n.t("About", "정보")) {
                            infoRow(
                                label: L10n.t("Version", "버전"),
                                value: appVersion
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(L10n.t("Settings", "설정"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Done", "완료")) {
                        commitName()
                        dismiss()
                    }
                    .foregroundStyle(PaletteTheme.primaryText)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(PaletteTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                draftTime: $draftTime,
                onConfirm: {
                    reminderTimeInterval = draftTime.timeIntervalSince1970
                    NotificationManager.shared.scheduleDailyReminder(at: draftTime)
                    showTimePicker = false
                },
                onCancel: { showTimePicker = false }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
            .presentationBackground(PaletteTheme.background)
        }
        .onAppear {
            draftName = storedUsername
            draftTime = currentReminderTime ?? defaultReminderTime()
        }
    }

    // MARK: Rows

    private var nameRow: some View {
        HStack(spacing: 12) {
            Text(L10n.t("Name", "이름"))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)

            Spacer()

            TextField(
                "",
                text: $draftName,
                prompt: Text(L10n.t("Not set", "미설정"))
                    .foregroundStyle(PaletteTheme.tertiaryText)
            )
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(PaletteTheme.primaryText)
            .multilineTextAlignment(.trailing)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($nameFocused)
            .onSubmit { commitName() }
            .onChange(of: draftName) { _, newValue in
                if newValue.count > OnboardingUsernamePage.maxLength {
                    draftName = String(newValue.prefix(OnboardingUsernamePage.maxLength))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(PaletteTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
        )
    }

    private var reminderRow: some View {
        Button {
            nameFocused = false
            commitName()
            draftTime = currentReminderTime ?? defaultReminderTime()
            showTimePicker = true
        } label: {
            HStack(spacing: 12) {
                Text(L10n.t("Daily time", "매일 알림 시간"))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)

                Spacer()

                if let time = currentReminderTime {
                    Text(timeString(time))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(PaletteTheme.primaryText)
                        .monospacedDigit()
                } else {
                    Text(L10n.t("Not set", "미설정"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(PaletteTheme.tertiaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PaletteTheme.tertiaryText)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PaletteTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.primaryText)
                .monospacedDigit()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(PaletteTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: Section helper

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(PaletteTheme.secondaryText)
                .textCase(.uppercase)
                .padding(.leading, 4)

            content()
        }
    }

    // MARK: Helpers

    private func commitName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        storedUsername = trimmed
        draftName = trimmed
    }

    private var currentReminderTime: Date? {
        guard reminderTimeInterval > 0 else { return nil }
        return Date(timeIntervalSince1970: reminderTimeInterval)
    }

    private func defaultReminderTime() -> Date {
        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        return formatter.string(from: date)
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
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
    SettingsView()
}
