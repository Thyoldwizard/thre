import XCTest
@testable import Ember

@MainActor
final class ReminderServiceDateTests: XCTestCase {
    private enum ReminderTestError: Error {
        case addFailed
    }

    private final class FakeReminderNotificationCenter: ReminderNotificationCenter {
        var status: ReminderAuthorizationStatus
        var requestAuthorizationResult = true
        var addError: Error?
        private(set) var requestedOptions: UNAuthorizationOptions?
        private(set) var removedIdentifiers: [[String]] = []
        private(set) var addedRequests: [UNNotificationRequest] = []

        init(status: ReminderAuthorizationStatus) {
            self.status = status
        }

        func authorizationStatus() async -> ReminderAuthorizationStatus {
            status
        }

        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            requestedOptions = options
            return requestAuthorizationResult
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            removedIdentifiers.append(identifiers)
        }

        func add(_ request: UNNotificationRequest) async throws {
            if let addError {
                throw addError
            }
            addedRequests.append(request)
        }
    }

    private func taskFor(dayOffset: Int, hourOffset: Int) -> EmberTask {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayDate = cal.date(byAdding: .day, value: dayOffset, to: today)!
        let task = EmberTask(title: "Test task", displayOrder: 0, dayDate: dayDate)

        var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
        comps.hour = 12 + hourOffset
        comps.minute = 0
        task.scheduledTime = cal.date(from: comps)
        return task
    }

    func testReminderDateCombinesDayAndTime() {
        let service = ReminderService(clock: FixedClock(now: Date()))
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        var timeComps = DateComponents()
        timeComps.hour = 14
        timeComps.minute = 30
        let scheduledTime = cal.date(from: timeComps) ?? Date()

        let fireDate = service.reminderDate(dayDate: tomorrow, scheduledTime: scheduledTime)

        XCTAssertNotNil(fireDate)
        let fireDateComps = cal.dateComponents([.hour, .minute], from: fireDate!)
        XCTAssertEqual(fireDateComps.hour, 14)
        XCTAssertEqual(fireDateComps.minute, 30)
    }

    func testPastFireDateSkipsScheduling() async throws {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let day = Calendar.current.startOfDay(for: pastDate)
        let task = EmberTask(title: "Past", displayOrder: 0, dayDate: day)
        task.scheduledTime = pastDate

        let service = ReminderService(clock: FixedClock(now: Date()))
        let fireDate = service.reminderDate(dayDate: task.dayDate, scheduledTime: task.scheduledTime!)
        XCTAssertNotNil(fireDate)
        XCTAssertLessThan(fireDate!, Date(), "Fire date for a past task must be in the past so scheduling is skipped")

        // Returns early without throwing
        try await service.scheduleReminder(for: task)
    }

    func testCompletedTaskSkipsScheduling() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Done", displayOrder: 0, dayDate: day)
        task.isCompleted = true
        task.scheduledTime = Date(timeIntervalSinceNow: 3600)

        let service = ReminderService(clock: FixedClock(now: Date()))
        try await service.scheduleReminder(for: task)
        XCTAssertTrue(task.isCompleted, "Task should remain completed after scheduling attempt")
    }

    func testNoScheduledTimeSkipsScheduling() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Unscheduled", displayOrder: 0, dayDate: day)
        // no scheduledTime set

        let service = ReminderService(clock: FixedClock(now: Date()))
        try await service.scheduleReminder(for: task)
        XCTAssertNil(task.scheduledTime, "Unscheduled task must have no scheduledTime after scheduling attempt")
    }

    func testNotificationIDFormat() {
        let service = ReminderService()
        let id = UUID()
        let notifID = service.notificationID(for: id)
        XCTAssertEqual(notifID, "ember-task-\(id.uuidString)")
    }

    func testClockInjectionAffectsPastCheck() {
        // A fire date that's in the "future" relative to the injected clock
        let cal = Calendar.current
        let fixedPast = Date(timeIntervalSince1970: 1_000_000) // very old date as "now"
        let service = ReminderService(clock: FixedClock(now: fixedPast))

        // Any real future date should be > fixedPast
        let futureDay = cal.date(byAdding: .day, value: 1, to: Date())!
        var comps = cal.dateComponents([.year, .month, .day], from: futureDay)
        comps.hour = 12
        let scheduledTime = cal.date(from: comps)!

        let fireDate = service.reminderDate(dayDate: futureDay, scheduledTime: scheduledTime)
        XCTAssertNotNil(fireDate)
        XCTAssertGreaterThan(fireDate!, fixedPast)
    }

    func testAuthorizedSchedulesAndReplacesExistingReminder() async throws {
        let center = FakeReminderNotificationCenter(status: .authorized)
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 0)

        try await service.scheduleReminder(for: task)

        let expectedID = service.notificationID(for: task.id)
        XCTAssertEqual(center.removedIdentifiers, [[expectedID]])
        XCTAssertEqual(center.addedRequests.count, 1)
        XCTAssertEqual(center.addedRequests.first?.identifier, expectedID)
        XCTAssertNil(center.requestedOptions)
    }

    func testNotDeterminedRequestsAuthorizationAndSchedulesWhenGranted() async throws {
        let center = FakeReminderNotificationCenter(status: .notDetermined)
        center.requestAuthorizationResult = true
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 0)

        try await service.scheduleReminder(for: task)

        XCTAssertEqual(center.requestedOptions, [.alert, .sound, .badge])
        XCTAssertEqual(center.addedRequests.count, 1)
    }

    func testNotDeterminedRequestsAuthorizationAndSkipsWhenDenied() async throws {
        let center = FakeReminderNotificationCenter(status: .notDetermined)
        center.requestAuthorizationResult = false
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 0)

        try await service.scheduleReminder(for: task)

        XCTAssertEqual(center.requestedOptions, [.alert, .sound, .badge])
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertTrue(center.removedIdentifiers.isEmpty)
    }

    func testDeniedSkipsWithoutRequestingAuthorizationOrScheduling() async throws {
        let center = FakeReminderNotificationCenter(status: .denied)
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 0)

        try await service.scheduleReminder(for: task)

        XCTAssertNil(center.requestedOptions)
        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertTrue(center.removedIdentifiers.isEmpty)
    }

    func testSchedulingFailurePropagates() async throws {
        let center = FakeReminderNotificationCenter(status: .authorized)
        center.addError = ReminderTestError.addFailed
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 0)

        do {
            try await service.scheduleReminder(for: task)
            XCTFail("Expected scheduling to throw")
        } catch ReminderTestError.addFailed {
            XCTAssertEqual(center.addedRequests.count, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScheduledRequestPayloadMatchesTaskAndSoundPreference() async throws {
        EmberPreferences.soundEnabled = false
        defer { UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.soundEnabled) }

        let center = FakeReminderNotificationCenter(status: .authorized)
        let service = ReminderService(clock: FixedClock(now: Date()), notificationCenter: center)
        let task = taskFor(dayOffset: 1, hourOffset: 2)

        try await service.scheduleReminder(for: task)

        let request = try XCTUnwrap(center.addedRequests.first)
        XCTAssertEqual(request.identifier, service.notificationID(for: task.id))
        XCTAssertEqual(request.content.title, "Ember")
        XCTAssertEqual(request.content.body, "Focus: \(task.title)")
        XCTAssertNil(request.content.sound)

        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        let fireDate = try XCTUnwrap(service.reminderDate(dayDate: task.dayDate, scheduledTime: task.scheduledTime!))
        let expectedComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        XCTAssertEqual(trigger.dateComponents.year, expectedComponents.year)
        XCTAssertEqual(trigger.dateComponents.month, expectedComponents.month)
        XCTAssertEqual(trigger.dateComponents.day, expectedComponents.day)
        XCTAssertEqual(trigger.dateComponents.hour, expectedComponents.hour)
        XCTAssertEqual(trigger.dateComponents.minute, expectedComponents.minute)
    }
}
