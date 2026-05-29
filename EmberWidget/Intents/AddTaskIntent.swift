import AppIntents
import Foundation
import WidgetKit

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Focus"
    static let description = IntentDescription("Open Ember to add a focus for today.")
    static let openAppWhenRun = true

    @Parameter(title: "Title")
    var title: String

    init() {
        title = ""
    }

    init(title: String) {
        self.title = title
    }

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        EmberIntentStore.storePendingAddTitle(trimmedTitle)

        var components = URLComponents()
        components.scheme = "ember"
        components.host = "add"
        if !trimmedTitle.isEmpty {
            components.queryItems = [URLQueryItem(name: "title", value: trimmedTitle)]
        }

        let url = components.url ?? URL(string: "ember://add")!
        let dialog: IntentDialog = trimmedTitle.isEmpty
            ? "Opening Ember."
            : "Opening Ember with \(trimmedTitle)."

        WidgetCenter.shared.reloadAllTimelines()
        return .result(opensIntent: OpenURLIntent(url), dialog: dialog)
    }
}
