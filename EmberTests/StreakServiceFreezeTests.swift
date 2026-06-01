// StreakServiceFreezeTests.swift
import XCTest
import SwiftData
@testable import Ember

@MainActor
final class StreakServiceFreezeTests: XCTestCase {

    func testGapWithFreezePasses() {
        let calendar = DateService.shared.calendar
        let today = DateService.shared.today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let records = [
            DailyRecord(date: today, taskCount: 3, completedCount: 3, isFrozen: false),
            DailyRecord(date: yesterday, taskCount: 0, completedCount: 0, isFrozen: true),
            DailyRecord(date: twoDaysAgo, taskCount: 3, completedCount: 3, isFrozen: false),
            DailyRecord(date: threeDaysAgo, taskCount: 3, completedCount: 3, isFrozen: false)
        ]

        XCTAssertEqual(StreakService.shared.currentStreak(from: records), 3)
        XCTAssertEqual(StreakService.shared.longestStreak(from: records), 3)
    }

    func testTwoGapsWithOneFreezeBreaks() {
        let calendar = DateService.shared.calendar
        let today = DateService.shared.today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        // Gap on yesterday (neither completed nor frozen), freeze on twoDaysAgo
        let records = [
            DailyRecord(date: today, taskCount: 3, completedCount: 3, isFrozen: false),
            DailyRecord(date: yesterday, taskCount: 3, completedCount: 1, isFrozen: false), // Gap
            DailyRecord(date: twoDaysAgo, taskCount: 0, completedCount: 0, isFrozen: true),  // Frozen
            DailyRecord(date: threeDaysAgo, taskCount: 3, completedCount: 3, isFrozen: false) // Completed
        ]

        XCTAssertEqual(StreakService.shared.currentStreak(from: records), 1)
        XCTAssertEqual(StreakService.shared.longestStreak(from: records), 1)
    }

    func testMultipleFreezesAndCompletions() {
        let calendar = DateService.shared.calendar
        let today = DateService.shared.today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!

        let records = [
            DailyRecord(date: today, taskCount: 3, completedCount: 3, isFrozen: false),
            DailyRecord(date: yesterday, taskCount: 0, completedCount: 0, isFrozen: true),
            DailyRecord(date: twoDaysAgo, taskCount: 3, completedCount: 3, isFrozen: false),
            DailyRecord(date: threeDaysAgo, taskCount: 0, completedCount: 0, isFrozen: true),
            DailyRecord(date: fourDaysAgo, taskCount: 3, completedCount: 3, isFrozen: false)
        ]

        XCTAssertEqual(StreakService.shared.currentStreak(from: records), 3)
        XCTAssertEqual(StreakService.shared.longestStreak(from: records), 3)
    }
}
