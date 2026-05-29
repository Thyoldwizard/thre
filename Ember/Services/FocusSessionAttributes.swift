// FocusSessionAttributes.swift
// Step 8.2 — Shared between main app and EmberWidgetExtension.
//
// XCODE SETUP REQUIRED:
//   Add this file to the EmberWidgetExtension target via File Inspector →
//   Target Membership. Both targets must compile it.
//
import ActivityKit
import Foundation

/// Live Activity attributes for an active focus session on a single task.
struct FocusSessionAttributes: nonisolated ActivityAttributes, Sendable {

    // MARK: - Fixed attributes (set at start, never mutated)

    /// Persistent identifier of the task being focused on.
    let taskID: String

    /// Display title of the task (shown on lock screen + Dynamic Island).
    let taskTitle: String

    /// Moment the session began, used to show elapsed time.
    let startedAt: Date

    // MARK: - Dynamic content state (updated as tasks are completed)

    struct ContentState: nonisolated Codable, nonisolated Hashable, Sendable {
        /// Number of today's tasks that are complete (0–3).
        var completedCount: Int
    }
}
