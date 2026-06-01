// DateService.swift
import Foundation

// MARK: - Clock protocol

protocol EmberClock: Sendable {
    var now: Date { get }
}

struct SystemClock: EmberClock {
    var now: Date { Date() }
    static let continuous = SystemClock()
}

// MARK: - DateService

@MainActor
final class DateService {
    static let shared = DateService()

    let clock: any EmberClock
    let calendar: Calendar
    private let userDefaults: UserDefaults
    private let lastActiveDateKey = "lastActiveDate"

    init(clock: any EmberClock = SystemClock.continuous, calendar: Calendar = .current, userDefaults: UserDefaults = .standard) {
        self.clock = clock
        self.calendar = calendar
        self.userDefaults = userDefaults
    }

    nonisolated deinit {}

    var now: Date { clock.now }

    var today: Date {
        calendar.startOfDay(for: clock.now)
    }

    var lastActiveDate: Date? {
        get { userDefaults.object(forKey: lastActiveDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastActiveDateKey) }
    }

    func isNewDay() -> Bool {
        guard let last = lastActiveDate else { return true }
        return !calendar.isDate(last, inSameDayAs: clock.now)
    }

    func recordActiveDate() {
        lastActiveDate = today
    }

    var yesterday: Date {
        calendar.date(byAdding: .day, value: -1, to: today)!
    }
}
