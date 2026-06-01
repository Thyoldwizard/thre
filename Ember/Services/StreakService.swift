// StreakService.swift
import Foundation
import SwiftData

class StreakService {
    static let shared = StreakService()

    /// Computes the current consecutive-day streak from today's DailyRecords.
    /// Counts backwards from today, requiring allThreeCompleted == true on each day.
    /// Treat isFrozen == true days as transparent — streak passes through them without counting as completed.
    func currentStreak(from records: [DailyRecord]) -> Int {
        let calendar = DateService.shared.calendar
        var recordMap: [Date: DailyRecord] = [:]
        for record in records {
            let normalizedDate = calendar.startOfDay(for: record.date)
            recordMap[normalizedDate] = record
        }

        guard !recordMap.isEmpty else { return 0 }

        var streak = 0
        var checkDate = DateService.shared.today

        while true {
            if let record = recordMap[checkDate] {
                if record.allThreeCompleted {
                    streak += 1
                } else if record.isFrozen {
                    // Transparent day: do not increment streak, but do not break either
                } else {
                    // Not completed, not frozen.
                    if checkDate == DateService.shared.today {
                        // Today is ongoing, not a gap yet.
                    } else {
                        // Past day gap - streak broken
                        break
                    }
                }
            } else {
                // No record found.
                if checkDate == DateService.shared.today {
                    // Today is ongoing, not a gap yet.
                } else {
                    // Past day gap - streak broken
                    break
                }
            }
            // Move back 1 day
            guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDate
        }

        return streak
    }

    /// Computes the longest ever consecutive run across all DailyRecords.
    /// Treat isFrozen == true days as transparent.
    func longestStreak(from records: [DailyRecord]) -> Int {
        let calendar = DateService.shared.calendar
        var recordMap: [Date: DailyRecord] = [:]
        var minDate: Date?
        var maxDate: Date?

        for record in records {
            let normalizedDate = calendar.startOfDay(for: record.date)
            recordMap[normalizedDate] = record
            if let currentMin = minDate {
                minDate = min(currentMin, normalizedDate)
            } else {
                minDate = normalizedDate
            }
            if let currentMax = maxDate {
                maxDate = max(currentMax, normalizedDate)
            } else {
                maxDate = normalizedDate
            }
        }

        guard let start = minDate, let end = maxDate else { return 0 }

        var longest = 0
        var current = 0
        var checkDate = start

        while checkDate <= end {
            if let record = recordMap[checkDate] {
                if record.allThreeCompleted {
                    current += 1
                    longest = max(longest, current)
                } else if record.isFrozen {
                    // Transparent day: do not increment or reset
                } else {
                    current = 0 // Gap!
                }
            } else {
                current = 0 // Gap!
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDate
        }

        return longest
    }

    /// Total count of days where all 3 tasks were completed.
    func totalCompletedDays(from records: [DailyRecord]) -> Int {
        records.filter { $0.allThreeCompleted }.count
    }
}
