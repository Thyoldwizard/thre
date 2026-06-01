// ShareViewController.swift

import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Process the shared item immediately without showing any custom UI.
        extractSharedText { [weak self] text in
            DispatchQueue.main.async {
                self?.forwardToApp(text: text)
            }
        }
    }

    // MARK: - Extract shared text

    private func extractSharedText(completion: @escaping (String) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = extensionItem.attachments else {
            completion("")
            return
        }

        // Prefer plain text
        let textType = UTType.plainText.identifier
        let urlType = UTType.url.identifier

        if let textProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(textType) }) {
            textProvider.loadItem(forTypeIdentifier: textType) { item, _ in
                let text = (item as? String) ?? ""
                completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } else if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(urlType) }) {
            // Fallback: use the URL's host + path as the task title
            urlProvider.loadItem(forTypeIdentifier: urlType) { item, _ in
                if let url = item as? URL {
                    let title = url.host ?? url.absoluteString
                    completion(title)
                } else {
                    completion("")
                }
            }
        } else {
            completion("")
        }
    }

    // MARK: - Forward to main app

    private func forwardToApp(text: String) {
        // 1. Store in shared App Group defaults (same key AddTaskIntent uses)
        let groupID = "group.com.ember.focus"
        let defaults = UserDefaults(suiteName: groupID)
        let sanitized = sanitize(text)
        defaults?.set(sanitized, forKey: "ember.pendingAddTaskTitle")

        // 2. Build the deep link URL
        var components = URLComponents()
        components.scheme = "ember"
        components.host = "add"
        if !sanitized.isEmpty {
            components.queryItems = [URLQueryItem(name: "title", value: sanitized)]
        }

        // 3. Open the main app via the URL
        if let url = components.url {
            extensionContext?.open(url) { [weak self] _ in
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // MARK: - Helpers

    /// Trim and truncate the text to a sane task title length (140 chars max).
    private func sanitize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 140 else { return trimmed }
        return String(trimmed.prefix(140))
    }
}
