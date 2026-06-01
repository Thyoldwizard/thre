// Subtask.swift
import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var displayOrder: Int

    @Relationship var task: EmberTask?

    init(title: String, displayOrder: Int) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.displayOrder = displayOrder
    }
}
