import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("palette.username") private var storedUsername: String = ""
    @AppStorage("palette.reminderTime") private var reminderTimeInterval: Double = 0
    @AppStorage("palette.appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    @State private var draftName: String = ""
    @FocusState private var nameFocused: Bool

    @State private var showTimePicker: Bool = false
    @State private var draftTime: Date = Date()
    @State private var showOpenSettingsAlert: Bool = false

    #if DEBUG
    @State private var iconPNGURL: URL? = nil
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                PaletteTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        section(title: L10n.t("Profile", "프로필")) {
                            nameRow
                        }

                        section(title: L10n.t("Appearance", "외관")) {
                            appearanceRow
                        }

                        section(title: L10n.t("Reminder", "알림")) {
                            reminderToggleRow
                            if reminderTimeInterval > 0 {
                                reminderTimeRow
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: reminderTimeInterval > 0)

                        section(title: L10n.t("About", "정보")) {
                            infoRow(
                                label: L10n.t("Version", "버전"),
                                value: appVersion
                            )
                        }

                        #if DEBUG
                        section(title: "Dev") {
                            devIconExportRow
                        }
                        #endif
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .contentShape(Rectangle())
            .onTapGesture { nameFocused = false }
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
        .preferredColorScheme(currentAppearance.colorScheme)
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
        .alert(
            L10n.t("Notifications are off", "알림이 꺼져 있어요"),
            isPresented: $showOpenSettingsAlert
        ) {
            Button(L10n.t("Cancel", "취소"), role: .cancel) {}
            Button(L10n.t("Open Settings", "설정 열기")) { openAppSettings() }
        } message: {
            Text(L10n.t(
                "Enable notifications in Settings to receive the daily reminder.",
                "설정에서 알림을 허용하면 매일 알림을 받을 수 있어요."
            ))
        }
        .onAppear {
            draftName = storedUsername
            draftTime = currentReminderTime ?? defaultReminderTime()

            Task {
                let status = await NotificationManager.shared.authorizationStatus()
                if status == .denied, reminderTimeInterval > 0 {
                    NotificationManager.shared.cancelDailyReminder()
                    await MainActor.run { reminderTimeInterval = 0 }
                }
            }
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
            .frame(minHeight: 22)
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
        .contentShape(Rectangle())
        .onTapGesture { nameFocused = true }
    }

    private var appearanceRow: some View {
        let binding = Binding<AppearanceMode>(
            get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
            set: { newValue in
                appearanceRaw = newValue.rawValue
                #if canImport(UIKit)
                newValue.applyToWindows()
                #endif
            }
        )
        return Picker("", selection: binding) {
            ForEach(AppearanceMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var reminderToggleRow: some View {
        HStack(spacing: 12) {
            Text(L10n.t("Daily reminder", "매일 알림"))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PaletteTheme.secondaryText)

            Spacer()

            Toggle("", isOn: Binding(
                get: { reminderTimeInterval > 0 },
                set: { _ in
                    if reminderTimeInterval > 0 {
                        handleDisableReminder()
                    } else {
                        Task { await handleEnableReminder() }
                    }
                }
            ))
            .labelsHidden()
            .tint(PaletteTheme.primaryText)
        }
        .padding(.vertical, 10)
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

    private var reminderTimeRow: some View {
        Button {
            nameFocused = false
            commitName()
            draftTime = currentReminderTime ?? defaultReminderTime()
            showTimePicker = true
        } label: {
            HStack(spacing: 12) {
                Text(L10n.t("Time", "시간"))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(PaletteTheme.secondaryText)

                Spacer()

                if let time = currentReminderTime {
                    Text(timeString(time))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(PaletteTheme.primaryText)
                        .monospacedDigit()
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

    #if DEBUG
    private var devIconExportRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppIconView()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(PaletteTheme.hairline, lineWidth: 1)
                )

            Button {
                iconPNGURL = AppIconExporter.writePNG()
            } label: {
                Text("Generate AppIcon PNG (1024)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PaletteTheme.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
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

            if let url = iconPNGURL {
                ShareLink(item: url) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share \(url.lastPathComponent)")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(PaletteTheme.primaryText)
                    .padding(.vertical, 12)
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
            }
        }
    }
    #endif

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

    private var currentAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

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
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
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

    // MARK: Reminder toggle actions

    private func handleEnableReminder() async {
        let status = await NotificationManager.shared.authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                await MainActor.run {
                    draftTime = currentReminderTime ?? defaultReminderTime()
                    showTimePicker = true
                }
            }
        case .denied:
            await MainActor.run { showOpenSettingsAlert = true }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                draftTime = currentReminderTime ?? defaultReminderTime()
                showTimePicker = true
            }
        @unknown default:
            break
        }
    }

    private func handleDisableReminder() {
        NotificationManager.shared.cancelDailyReminder()
        reminderTimeInterval = 0
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
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
