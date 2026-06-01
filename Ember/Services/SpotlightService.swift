// SpotlightService.swift

import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

enum SpotlightService {

    private static let domainIdentifier = "com.ember.focus.task"
    nonisolated(unsafe) private static var indexTask:   Task<Void, Never>?
    nonisolated(unsafe) private static var deindexTask: Task<Void, Never>?

    // MARK: - Index a single task

    static func index(_ task: EmberTask) {
        let taskID = task.id.uuidString
        let taskTitle = task.title
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = taskTitle
        attributeSet.contentDescription = task.isCompleted
            ? "Completed focus task"
            : "Focus task for \(formattedDate(task.dayDate))"
        attributeSet.keywords = ["ember", "focus", "task", taskTitle]
        attributeSet.displayName = taskTitle
        attributeSet.contentURL = URL(string: "ember://task/\(task.id.uuidString)")

        let item = CSSearchableItem(
            uniqueIdentifier: spotlightID(for: task.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        // Keep the index entry alive for 30 days so completed tasks are findable
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: task.dayDate)

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            indexTask = Task { @MainActor in
                if let error {
                    EmberLogger.records.error("Spotlight index failed for task \(taskID)", error)
                } else {
                    EmberLogger.records.debug("Spotlight indexed task: \(taskTitle)")
                }
            }
        }
    }

    // MARK: - Deindex a single task

    static func deindex(_ task: EmberTask) {
        deindex(id: task.id)
    }

    static func deindex(id: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [spotlightID(for: id)]
        ) { error in
            let taskID = id.uuidString
            deindexTask = Task { @MainActor in
                if let error {
                    EmberLogger.records.error("Spotlight deindex failed for task \(taskID)", error)
                } else {
                    EmberLogger.records.debug("Spotlight deindexed task id: \(taskID)")
                }
            }
        }
    }

    // MARK: - Reindex (update) a task's metadata

    /// Call after title edits, completion state changes, or subtask updates.
    static func reindex(_ task: EmberTask) {
        index(task)
    }

    // MARK: - Helpers

    /// Converts a Spotlight unique identifier back to a task UUID, if it has our domain prefix.
    static func taskID(fromSpotlightIdentifier identifier: String) -> UUID? {
        let prefix = "\(domainIdentifier)."
        guard identifier.hasPrefix(prefix) else { return nil }
        let uuidString = String(identifier.dropFirst(prefix.count))
        return UUID(uuidString: uuidString)
    }

    private static func spotlightID(for id: UUID) -> String {
        "\(domainIdentifier).\(id.uuidString)"
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
