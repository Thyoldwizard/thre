// EmberRouter.swift
import SwiftUI
import SwiftData

enum EmberRoute: Hashable {
    case taskDetail(EmberTask)
    case streak
    case reflection
    case schedule
    case addTask
    case settings
}

@Observable
class EmberRouter {
    nonisolated deinit {}

    var path = NavigationPath()
    var showAddTask = false
    var showCarryForward = false
    var showTranscendence = false
    var showMorningRitual = false

    // 10.2 — pending deep-linked add-task title (from AddTaskIntent or ember://add)
    var pendingAddTitle: String? = nil

    func navigate(to route: EmberRoute) {
        path.append(route)
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    // MARK: - 10.2 URL / Universal Link handler

    /// Returns true if the URL was handled.
    /// Supported:
    ///   ember://task/{uuid}    → navigate to TaskDetailScreen
    ///   ember://add?title={t} → navigate to AddTaskView with optional pre-filled title
    @discardableResult
    func handle(url: URL, modelContext: ModelContext) -> Bool {
        guard url.scheme == "ember" else { return false }
        let host = url.host ?? ""

        switch host {
        case "settings":
            navigate(to: .settings)
            return true

        case "streak", "rhythm":
            navigate(to: .streak)
            return true

        case "schedule":
            navigate(to: .schedule)
            return true

        case "reflection":
            navigate(to: .reflection)
            return true

        case "task":
            // ember://task/{uuid}
            let uuidString = url.lastPathComponent
            guard let id = UUID(uuidString: uuidString) else { return false }
            // Fetch the task from the model context
            let descriptor = FetchDescriptor<EmberTask>(
                predicate: #Predicate { $0.id == id }
            )
            if let task = (try? modelContext.fetch(descriptor))?.first {
                navigate(to: .taskDetail(task))
                return true
            }
            return false

        case "add":
            // ember://add?title=Some+Task
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let title = components?.queryItems?.first(where: { $0.name == "title" })?.value
            pendingAddTitle = title
            navigate(to: .addTask)
            return true

        default:
            return false
        }
    }
}
