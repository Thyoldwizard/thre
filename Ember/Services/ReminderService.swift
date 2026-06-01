// ReminderService.swift
import Foundation
import UserNotifications

enum ReminderAuthorizationStatus {
    case authorized
    case provisional
    case ephemeral
    case notDetermined
    case denied
    case unknown
}

protocol ReminderNotificationCenter {
    func authorizationStatus() async -> ReminderAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

struct SystemReminderNotificationCenter: ReminderNotificationCenter {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> ReminderAuthorizationStatus {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        @unknown default:
            return .unknown
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}

struct ReminderService {
    static let shared = ReminderService()

    let clock: any EmberClock
    private let notificationCenter: any ReminderNotificationCenter

    init(
        clock: any EmberClock = SystemClock.continuous,
        notificationCenter: any ReminderNotificationCenter = SystemReminderNotificationCenter()
    ) {
        self.clock = clock
        self.notificationCenter = notificationCenter
    }

    // MARK: - Schedule

    func scheduleReminder(for task: EmberTask) async throws {
        guard let scheduledTime = task.scheduledTime, !task.isCompleted else {
            cancelReminder(for: task.id)
            return
        }

        guard let fireDate = reminderDate(dayDate: task.dayDate, scheduledTime: scheduledTime),
              fireDate > clock.now else {
            cancelReminder(for: task.id)
            return
        }

        let authorized: Bool
        switch await notificationCenter.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            authorized = true
        case .notDetermined:
            authorized = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        case .denied:
            authorized = false
        case .unknown:
            authorized = false
        }

        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Ember"
        content.body = "Focus: \(task.title)"
        content.sound = EmberPreferences.soundEnabled ? .default : nil

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: task.id),
            content: content,
            trigger: trigger
        )

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID(for: task.id)])
        try await notificationCenter.add(request)
    }

    // MARK: - Cancel

    func cancelReminder(for taskID: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationID(for: taskID)]
        )
    }

    static func cancelReminder(for taskID: UUID) {
        ReminderService.shared.cancelReminder(for: taskID)
    }

    // MARK: - Helpers

    func notificationID(for taskID: UUID) -> String {
        "ember-task-\(taskID.uuidString)"
    }

    func reminderDate(dayDate: Date, scheduledTime: Date) -> Date? {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components)
    }
}
