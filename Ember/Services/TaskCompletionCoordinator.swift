// TaskCompletionCoordinator.swift
import Foundation
import SwiftData

@MainActor
final class TaskCompletionCoordinator {
    static let shared = TaskCompletionCoordinator()

    private let reminderService: ReminderService

    init(reminderService: ReminderService = .shared) {
        self.reminderService = reminderService
    }

    // MARK: - Complete

    func complete(_ task: EmberTask, in context: ModelContext) async {
        guard !task.isCompleted else { return }

        task.isCompleted = true
        task.completionDate = DateService.shared.now
        reminderService.cancelReminder(for: task.id)
        DailyRecordService.upsertRecord(for: task.dayDate, in: context)
        // 10.1 — update Spotlight entry with completed state
        SpotlightService.reindex(task)
        EmberLogger.records.info("Task completed: \(task.title)")

        // 8.7 — Update Live Activity if a session is active for this task
        if FocusSessionService.shared.isActive(for: task.id.uuidString) {
            // Fetch updated count from context
            let today = DateService.shared.today
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            let descriptor = FetchDescriptor<EmberTask>(
                predicate: #Predicate { $0.dayDate >= today && $0.dayDate < tomorrow }
            )
            let allTodayTasks = (try? context.fetch(descriptor)) ?? []
            let completedCount = allTodayTasks.filter { $0.isCompleted }.count
            let allDone = allTodayTasks.count == 3 && completedCount == 3

            if allDone {
                await FocusSessionService.shared.end()
            } else {
                await FocusSessionService.shared.update(completedCount: completedCount)
            }
        }
    }

    // MARK: - Uncomplete

    func uncomplete(_ task: EmberTask, in context: ModelContext) async {
        guard task.isCompleted else { return }

        task.isCompleted = false
        task.completionDate = nil
        DailyRecordService.upsertRecord(for: task.dayDate, in: context)
        // 10.1 — update Spotlight entry with incomplete state
        SpotlightService.reindex(task)

        do {
            try await reminderService.scheduleReminder(for: task)
        } catch {
            EmberLogger.reminders.error("Failed to reschedule reminder on uncomplete", error)
        }
        EmberLogger.records.info("Task uncompleted: \(task.title)")
    }

    // MARK: - Delete

    func deleteTask(_ task: EmberTask, in context: ModelContext) {
        let recordDate = task.dayDate
        reminderService.cancelReminder(for: task.id)
        // 10.1 — remove from Spotlight before deletion
        SpotlightService.deindex(task)
        context.delete(task)
        DailyRecordService.upsertRecord(for: recordDate, in: context)
        EmberLogger.records.info("Task deleted")
    }

    // MARK: - Schedule reminder

    func scheduleReminder(for task: EmberTask) async {
        do {
            try await reminderService.scheduleReminder(for: task)
        } catch {
            EmberLogger.reminders.error("Failed to schedule reminder", error)
        }
    }
}
