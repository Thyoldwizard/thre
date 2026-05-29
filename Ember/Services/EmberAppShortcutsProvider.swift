import AppIntents

struct EmberAppShortcutsProvider: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add focus to \(.applicationName)",
                "Add a focus in \(.applicationName)"
            ],
            shortTitle: "Add Focus",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: ShowTodayIntent(),
            phrases: [
                "What are my three for today in \(.applicationName)",
                "Show today's three in \(.applicationName)"
            ],
            shortTitle: "Today",
            systemImageName: "circle.grid.3x3.fill"
        )

        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Mark focus as done in \(.applicationName)",
                "Complete focus in \(.applicationName)"
            ],
            shortTitle: "Complete Focus",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
