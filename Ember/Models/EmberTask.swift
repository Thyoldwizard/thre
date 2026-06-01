// EmberTask.swift
import Foundation
import SwiftData

@Model
final class EmberTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var creationDate: Date
    var completionDate: Date?
    var isCarriedForward: Bool
    var displayOrder: Int // 0, 1, or 2 — maps to card slot
    var dayDate: Date // Normalized to midnight, used for grouping by day
    var scheduledTime: Date? // Optional time of day for the task

    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    var subtasks: [Subtask]

    init(
        title: String,
        displayOrder: Int,
        dayDate: Date,
        isCarriedForward: Bool = false,
        scheduledTime: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.creationDate = Date()
        self.completionDate = nil
        self.isCarriedForward = isCarriedForward
        self.displayOrder = displayOrder
        self.dayDate = Calendar.current.startOfDay(for: dayDate)
        self.subtasks = []
        self.scheduledTime = scheduledTime
    }
}
