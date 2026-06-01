// Reflection.swift
import Foundation
import SwiftData

@Model
final class Reflection {
    var id: UUID
    @Attribute(.unique) var date: Date // Normalized to midnight
    var text: String
    var createdAt: Date

    init(date: Date, text: String) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
        self.createdAt = Date()
    }
}
