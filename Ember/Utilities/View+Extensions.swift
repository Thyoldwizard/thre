// View+Extensions.swift
import SwiftUI

extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply strikethrough with completed styling
    func completedStyle(_ isCompleted: Bool) -> some View {
        self
            .strikethrough(isCompleted, color: EmberColors.textDone)
            .foregroundStyle(isCompleted ? EmberColors.textDone : EmberColors.textPrimary)
    }
}

// MARK: - Collection safe subscript

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
