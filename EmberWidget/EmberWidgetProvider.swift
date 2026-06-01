// EmberWidgetProvider.swift
// TimelineProvider — builds widget timeline entries from shared SwiftData store.
import WidgetKit
import SwiftData

// MARK: - Entry

struct EmberWidgetEntry: TimelineEntry {
    let date:         Date
    let tasks:        [TaskSnapshot]
    let streakCount:  Int
    let completedCount: Int

    var totalTasks: Int { tasks.count }
}

struct TaskSnapshot: Identifiable {
    let id:               UUID
    let title:            String
    let isCompleted:      Bool
    let isCarriedForward: Bool
}

// MARK: - Provider

struct EmberWidgetProvider: TimelineProvider {

    // MARK: Placeholder (shown while widget loads)
    func placeholder(in context: Context) -> EmberWidgetEntry {
        EmberWidgetEntry(
            date: Date(),
            tasks: [
                TaskSnapshot(id: UUID(), title: "Morning run",  isCompleted: true,  isCarriedForward: false),
                TaskSnapshot(id: UUID(), title: "Read 30 min",  isCompleted: false, isCarriedForward: false),
                TaskSnapshot(id: UUID(), title: "Journal entry",isCompleted: false, isCarriedForward: false)
            ],
            streakCount: 7,
            completedCount: 1
        )
    }

    // MARK: Snapshot (Gallery preview)
    func getSnapshot(in context: Context, completion: @escaping (EmberWidgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : buildEntry())
    }

    // MARK: Timeline — refreshes at next midnight
    func getTimeline(in context: Context, completion: @escaping (Timeline<EmberWidgetEntry>) -> Void) {
        let entry     = buildEntry()
        let midnight  = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline  = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    // MARK: Build from SwiftData store
    private func buildEntry() -> EmberWidgetEntry {
        guard let container = SharedDataProvider.makeSharedContainer() else {
            return EmberWidgetEntry(date: Date(), tasks: [], streakCount: 0, completedCount: 0)
        }

        let context  = ModelContext(container)
        let tasks    = SharedDataProvider.todaysTasks(in: context)
        let streak   = SharedDataProvider.currentStreak(in: context)

        let snapshots = tasks.map {
            TaskSnapshot(
                id:               $0.id,
                title:            $0.title,
                isCompleted:      $0.isCompleted,
                isCarriedForward: $0.isCarriedForward
            )
        }

        return EmberWidgetEntry(
            date:           Date(),
            tasks:          snapshots,
            streakCount:    streak,
            completedCount: snapshots.filter { $0.isCompleted }.count
        )
    }
}
