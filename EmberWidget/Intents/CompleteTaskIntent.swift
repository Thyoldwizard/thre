import AppIntents
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

enum EmberIntentError: Error, LocalizedError {
    case appGroupUnavailable
    case invalidTaskID
    case taskNotFound

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            "Ember's shared store is unavailable."
        case .invalidTaskID:
            "That focus could not be identified."
        case .taskNotFound:
            "That focus is no longer available."
        }
    }
}

enum EmberIntentStore {
    static let appGroupID = "group.com.ember.focus"
    static let pendingAddTaskTitleKey = "ember.pendingAddTaskTitle"

    @MainActor
    static func makeContext() throws -> ModelContext {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw EmberIntentError.appGroupUnavailable
        }

        let schema = Schema([EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self])
        let storeURL = groupURL.appendingPathComponent("Ember.store")
        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @MainActor
    static func task(with id: UUID, in context: ModelContext) throws -> EmberTask {
        let descriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> { task in
                task.id == id
            }
        )

        guard let task = try context.fetch(descriptor).first else {
            throw EmberIntentError.taskNotFound
        }
        return task
    }

    @MainActor
    static func todaysTasks(in context: ModelContext) throws -> [EmberTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let descriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> { task in
                task.dayDate >= today && task.dayDate < tomorrow
            },
            sortBy: [SortDescriptor(\EmberTask.displayOrder)]
        )
        return try context.fetch(descriptor)
    }

    @MainActor
    static func upsertDailyRecord(for date: Date, in context: ModelContext) throws {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let taskDescriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> { task in
                task.dayDate >= day && task.dayDate < nextDay
            }
        )
        let tasks = try context.fetch(taskDescriptor)
        let completedCount = tasks.filter(\.isCompleted).count

        let recordDescriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date >= day && record.date < nextDay
            }
        )

        if let existing = try context.fetch(recordDescriptor).first {
            existing.taskCount = tasks.count
            existing.completedCount = completedCount
            existing.allThreeCompleted = tasks.count == 3 && completedCount == 3
        } else {
            context.insert(
                DailyRecord(
                    date: day,
                    taskCount: tasks.count,
                    completedCount: completedCount
                )
            )
        }
    }

    static func storePendingAddTitle(_ title: String) {
        UserDefaults(suiteName: appGroupID)?.set(title, forKey: pendingAddTaskTitleKey)
    }
}

struct CompleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Focus Done"
    static let description = IntentDescription("Complete one of today's Ember focus slots.")
    static let openAppWhenRun = false

    @Parameter(title: "Focus ID")
    var taskID: String

    init() {
        taskID = ""
    }

    init(taskID: String) {
        self.taskID = taskID
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let id = UUID(uuidString: taskID) else {
            throw EmberIntentError.invalidTaskID
        }

        let context = try EmberIntentStore.makeContext()
        let task = try EmberIntentStore.task(with: id, in: context)

        if !task.isCompleted {
            task.isCompleted = true
            task.completionDate = Date()
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["ember-task-\(task.id.uuidString)"]
            )
            try EmberIntentStore.upsertDailyRecord(for: task.dayDate, in: context)
            try context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "Marked \(task.title) done.")
    }
}
