// EmberFocusFilter.swift
// Step 10.4 — Focus Filter intent.
// Lets iOS Focus Modes (e.g., "Work", "Personal") configure Ember to show
// only a specific slot when the Focus mode is active.
// User sets this via Settings → Focus → [Mode] → App Filters → Ember.

import AppIntents

// MARK: - Focus Filter Intent

@available(iOS 16.0, *)
struct EmberFocusFilter: SetFocusFilterIntent {

    static let title: LocalizedStringResource = "Show Focus Slot"
    static let description: IntentDescription = IntentDescription(
        "Configure which Ember focus slots are visible when this Focus mode is active.",
        categoryName: "Productivity"
    )

    // MARK: - Parameter

    /// When true, only slot 01 (the primary focus) is shown; slots 02 and 03 are hidden.
    @Parameter(
        title: "Show Only Primary Slot",
        description: "When on, Ember shows only your first focus slot — the top priority for this Focus mode.",
        default: false
    )
    var showOnlyPrimarySlot: Bool

    // MARK: - Conformance
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Show Only Primary Slot",
            subtitle: showOnlyPrimarySlot ? "Active" : "Inactive"
        )
    }

    // MARK: - SetFocusFilterIntent conformance

    /// Called by iOS when a Focus mode activates or updates.
    @MainActor
    func perform() async throws -> some IntentResult {
        EmberPreferences.focusFilterShowOnlyPrimary = showOnlyPrimarySlot
        EmberLogger.records.info("FocusFilter applied — showOnlyPrimary: \(showOnlyPrimarySlot)")
        return .result()
    }
}
