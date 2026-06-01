// FocusSessionService.swift
import Foundation
import ActivityKit

@MainActor
final class FocusSessionService {

    static let shared = FocusSessionService()

    // MARK: - State

    /// The task whose session is currently live. Nil when no session is active.
    private(set) var activeTaskID: String?

    // MARK: - Private

    private var liveActivityID: String?

    // MARK: - Public interface

    /// Returns true if a session is currently active for the given task ID.
    func isActive(for taskID: String) -> Bool {
        activeTaskID == taskID
    }

    /// Returns true if any session is currently active.
    var hasActiveSession: Bool { activeTaskID != nil }

    /// Start a new Live Activity for the given task.
    /// No-ops if a session is already active or ActivityKit is unavailable.
    func start(for task: EmberTask, completedCount: Int = 0) async {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            EmberLogger.records.info("Live Activities not enabled — skipping session start")
            return
        }
        // End any existing session first
        if hasActiveSession { await end() }

        let attributes = FocusSessionAttributes(
            taskID: task.id.uuidString,
            taskTitle: task.title,
            startedAt: DateService.shared.now
        )
        let contentState = FocusSessionAttributes.ContentState(completedCount: completedCount)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: nil
            )
            liveActivityID = activity.id
            activeTaskID = task.id.uuidString
            EmberLogger.records.info("Live Activity started for: \(task.title)")
        } catch {
            EmberLogger.records.error("Failed to start Live Activity", error)
        }
    }

    /// Update the completion count on the currently active Live Activity.
    func update(completedCount: Int) async {
        guard #available(iOS 16.1, *), let liveActivityID else { return }
        let state = FocusSessionAttributes.ContentState(completedCount: completedCount)
        await Self.updateLiveActivity(id: liveActivityID, state: state)
        EmberLogger.records.info("Live Activity updated: completedCount=\(completedCount)")
    }

    /// End the currently active Live Activity.
    func end() async {
        guard #available(iOS 16.1, *), let liveActivityID else {
            activeTaskID = nil
            self.liveActivityID = nil
            return
        }
        await Self.endLiveActivity(id: liveActivityID)
        self.liveActivityID = nil
        activeTaskID = nil
        EmberLogger.records.info("Live Activity ended")
    }

    @available(iOS 16.1, *)
    private nonisolated static func updateLiveActivity(
        id: String,
        state: FocusSessionAttributes.ContentState
    ) async {
        guard let activity = Activity<FocusSessionAttributes>.activities.first(where: { $0.id == id }) else {
            return
        }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    @available(iOS 16.1, *)
    private nonisolated static func endLiveActivity(id: String) async {
        guard let activity = Activity<FocusSessionAttributes>.activities.first(where: { $0.id == id }) else {
            return
        }
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
