import AppIntents
import Foundation
import SwiftData

struct ShowTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Today's Three"
    static let description = IntentDescription("Summarize today's Ember focus slots.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let context = try EmberIntentStore.makeContext()
        let tasks = try EmberIntentStore.todaysTasks(in: context)
        let completedCount = tasks.filter(\.isCompleted).count
        let summary = Self.summary(for: tasks, completedCount: completedCount)

        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }

    private static func summary(for tasks: [EmberTask], completedCount: Int) -> String {
        guard !tasks.isEmpty else {
            return "You have no focus slots set for today."
        }

        let openTasks = tasks.filter { !$0.isCompleted }
        let nextLine: String
        if let nextTask = openTasks.first {
            nextLine = "Next up is: \(nextTask.title)."
        } else {
            nextLine = "All three are complete."
        }

        let slotLines = tasks
            .prefix(3)
            .enumerated()
            .map { index, task in
                let status = task.isCompleted ? "done" : "open"
                return "Slot \(index + 1): \(task.title), \(status)."
            }
            .joined(separator: " ")

        return "You have \(completedCount) of 3 done. \(nextLine) \(slotLines)"
    }
}
