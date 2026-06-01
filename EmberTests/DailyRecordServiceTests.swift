import XCTest
import SwiftData
@testable import Ember

@MainActor
final class DailyRecordServiceTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    let day = Calendar.current.startOfDay(for: Date())

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

    // MARK: - create-when-absent

    func testCreatesRecordWhenNoneExists() throws {
        let task = EmberTask(title: "A", displayOrder: 0, dayDate: day)
        context.insert(task)

        DailyRecordService.upsertRecord(for: day, in: context)

        let records = try context.fetch(FetchDescriptor<DailyRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.taskCount, 1)
        XCTAssertEqual(records.first?.completedCount, 0)
    }

    // MARK: - update-existing

    func testUpdatesExistingRecord() throws {
        let task = EmberTask(title: "A", displayOrder: 0, dayDate: day)
        context.insert(task)
        DailyRecordService.upsertRecord(for: day, in: context)

        task.isCompleted = true
        DailyRecordService.upsertRecord(for: day, in: context)

        let records = try context.fetch(FetchDescriptor<DailyRecord>())
        XCTAssertEqual(records.count, 1, "Should update in-place, not create a duplicate")
        XCTAssertEqual(records.first?.completedCount, 1)
    }

    // MARK: - day-boundary predicate

    func testDoesNotCountTasksFromOtherDays() throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        let todayTask = EmberTask(title: "Today", displayOrder: 0, dayDate: day)
        let yesterdayTask = EmberTask(title: "Yesterday", displayOrder: 0, dayDate: yesterday)
        context.insert(todayTask)
        context.insert(yesterdayTask)

        DailyRecordService.upsertRecord(for: day, in: context)

        let records = try context.fetch(FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.date >= day }
        ))
        XCTAssertEqual(records.first?.taskCount, 1, "Only today's task should be counted")
    }

    // MARK: - idempotency

    func testIdempotentDoubleCall() throws {
        let task = EmberTask(title: "A", displayOrder: 0, dayDate: day)
        context.insert(task)

        DailyRecordService.upsertRecord(for: day, in: context)
        DailyRecordService.upsertRecord(for: day, in: context)

        let records = try context.fetch(FetchDescriptor<DailyRecord>())
        XCTAssertEqual(records.count, 1, "Two upserts for the same day must produce exactly one record")
    }

    // MARK: - completionSummary

    func testCompletionSummaryAllThreeCompleted() {
        let tasks = (0..<3).map { i -> EmberTask in
            let t = EmberTask(title: "\(i)", displayOrder: i, dayDate: day)
            t.isCompleted = true
            return t
        }
        let summary = DailyRecordService.completionSummary(for: tasks)
        XCTAssertTrue(summary.allThreeCompleted)
        XCTAssertEqual(summary.completedCount, 3)
    }

    func testCompletionSummaryPartial() {
        let tasks = (0..<3).map { EmberTask(title: "\($0)", displayOrder: $0, dayDate: day) }
        let summary = DailyRecordService.completionSummary(for: tasks)
        XCTAssertFalse(summary.allThreeCompleted)
        XCTAssertEqual(summary.completedCount, 0)
        XCTAssertEqual(summary.taskCount, 3)
    }

    func testCompletionSummaryFewerThanThreeTasks() {
        let tasks = [EmberTask(title: "A", displayOrder: 0, dayDate: day)]
        tasks[0].isCompleted = true
        let summary = DailyRecordService.completionSummary(for: tasks)
        XCTAssertFalse(summary.allThreeCompleted, "allThreeCompleted requires exactly 3 completed tasks")
    }
}
