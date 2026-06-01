import XCTest
@testable import Ember

@MainActor
final class EmberTests: XCTestCase {

    func testDailyRecordServiceSummarizesPartialAndPerfectDays() {
        let day = Calendar.current.startOfDay(for: Date())
        let first = EmberTask(title: "First", displayOrder: 0, dayDate: day)
        let second = EmberTask(title: "Second", displayOrder: 1, dayDate: day)
        let third = EmberTask(title: "Third", displayOrder: 2, dayDate: day)
        first.isCompleted = true
        second.isCompleted = true

        var summary = DailyRecordService.completionSummary(for: [first, second, third])
        XCTAssertEqual(summary.taskCount, 3)
        XCTAssertEqual(summary.completedCount, 2)
        XCTAssertFalse(summary.allThreeCompleted)

        third.isCompleted = true

        summary = DailyRecordService.completionSummary(for: [first, second, third])
        XCTAssertEqual(summary.taskCount, 3)
        XCTAssertEqual(summary.completedCount, 3)
        XCTAssertTrue(summary.allThreeCompleted)
    }

    func testDailyRecordNormalizesDateAndPerfectState() {
        let calendar = Calendar.current
        let now = Date()
        let record = DailyRecord(date: now, taskCount: 3, completedCount: 3)

        XCTAssertEqual(record.date, calendar.startOfDay(for: now))
        XCTAssertEqual(record.taskCount, 3)
        XCTAssertEqual(record.completedCount, 3)
        XCTAssertTrue(record.allThreeCompleted)
        XCTAssertFalse(DailyRecordService.isAllThreeCompleted(taskCount: 2, completedCount: 2))
    }

    func testStreakServiceCountsOnlyPerfectConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let records = [
            DailyRecord(date: today, taskCount: 3, completedCount: 3),
            DailyRecord(date: yesterday, taskCount: 3, completedCount: 3),
            DailyRecord(date: twoDaysAgo, taskCount: 3, completedCount: 2),
            DailyRecord(date: threeDaysAgo, taskCount: 3, completedCount: 3)
        ]

        XCTAssertEqual(StreakService.shared.currentStreak(from: records), 2)
        XCTAssertEqual(StreakService.shared.longestStreak(from: records), 2)
        XCTAssertEqual(StreakService.shared.totalCompletedDays(from: records), 3)
    }
}
