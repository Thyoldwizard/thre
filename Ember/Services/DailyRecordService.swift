// DailyRecordService.swift
import Foundation
import SwiftData

enum DailyRecordService {
    static func upsertRecord(for date: Date = DateService.shared.today, in context: ModelContext) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!

        let taskDescriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> { task in
                task.dayDate >= day && task.dayDate < nextDay
            }
        )

        let tasks: [EmberTask]
        do {
            tasks = try context.fetch(taskDescriptor)
        } catch {
            EmberLogger.records.error("Failed to fetch tasks for DailyRecord upsert", error)
            return
        }

        let summary = completionSummary(for: tasks)
        upsertRecord(
            date: day,
            taskCount: summary.taskCount,
            completedCount: summary.completedCount,
            in: context
        )
    }

    static func completionSummary(for tasks: [EmberTask]) -> (
        taskCount: Int,
        completedCount: Int,
        allThreeCompleted: Bool
    ) {
        let completedCount = tasks.filter { $0.isCompleted }.count
        return (
            taskCount: tasks.count,
            completedCount: completedCount,
            allThreeCompleted: isAllThreeCompleted(taskCount: tasks.count, completedCount: completedCount)
        )
    }

    static func isAllThreeCompleted(taskCount: Int, completedCount: Int) -> Bool {
        completedCount == 3 && taskCount == 3
    }

    static func upsertRecord(
        date: Date,
        taskCount: Int,
        completedCount: Int,
        in context: ModelContext
    ) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!

        let recordDescriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date >= day && record.date < nextDay
            }
        )

        do {
            if let existing = try context.fetch(recordDescriptor).first {
                existing.taskCount = taskCount
                existing.completedCount = completedCount
                existing.allThreeCompleted = isAllThreeCompleted(
                    taskCount: taskCount,
                    completedCount: completedCount
                )
            } else {
                let record = DailyRecord(
                    date: day,
                    taskCount: taskCount,
                    completedCount: completedCount
                )
                context.insert(record)
            }
            try context.save()
        } catch {
            EmberLogger.records.error("DailyRecord upsert failed", error)
        }
    }
}
