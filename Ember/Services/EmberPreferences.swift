// EmberPreferences.swift
import Foundation

enum EmberPreferenceKey {
    static let soundEnabled = "soundEnabled"
    static let hapticsEnabled = "hapticsEnabled"
    static let reducedMotionEnabled = "reducedMotionEnabled"
    static let morningRitualLastShownDate = "morningRitualLastShownDate"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let displayName = "displayName"
    static let autoStartScheduledSessions = "autoStartScheduledSessions"
    static let dismissedAutoSessions = "dismissedAutoSessions"
    static let focusFilterShowOnlyPrimary = "focusFilterShowOnlyPrimary"
    static let currentTheme = "currentTheme"
    static let oledBlackEnabled = "oledBlackEnabled"
}

enum EmberPreferences {
    static var soundEnabled: Bool {
        get { bool(for: EmberPreferenceKey.soundEnabled, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.soundEnabled) }
    }

    static var hapticsEnabled: Bool {
        get { bool(for: EmberPreferenceKey.hapticsEnabled, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.hapticsEnabled) }
    }

    static var reducedMotionEnabled: Bool {
        get { bool(for: EmberPreferenceKey.reducedMotionEnabled, defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.reducedMotionEnabled) }
    }

    static var currentTheme: EmberTheme {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: EmberPreferenceKey.currentTheme),
                  let theme = EmberTheme(rawValue: rawValue)
            else { return .ember }
            return theme
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: EmberPreferenceKey.currentTheme) }
    }

    static var oledBlackEnabled: Bool {
        get { bool(for: EmberPreferenceKey.oledBlackEnabled, defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.oledBlackEnabled) }
    }

    static var morningRitualLastShownDate: Date? {
        get { UserDefaults.standard.object(forKey: EmberPreferenceKey.morningRitualLastShownDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.morningRitualLastShownDate) }
    }

    @MainActor static var hasShownMorningRitualToday: Bool {
        guard let date = morningRitualLastShownDate else { return false }
        let ds = DateService.shared
        return ds.calendar.isDate(date, inSameDayAs: ds.now)
    }

    @MainActor static func markMorningRitualShownToday() {
        morningRitualLastShownDate = DateService.shared.today
    }

    static var hasCompletedOnboarding: Bool {
        get { bool(for: EmberPreferenceKey.hasCompletedOnboarding, defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.hasCompletedOnboarding) }
    }

    static var displayName: String {
        get { UserDefaults.standard.string(forKey: EmberPreferenceKey.displayName) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.displayName) }
    }

    // MARK: - Auto-start scheduled sessions

    /// If true, the ScheduledSessionWatcher will auto-start a Live Activity
    /// when a task's scheduledTime window arrives.
    static var autoStartScheduledSessions: Bool {
        get { bool(for: EmberPreferenceKey.autoStartScheduledSessions, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.autoStartScheduledSessions) }
    }

    /// Dismissed auto-session task IDs mapped to the date they were dismissed.
    /// Dictionary is stored as JSON-encoded Data.
    @MainActor private static var dismissedAutoSessions: [String: Date] {
        get {
            guard let data = UserDefaults.standard.data(forKey: EmberPreferenceKey.dismissedAutoSessions),
                  let decoded = try? JSONDecoder().decode([String: Date].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: EmberPreferenceKey.dismissedAutoSessions)
            }
        }
    }

    /// Returns true if the user dismissed the auto-session for this task today.
    @MainActor static func hasAutoSessionBeenDismissed(for taskID: UUID) -> Bool {
        let key = taskID.uuidString
        guard let dismissedDate = dismissedAutoSessions[key] else { return false }
        let ds = DateService.shared
        return ds.calendar.isDate(dismissedDate, inSameDayAs: ds.now)
    }

    /// Record that the user dismissed the auto-session for this task today.
    @MainActor static func dismissAutoSession(for taskID: UUID) {
        var current = dismissedAutoSessions
        current[taskID.uuidString] = DateService.shared.now
        dismissedAutoSessions = current
    }

    // MARK: - Focus filter

    /// When true (set by EmberFocusFilter intent), HomeScreen hides slots 02 and 03.
    static var focusFilterShowOnlyPrimary: Bool {
        get { bool(for: EmberPreferenceKey.focusFilterShowOnlyPrimary, defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: EmberPreferenceKey.focusFilterShowOnlyPrimary) }
    }

    // MARK: - Streak repair

    /// Dates when a streak freeze was used.
    static var freezeUsedDates: [Date] {
        get {
            UserDefaults.standard.array(forKey: "freezeUsedDates") as? [Date] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "freezeUsedDates")
        }
    }

    static func resetForUITesting() {
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.soundEnabled)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.hapticsEnabled)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.reducedMotionEnabled)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.currentTheme)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.oledBlackEnabled)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.morningRitualLastShownDate)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.displayName)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.autoStartScheduledSessions)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.dismissedAutoSessions)
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.focusFilterShowOnlyPrimary)
        UserDefaults.standard.removeObject(forKey: "freezeUsedDates")
    }

    private static func bool(for key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }
}
