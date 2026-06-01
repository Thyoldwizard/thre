// SharedDataProvider.swift
import Foundation
import OSLog
import SwiftData

private let widgetLogger = Logger(subsystem: "com.ember.focus", category: "ember.widget")

struct SharedDataProvider {

    // MARK: - Shared Container

    static func makeSharedContainer() -> ModelContainer? {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ember.focus"
        ) else {
            widgetLogger.error("App Group container not found")
            return nil
        }

        let schema   = Schema([EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self])
        let storeURL = groupURL.appendingPathComponent("Ember.store")
        let config   = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)

        return try? ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Today's Tasks

    static func todaysTasks(in context: ModelContext) -> [EmberTask] {
        let today    = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate { task in
                task.dayDate >= today && task.dayDate < tomorrow
            },
            sortBy: [SortDescriptor(\EmberTask.displayOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Current Streak (inline — avoids importing main-app StreakService)

    static func currentStreak(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\DailyRecord.date, order: .reverse)]
        )
        let records  = (try? context.fetch(descriptor)) ?? []
        let calendar = Calendar.current

        let completedDates = records
            .filter { $0.allThreeCompleted }
            .map    { $0.date }
            .sorted { $0 > $1 }

        guard !completedDates.isEmpty else { return 0 }

        var streak    = 0
        var checkDate = calendar.startOfDay(for: Date())

        for date in completedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak   += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if date < checkDate {
                break
            }
        }
        return streak
    }
}
