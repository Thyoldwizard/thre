// ScheduledSessionWatcher.swift
import Foundation
import SwiftData

@MainActor
final class ScheduledSessionWatcher {

    // MARK: - Init

    init() {}

    // MARK: - Public

    /// Evaluate all tasks in the context and auto-start if conditions are met.
    /// Call from scene-phase changes (foreground) and on first app appear.
    func evaluate(tasks: [EmberTask], completedCount: Int) async {
        guard EmberPreferences.autoStartScheduledSessions else { return }
        guard !FocusSessionService.shared.hasActiveSession else { return }

        let now = DateService.shared.now
        let windowStart = now.addingTimeInterval(-600)   // 10 min before
        let windowEnd   = now.addingTimeInterval(600)    // 10 min after

        for task in tasks {
            guard !task.isCompleted,
                  let scheduled = task.scheduledTime,
                  scheduled >= windowStart,
                  scheduled <= windowEnd,
                  !EmberPreferences.hasAutoSessionBeenDismissed(for: task.id)
            else { continue }

            await FocusSessionService.shared.start(for: task, completedCount: completedCount)
            return  // only one session at a time
        }
    }
}
