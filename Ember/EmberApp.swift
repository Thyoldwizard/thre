// EmberApp.swift
import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([
            EmberTask.self,
            Subtask.self,
            DailyRecord.self,
            Reflection.self
        ])

        if ProcessInfo.processInfo.arguments.contains("-uiTesting")
            || ProcessInfo.processInfo.environment["EMBER_UI_TESTING"] == "1" {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [config])
        }

        // Use shared App Group storage when available so widgets can read app data.
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ember.focus"
        ) {
            let storeURL = groupURL.appendingPathComponent("Ember.store")
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
        }

        return try! ModelContainer(for: schema)
    }()

    @State private var sessionWatcher = ScheduledSessionWatcher()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetPreferences")
            || ProcessInfo.processInfo.environment["EMBER_RESET_PREFERENCES"] == "1" {
            EmberPreferences.resetForUITesting()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { @MainActor in
                        EmberLogger.records.info("Scene became active — session watcher pass deferred to HomeScreen")
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
