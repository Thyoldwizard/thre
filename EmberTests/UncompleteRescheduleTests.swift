import XCTest
import SwiftData
@testable import Ember

@MainActor
final class UncompleteRescheduleTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - uncomplete sets state before scheduling

    func testUncompleteRevertsStateEvenIfReminderFails() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Test", displayOrder: 0, dayDate: day)
        task.isCompleted = true
        task.completionDate = Date()
        context.insert(task)

        // Use a past-fixed clock so scheduleReminder returns early (past date guard) without requesting
        // notification authorization — avoids a real UNUserNotificationCenter call in tests.
        let coordinator = TaskCompletionCoordinator(
            reminderService: ReminderService(clock: FixedClock(now: Date()))
        )
        await coordinator.uncomplete(task, in: context)

        XCTAssertFalse(task.isCompleted, "Task must be marked incomplete regardless of reminder outcome")
        XCTAssertNil(task.completionDate, "completionDate must be cleared on uncomplete")
    }

    func testUncompleteIsNoOpForAlreadyIncompleteTask() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Already incomplete", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(
            reminderService: ReminderService(clock: FixedClock(now: Date()))
        )
        await coordinator.uncomplete(task, in: context)

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completionDate)
    }

    // MARK: - Reminder reschedule with future scheduled time

    func testUncompleteWithFutureScheduleDoesNotThrow() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Future task", displayOrder: 0, dayDate: day)
        task.isCompleted = true
        task.completionDate = Date()
        task.scheduledTime = Date(timeIntervalSinceNow: 7200)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(
            reminderService: ReminderService(clock: FixedClock(now: Date()))
        )
        // Should not throw; UNUserNotificationCenter.requestAuthorization is called if not yet authorized.
        await coordinator.uncomplete(task, in: context)

        XCTAssertFalse(task.isCompleted)
    }
}
