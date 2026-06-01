import XCTest
import SwiftData
@testable import Ember

@MainActor
final class TaskCompletionCoordinatorTests: XCTestCase {

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

    // MARK: - complete

    func testCompleteHappyPath() async {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Test task", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(reminderService: ReminderService(clock: FixedClock(now: Date())))
        await coordinator.complete(task, in: context)

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completionDate)
    }

    func testCompleteIsIdempotent() async {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Test task", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(reminderService: ReminderService(clock: FixedClock(now: Date())))
        await coordinator.complete(task, in: context)
        let firstDate = task.completionDate

        // Second call should be a no-op
        await coordinator.complete(task, in: context)

        XCTAssertEqual(task.completionDate, firstDate)
    }

    func testCompleteUpdatesCompletionDate() async {
        let before = Date()
        let day = Calendar.current.startOfDay(for: before)
        let task = EmberTask(title: "Test", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(reminderService: ReminderService(clock: FixedClock(now: before)))
        await coordinator.complete(task, in: context)
        let after = Date()

        XCTAssertNotNil(task.completionDate)
        if let completionDate = task.completionDate {
            XCTAssertGreaterThanOrEqual(completionDate, before)
            XCTAssertLessThanOrEqual(completionDate, after)
        }
    }

    // MARK: - uncomplete

    func testUncompleteRevertsState() async {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Test task", displayOrder: 0, dayDate: day)
        task.isCompleted = true
        task.completionDate = Date()
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(reminderService: ReminderService(clock: FixedClock(now: Date())))
        await coordinator.uncomplete(task, in: context)

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completionDate)
    }

    func testUncompleteIsIdempotentWhenAlreadyIncomplete() async {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "Test", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator(reminderService: ReminderService(clock: FixedClock(now: Date())))
        await coordinator.uncomplete(task, in: context)

        XCTAssertFalse(task.isCompleted)
    }

    // MARK: - deleteTask

    func testDeleteRemovesTask() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let task = EmberTask(title: "To delete", displayOrder: 0, dayDate: day)
        context.insert(task)

        let coordinator = TaskCompletionCoordinator()
        coordinator.deleteTask(task, in: context)

        let remaining = try context.fetch(FetchDescriptor<EmberTask>())
        XCTAssertTrue(remaining.isEmpty)
    }

    func testDeleteCreatesOrUpdatesDailyRecord() async throws {
        let day = Calendar.current.startOfDay(for: Date())
        let t1 = EmberTask(title: "A", displayOrder: 0, dayDate: day)
        let t2 = EmberTask(title: "B", displayOrder: 1, dayDate: day)
        context.insert(t1)
        context.insert(t2)

        let coordinator = TaskCompletionCoordinator()
        coordinator.deleteTask(t1, in: context)

        let records = try context.fetch(FetchDescriptor<DailyRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.taskCount, 1)
    }
}
