// SettingsScreen.swift
import SwiftUI
import UserNotifications

struct SettingsScreen: View {
    @Environment(EmberRouter.self) private var router

    @AppStorage(EmberPreferenceKey.soundEnabled) private var soundEnabled = true
    @AppStorage(EmberPreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false
    // Step 8.9
    @AppStorage(EmberPreferenceKey.autoStartScheduledSessions) private var autoStartScheduledSessions = true
    @AppStorage(EmberPreferenceKey.currentTheme) private var currentThemeRaw = EmberTheme.ember.rawValue
    @AppStorage(EmberPreferenceKey.oledBlackEnabled) private var oledBlackEnabled = false

    @State private var notificationStatus = "Checking"
    @State private var currentAppIcon: AppIconService.Icon = .primary
    @State private var isSwitchingAppIcon = false
    @State private var appIconErrorMessage: String?

    private var selectedTheme: EmberTheme {
        EmberTheme(rawValue: currentThemeRaw) ?? .ember
    }

    private var background: Color { EmberColors.studioBackground }
    private let panel = Color(hex: "181818")
    private let panelElevated = Color(hex: "1F1F1F")
    private let panelMuted = Color(hex: "2A2A2A")
    private let textPrimary = Color(hex: "F7F3EA")
    private let textSecondary = Color(hex: "8B8B86")
    private var ember: Color { selectedTheme.accent }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    notificationPanel
                    appearancePanel
                    preferencePanel
                    privacyPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: currentThemeRaw)
        .animation(.easeInOut(duration: 0.18), value: oledBlackEnabled)
        .task {
            await refreshNotificationStatus()
            await MainActor.run {
                currentAppIcon = AppIconService.currentIcon()
            }
        }
        .alert("Couldn’t Change Icon", isPresented: appIconErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appIconErrorMessage ?? "Try again from the Home Screen.")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                router.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(panelElevated))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("settings.back")

            Spacer()

            Text("SETTINGS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(textSecondary)

            Spacer()

            Circle()
                .fill(panelElevated)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ember)
                )
        }
    }

    private var notificationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("REMINDERS")

            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)

                VStack(alignment: .leading, spacing: 3) {
                    Text(notificationStatus)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(textPrimary)

                    Text("Scheduled tasks use local notifications.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(textSecondary)
                }

                Spacer()

                Button {
                    requestNotificationPermission()
                } label: {
                    Text(notificationStatus == "Allowed" ? "Refresh" : "Allow")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(ember))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(studioPanel)
    }

    private var preferencePanel: some View {
        VStack(spacing: 0) {
            sectionHeader("PREFERENCES")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            settingsToggle(
                title: "Sound",
                subtitle: "Completion tones and reminder sound.",
                identifier: "settings.sound",
                isOn: $soundEnabled
            )
            divider
            settingsToggle(
                title: "Haptics",
                subtitle: "Physical feedback during completion.",
                identifier: "settings.haptics",
                isOn: $hapticsEnabled
            )
            divider
            settingsToggle(
                title: "Reduced Motion",
                subtitle: "Calmer orbit and victory movement.",
                identifier: "settings.reducedMotion",
                isOn: $reducedMotionEnabled
            )
            divider
            settingsToggle(
                title: "Auto Focus Session",
                subtitle: "Start a Live Activity when a scheduled task is due.",
                identifier: "settings.autoStartSessions",
                isOn: $autoStartScheduledSessions
            )
        }
        .padding(18)
        .background(studioPanel)
    }

    private var appearancePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("APPEARANCE")

            HStack(spacing: 12) {
                ForEach(EmberTheme.allCases, id: \.rawValue) { theme in
                    Button {
                        currentThemeRaw = theme.rawValue
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(panelElevated)
                                    .frame(height: 54)

                                HStack(spacing: 6) {
                                    Capsule()
                                        .fill(theme.accent)
                                        .frame(width: 30, height: 6)

                                    Capsule()
                                        .fill(theme.accentSubtle)
                                        .frame(width: 18, height: 6)

                                    Capsule()
                                        .fill(Color.white.opacity(0.09))
                                        .frame(width: 18, height: 6)
                                }
                            }

                            Text(theme.rawValue.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(selectedTheme == theme ? textPrimary : textSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(panel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .strokeBorder(selectedTheme == theme ? theme.accent.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.theme.\(theme.rawValue)")
                    .accessibilityLabel("\(theme.rawValue) theme")
                    .accessibilityAddTraits(selectedTheme == theme ? .isSelected : [])
                }
            }

            divider

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("App Icon")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(textPrimary)

                    Spacer()

                    if isSwitchingAppIcon {
                        ProgressView()
                            .controlSize(.small)
                            .tint(ember)
                    }
                }

                Text("Choose the studio mark that sits best on your home screen.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(AppIconService.Icon.allCases) { icon in
                        Button {
                            switchAppIcon(to: icon)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                AppIconPreview(icon: icon)
                                    .frame(height: 82)

                                Text(icon.title.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(currentAppIcon == icon ? textPrimary : textSecondary)

                                Text(icon.subtitle)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(panel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .strokeBorder(currentAppIcon == icon ? ember.opacity(0.74) : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSwitchingAppIcon || !AppIconService.supportsAlternateIcons && icon != .primary)
                        .accessibilityIdentifier("settings.icon.\(icon.rawValue.lowercased())")
                        .accessibilityLabel("\(icon.title) app icon")
                        .accessibilityAddTraits(currentAppIcon == icon ? .isSelected : [])
                    }
                }

                if !AppIconService.supportsAlternateIcons {
                    Text("Alternate icons aren’t available in this environment.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(textSecondary)
                }
            }

            divider

            settingsToggle(
                title: "OLED Black",
                subtitle: "Push studio backgrounds to pure black.",
                identifier: "settings.oledBlack",
                isOn: $oledBlackEnabled
            )
        }
        .padding(18)
        .background(studioPanel)
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("DATA")

            Text("Tasks, reflections, streaks, and preferences stay local on this device for now.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(textPrimary.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            Text("iCloud sync is not enabled in this build.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(textSecondary)
        }
        .padding(18)
        .background(studioPanel)
    }

    private func settingsToggle(
        title: String,
        subtitle: String,
        identifier: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(ember)
                .accessibilityIdentifier(identifier)
        }
        .padding(.vertical, 11)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .tracking(2.4)
            .foregroundStyle(textSecondary)
    }

    private var studioPanel: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private var statusColor: Color {
        switch notificationStatus {
        case "Allowed": return ember
        case "Denied": return Color.red.opacity(0.78)
        default: return panelMuted
        }
    }

    private var appIconErrorPresented: Binding<Bool> {
        Binding(
            get: { appIconErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    appIconErrorMessage = nil
                }
            }
        )
    }

    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status: String
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = "Allowed"
        case .denied:
            status = "Denied"
        case .notDetermined:
            status = "Not Allowed"
        @unknown default:
            status = "Unknown"
        }
        await MainActor.run {
            notificationStatus = status
        }
    }

    private func switchAppIcon(to icon: AppIconService.Icon) {
        guard currentAppIcon != icon, !isSwitchingAppIcon else { return }

        isSwitchingAppIcon = true
        Task {
            do {
                try await AppIconService.setIcon(icon)
                await MainActor.run {
                    currentAppIcon = icon
                    isSwitchingAppIcon = false
                }
            } catch {
                await MainActor.run {
                    appIconErrorMessage = error.localizedDescription
                    isSwitchingAppIcon = false
                }
            }
        }
    }
}

private struct AppIconPreview: View {
    let icon: AppIconService.Icon

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [icon.backgroundTop, icon.backgroundBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            Circle()
                .stroke(icon.ringColor, lineWidth: 2.2)
                .frame(width: 30, height: 30)

            Circle()
                .fill(icon.glowColor)
                .frame(width: 42, height: 42)
                .blur(radius: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [icon.coreInner, icon.coreOuter],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 16
                    )
                )
                .frame(width: 18, height: 18)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.white.opacity(icon == .black ? 0.07 : 0.18))
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: 1)
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.26), radius: 14, y: 8)
    }
}
