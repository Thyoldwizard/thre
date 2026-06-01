// EmberWidget.swift
import WidgetKit
import SwiftUI

struct EmberTodayWidget: Widget {
    let kind = "EmberTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmberWidgetProvider()) { entry in
            HomeScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("thre Today")
        .description("Track today's three focus slots.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct EmberLockScreenWidget: Widget {
    let kind = "EmberLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmberWidgetProvider()) { entry in
            LockScreenWidgetRoot(entry: entry)
        }
        .configurationDisplayName("thre Progress")
        .description("See today's completion progress and streak.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

private struct LockScreenWidgetRoot: View {
    let entry: EmberWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        default:
            RectangularLockScreenView(entry: entry)
        }
    }
}

#Preview(as: .systemMedium) {
    EmberTodayWidget()
} timeline: {
    EmberWidgetEntry.preview
}

#Preview(as: .accessoryCircular) {
    EmberLockScreenWidget()
} timeline: {
    EmberWidgetEntry.preview
}

private extension EmberWidgetEntry {
    static var preview: EmberWidgetEntry {
        EmberWidgetEntry(
            date: Date(),
            tasks: [
                TaskSnapshot(id: UUID(), title: "Morning run", isCompleted: true, isCarriedForward: false),
                TaskSnapshot(id: UUID(), title: "Read 30 min", isCompleted: false, isCarriedForward: false),
                TaskSnapshot(id: UUID(), title: "Journal entry", isCompleted: false, isCarriedForward: false)
            ],
            streakCount: 7,
            completedCount: 1
        )
    }
}
