import XCTest
@testable import Ember

@MainActor
final class StreakServiceNonFreezeTests: XCTestCase {

    private let service = StreakService()
    private let calendar = Calendar.current

    private func today() -> Date { DateService.shared.today }
    private func day(offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today())!
    }

    // MARK: - Today incomplete must not break streak

    func testTodayZeroOfThreeDoesNotBreakStreak() {
        let records = [
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: day(offset: -2), taskCount: 3, completedCount: 3),
            DailyRecord(date: today(), taskCount: 3, completedCount: 0)
        ]
        // Yesterday+day before = 2-day streak; today is ongoing (0 complete, not frozen) — must not break
        XCTAssertEqual(service.currentStreak(from: records), 2,
                       "An incomplete today must not break a past streak")
    }

    func testTodayOneOfThreeDoesNotBreakStreak() {
        let records = [
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: today(), taskCount: 3, completedCount: 1)
        ]
        XCTAssertEqual(service.currentStreak(from: records), 1)
    }

    func testTodayTwoOfThreeDoesNotBreakStreak() {
        let records = [
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: today(), taskCount: 3, completedCount: 2)
        ]
        XCTAssertEqual(service.currentStreak(from: records), 1)
    }

    func testTodayCompleteCountsInStreak() {
        let records = [
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: today(), taskCount: 3, completedCount: 3)
        ]
        XCTAssertEqual(service.currentStreak(from: records), 2)
    }

    // MARK: - Yesterday complete + today incomplete boundary

    func testYesterdayCompleteAndTodayIncompleteGivesYesterdayStreak() {
        let records = [
            DailyRecord(date: day(offset: -2), taskCount: 3, completedCount: 3),
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: today(), taskCount: 3, completedCount: 0)
        ]
        XCTAssertEqual(service.currentStreak(from: records), 2,
                       "Streak counts completed past days; today-incomplete is transparent")
    }

    func testNoRecordsTodayStreakCountsFromYesterday() {
        let records = [
            DailyRecord(date: day(offset: -1), taskCount: 3, completedCount: 3),
            DailyRecord(date: day(offset: -2), taskCount: 3, completedCount: 3)
        ]
        XCTAssertEqual(service.currentStreak(from: records), 2,
                       "When today has no record, streak counts back through completed past days")
    }

    // MARK: - completionSummary edge counts

    func testCompletionSummaryZeroTasks() {
        let summary = DailyRecordService.completionSummary(for: [])
        XCTAssertEqual(summary.taskCount, 0)
        XCTAssertEqual(summary.completedCount, 0)
        XCTAssertFalse(summary.allThreeCompleted)
    }

    func testCompletionSummaryOneTasks() {
        let task = EmberTask(title: "A", displayOrder: 0, dayDate: Date())
        task.isCompleted = true
        let summary = DailyRecordService.completionSummary(for: [task])
        XCTAssertEqual(summary.taskCount, 1)
        XCTAssertEqual(summary.completedCount, 1)
        XCTAssertFalse(summary.allThreeCompleted, "Completing 1 of 1 is not allThreeCompleted")
    }

    func testCompletionSummaryFourTasks() {
        let day = Calendar.current.startOfDay(for: Date())
        let tasks = (0..<4).map { i -> EmberTask in
            let t = EmberTask(title: "\(i)", displayOrder: i, dayDate: day)
            t.isCompleted = true
            return t
        }
        let summary = DailyRecordService.completionSummary(for: tasks)
        XCTAssertEqual(summary.taskCount, 4)
        XCTAssertFalse(summary.allThreeCompleted, "4 tasks completed is not allThreeCompleted (requires exactly 3)")
    }
}
