// ContentView.swift
// Root navigation shell for Ember.
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var router = EmberRouter()
    @State private var didApplyLaunchRoute = false
    @Namespace private var cardNamespace

    var body: some View {
        @Bindable var bindableRouter = router

        NavigationStack(path: $bindableRouter.path) {
            HomeScreen(cardNamespace: cardNamespace)
                .navigationDestination(for: EmberRoute.self) { route in
                    destination(for: route)
                }
        }
        .environment(router)
        .onOpenURL { url in
            router.handle(url: url, modelContext: modelContext)
        }
        .onAppear(perform: applyUITestingLaunchRouteIfNeeded)
    }

    @ViewBuilder
    private func destination(for route: EmberRoute) -> some View {
        switch route {
        case .taskDetail(let task):
            TaskDetailScreen(task: task, namespace: cardNamespace)
                .emberRouteEntrance(edge: .trailing)
        case .streak:
            StreakScreen()
                .emberRouteEntrance(edge: .trailing)
        case .reflection:
            ReflectionScreen()
                .emberRouteEntrance(edge: .trailing)
        case .schedule:
            ScheduleTimelineScreen()
                .emberRouteEntrance(edge: .trailing)
        case .addTask:
            AddTaskView()
                .emberRouteEntrance(edge: .bottom)
        case .settings:
            SettingsScreen()
                .emberRouteEntrance(edge: .trailing)
        }
    }

    private func applyUITestingLaunchRouteIfNeeded() {
        guard !didApplyLaunchRoute else { return }
        didApplyLaunchRoute = true

        let processInfo = ProcessInfo.processInfo
        let arguments = processInfo.arguments
        let environment = processInfo.environment
        guard arguments.contains("-uiTesting") || environment["EMBER_UI_TESTING"] == "1" else { return }
        let launchRoute = environment["EMBER_UI_TESTING_ROUTE"]

        let route: EmberRoute?
        if arguments.contains("-uiTestingStartSettings") || launchRoute == "settings" {
            route = .settings
        } else if arguments.contains("-uiTestingStartStreak") || launchRoute == "streak" {
            route = .streak
        } else if arguments.contains("-uiTestingStartSchedule") || launchRoute == "schedule" {
            seedScheduleUITestingTasks()
            route = .schedule
        } else if arguments.contains("-uiTestingStartReflection") || launchRoute == "reflection" {
            route = .reflection
        } else if arguments.contains("-uiTestingStartMorningRitual") || launchRoute == "morningRitual" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.showMorningRitual = true
            }
            route = nil
        } else if arguments.contains("-uiTestingSeedHomeTasks") || launchRoute == "homeSeeded" {
            seedHomeUITestingTasks()
            route = nil
        } else if arguments.contains("-uiTestingStartCarryForward") || launchRoute == "carryForward" {
            seedCarryForwardUITestingTasks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.showCarryForward = true
            }
            route = nil
        } else if arguments.contains("-uiTestingStartTranscendence") || launchRoute == "transcendence" {
            seedTranscendenceUITestingTasks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.showTranscendence = true
            }
            route = nil
        } else if arguments.contains("-uiTestingStartAddTask") || launchRoute == "addTask" {
            if let titleIndex = arguments.firstIndex(of: "-uiTestingAddTaskTitle"),
               arguments.indices.contains(arguments.index(after: titleIndex)) {
                router.pendingAddTitle = arguments[arguments.index(after: titleIndex)]
            } else if let title = environment["EMBER_UI_TESTING_ADD_TASK_TITLE"] {
                router.pendingAddTitle = title
            }
            route = .addTask
        } else if arguments.contains("-uiTestingStartTaskDetail") || launchRoute == "taskDetail" {
            let task = EmberTask(
                title: environment["EMBER_UI_TESTING_TASK_TITLE"]
                    ?? uiTestingArgument(after: "-uiTestingTaskTitle", in: arguments)
                    ?? "Shape the launch slice",
                displayOrder: 0,
                dayDate: DateService.shared.today,
                scheduledTime: DateService.shared.today.addingTimeInterval(10 * 60 * 60)
            )
            let firstSubtask = Subtask(title: "Confirm final screenshots", displayOrder: 0)
            let secondSubtask = Subtask(title: "Tighten release notes", displayOrder: 1)
            firstSubtask.task = task
            secondSubtask.task = task
            modelContext.insert(task)
            modelContext.insert(firstSubtask)
            modelContext.insert(secondSubtask)
            route = .taskDetail(task)
        } else {
            route = nil
        }

        guard let route else { return }
        DispatchQueue.main.async {
            router.navigate(to: route)
        }
    }

    private func seedHomeUITestingTasks() {
        let today = DateService.shared.today
        let tasks = [
            (
                title: "Shape the release story",
                order: 0,
                scheduledTime: uiTestingTime(on: today, hour: 9, minute: 30),
                isCompleted: true
            ),
            (
                title: "Review final screenshots",
                order: 1,
                scheduledTime: uiTestingTime(on: today, hour: 13, minute: 0),
                isCompleted: false
            ),
            (
                title: "Run the archive checklist",
                order: 2,
                scheduledTime: nil,
                isCompleted: false
            )
        ]

        for taskSpec in tasks {
            let task = EmberTask(
                title: taskSpec.title,
                displayOrder: taskSpec.order,
                dayDate: today,
                scheduledTime: taskSpec.scheduledTime
            )
            task.isCompleted = taskSpec.isCompleted
            if taskSpec.isCompleted {
                task.completionDate = Date()
            }
            modelContext.insert(task)
        }
        DailyRecordService.upsertRecord(in: modelContext)
    }

    private func seedCarryForwardUITestingTasks() {
        let yesterday = DateService.shared.yesterday
        let tasks = [
            ("Shape the product narrative", 0),
            ("Finish the release notes", 1),
            ("Polish the onboarding flow", 2),
        ]
        for (title, order) in tasks {
            let task = EmberTask(title: title, displayOrder: order, dayDate: yesterday)
            modelContext.insert(task)
        }
    }

    private func seedTranscendenceUITestingTasks() {
        let today = DateService.shared.today
        let tasks = [
            ("Ship the design pass", 0),
            ("Write the product summary", 1),
            ("Lock down the release build", 2),
        ]
        for (title, order) in tasks {
            let task = EmberTask(title: title, displayOrder: order, dayDate: today)
            task.isCompleted = true
            task.completionDate = Date()
            modelContext.insert(task)
        }
        DailyRecordService.upsertRecord(in: modelContext)
    }

    private func uiTestingArgument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }

    private func seedScheduleUITestingTasks() {
        let today = DateService.shared.today
        let first = EmberTask(
            title: "Release screens",
            displayOrder: 0,
            dayDate: today,
            scheduledTime: uiTestingTime(on: today, hour: 8, minute: 30)
        )
        let second = EmberTask(
            title: "Tighten schedule polish",
            displayOrder: 1,
            dayDate: today,
            scheduledTime: uiTestingTime(on: today, hour: 13, minute: 0)
        )
        let third = EmberTask(
            title: "Evening review pass",
            displayOrder: 2,
            dayDate: today,
            scheduledTime: uiTestingTime(on: today, hour: 18, minute: 15)
        )
        third.isCompleted = true
        third.completionDate = Date()

        modelContext.insert(first)
        modelContext.insert(second)
        modelContext.insert(third)
    }

    private func uiTestingTime(on day: Date, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? day
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self],
            inMemory: true
        )
}
