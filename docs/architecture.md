# Architecture

thre is a native SwiftUI app with a local-first data model and a small set of system integrations.

## Runtime Shape

- `EmberApp` creates the SwiftData `ModelContainer`.
- `ContentView` owns the `NavigationStack`, deep-link handling, and UI-test route seeding.
- `EmberRouter` centralizes in-app routes and modal presentation state.
- Feature screens live in `Ember/Screens/`.
- Reusable UI lives in `Ember/Components/`.
- Visual tokens live in `Ember/DesignSystem/`.

## Data Model

Core SwiftData models:

- `EmberTask` - one of the daily focus items.
- `Subtask` - checklist item attached to a task.
- `DailyRecord` - normalized daily completion/streak record.
- `Reflection` - end-of-day reflection text.

The app stores data locally. When the App Group container is available, the SwiftData store is placed there so widgets can read app data. If the group container is unavailable, the app falls back to a local container.

## Services

- `DateService` normalizes day boundaries and last-active date behavior.
- `DailyRecordService` creates and updates daily records.
- `StreakService` calculates streak state.
- `TaskCompletionCoordinator` handles task completion side effects.
- `ReminderService` schedules local notifications.
- `FocusSessionService` wraps ActivityKit Live Activity lifecycle.
- `ScheduledSessionWatcher` evaluates scheduled tasks and can start focus sessions.
- `SpotlightService` indexes tasks into CoreSpotlight.
- `EmberPreferences` owns UserDefaults-backed settings.
- `EmberLogger`, `AudioService`, and `HapticService` provide supporting system behavior.

## System Integrations

- WidgetKit widgets in `EmberWidget/`.
- ActivityKit Live Activity in `EmberWidget/FocusSessionLiveActivity.swift`.
- App Intents in `EmberWidget/Intents/` and app shortcut provider support in `Ember/Services/`.
- Share extension in `EmberShareExtension/`.
- CoreSpotlight indexing through `SpotlightService`.
- UserNotifications through `ReminderService`.

## UI Testing And Screenshots

`ContentView` supports environment-driven launch routes for deterministic screenshots and focused UI tests. This keeps visual QA repeatable without relying on a pre-existing simulator data store.

## Naming

The user-facing product is `thre`. The Xcode project and several bundle identifiers retain the earlier internal codename `Ember` to avoid broad signing and App Group churn. A future branding migration should be tracked separately from feature work.
