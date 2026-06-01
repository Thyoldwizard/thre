// DailyRecord.swift
import Foundation
import SwiftData

@Model
final class DailyRecord {
    var id: UUID
    @Attribute(.unique) var date: Date // Normalized to midnight
    var allThreeCompleted: Bool
    var taskCount: Int
    var completedCount: Int
    var isFrozen: Bool

    init(date: Date, taskCount: Int, completedCount: Int, isFrozen: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.taskCount = taskCount
        self.completedCount = completedCount
        self.allThreeCompleted = (completedCount == 3 && taskCount == 3)
        self.isFrozen = isFrozen
    }
}
