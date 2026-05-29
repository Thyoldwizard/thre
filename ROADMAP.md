# Ember — Build Roadmap

> Coordination doc for **Claude + Codex** working in parallel.
> Each task below is atomic, self-contained, and claim-able by either agent.
> Read the **Coordination Protocol** before claiming a task.

---

## Coordination Protocol

**Before claiming a task:**
1. Check the task's `Deps:` — make sure every dependency is `[x] DONE`.
2. Check the `Files:` list against other `[~] IN PROGRESS` tasks — if any file overlaps, wait or coordinate.
3. Edit this file to change `[ ]` → `[~] IN PROGRESS (Claude)` or `[~] IN PROGRESS (Codex)`.
4. Commit the claim before starting work so the other agent sees it.

**While working a task:**
- Touch only the files listed under `Files:`. If you need to touch something else, stop and split the task first.
- Do not start a downstream task until the current one is `[x] DONE`.

**When done:**
1. Run the `Done when:` verification.
2. Edit this file: `[~]` → `[x] DONE (Claude)` or `[x] DONE (Codex)`.
3. Append a one-line note under the task if anything diverged from the plan.
4. Update `PROGRESS.md` checkbox + `HANDOFF.md` "Recent Changes" if user-visible.
5. Commit with subject `<task-id>: <title>` (e.g. `1.3: DateService clock seam`).

**Conflict resolution:**
- If both agents accidentally claim the same task, the one with the earlier commit timestamp keeps it.
- Never force-push the other agent's work.

**Status legend:**
- `[ ]` — TODO, claim-able
- `[~]` — IN PROGRESS (agent name in parens)
- `[x]` — DONE (agent name in parens)
- `[!]` — BLOCKED (reason in note)
- `[-]` — SKIPPED / deferred (reason in note)

---

## Context

Ember is a SwiftUI + SwiftData iOS app for a "three meaningful tasks per day" ritual. Current state: dark studio design language, working hold-to-complete + drag-to-reorder, working widgets, working reminders, working streak/reflection. Build clean; 11 tests pass.

**Goal:** Make it a top-tier portfolio app — visually distinctive, modern iOS (animations, Live Activity, interactive widgets, App Intents), and backend-solid (timezone-correct, atomic, error-surfaced, well-tested).

**Approach:** Foundation first (so feature work doesn't fight backend), then visual tier, then platform features, then UX depth, then identity, then iPad.

**Locked decisions:**
- **Step 4 typeface:** Bundle Inter Tight (OFL, free, ~300KB variable font) for Daily Orbit value only. SF Pro everywhere else.
- **Step 8 Live Activity:** Manual start button + auto-start during scheduled task windows, with Settings toggle + per-task dismissal.

**Cross-cutting principles:**
- One file per concern. No god-files.
- No regressions: every task ends with `xcodebuild` green + existing tests passing.
- Reduce-Motion respected on every animation.
- `@MainActor` on view models; `Task` cancellation tokens on timers.
- Don't touch files outside the task's `Files:` list.

---

## Phase A — Foundation

### Step 1 — Backend hardening

- [x] **1.1** — Create `EmberLogger` wrapping `os.Logger` — DONE (Claude)
  - **Files:** NEW `Ember/Services/EmberLogger.swift`
  - **Deps:** none
  - **Scope:** Struct with 4 named subsystems (`ember.home`, `ember.reminders`, `ember.records`, `ember.widget`). Methods `.info(_:)`, `.error(_:_:)`, `.debug(_:)`.
  - **Done when:** Compiles. Other services can import nothing extra to use it.

- [x] **1.2** — Migrate all `print(...)` to `EmberLogger` — DONE (Claude); SharedDataProvider uses inline os.Logger (widget target can't import main app)
  - **Files:** `Ember/Services/HapticService.swift`, `Ember/Services/AudioService.swift`, `EmberWidget/SharedDataProvider.swift`
  - **Deps:** 1.1
  - **Scope:** Replace each `print(...)` (7 sites total) with the appropriate `EmberLogger.error/info` call.
  - **Done when:** `grep -rn "print(" Ember/Services EmberWidget` returns 0 matches.

- [x] **1.3** — Add `Clock` + `Calendar` injection seam to `DateService` — DONE (Claude); EmberClock protocol + SystemClock defined in DateService.swift
  - **Files:** `Ember/Services/DateService.swift`
  - **Deps:** none
  - **Scope:** Add `init(clock:calendar:)` defaulting to `.continuous` and `.current`. Replace internal `Date()` / `Calendar.current` with the injected values. Keep `.shared` as a default-constructed singleton for back-compat.
  - **Done when:** All existing callers compile unchanged. New `DateService(clock: someTestClock)` is constructible.

- [x] **1.4** — Route `EmberPreferences` date checks through `DateService` — DONE (Claude)
  - **Files:** `Ember/Services/EmberPreferences.swift`
  - **Deps:** 1.3
  - **Scope:** Remove `Calendar.current` and `Date()` direct calls. Inject `DateService` (parameterized or default to `.shared`).
  - **Done when:** `grep -n "Calendar.current\|Date()" Ember/Services/EmberPreferences.swift` returns 0.

- [x] **1.5** — Add explicit `try context.save()` + error logging to `DailyRecordService` — DONE (Claude)
  - **Files:** `Ember/Services/DailyRecordService.swift`
  - **Deps:** 1.1
  - **Scope:** Wrap `context.fetch` in do/catch; wrap mutations with `try context.save()`; log errors via `EmberLogger`. Public API signature stays the same.
  - **Done when:** `try?` count in file = 0. `EmberLogger.error` called on every catch.

- [x] **1.6** — Refactor `ReminderService` to `async throws` + add `Clock` seam — DONE (Claude); enum → struct, cancelReminder stays static convenience
  - **Files:** `Ember/Services/ReminderService.swift`
  - **Deps:** 1.3
  - **Scope:** `scheduleReminder(for:)` becomes `async throws`. Move cancel+add into a single structured `Task` (no orphan race). Inject `Clock` for testability.
  - **Done when:** Compiles. Race window between cancel and add no longer exists (single Task).

- [x] **1.7** — Create `TaskCompletionCoordinator` — DONE (Claude); 4 methods: complete, uncomplete, deleteTask, scheduleReminder
  - **Files:** NEW `Ember/Services/TaskCompletionCoordinator.swift`
  - **Deps:** 1.5, 1.6
  - **Scope:** Single async entry point `complete(_:)` / `uncomplete(_:)` that atomically: cancels reminder → flips model → upserts DailyRecord → saves → logs. Rolls back on failure.
  - **Done when:** Has 4 public methods, fully unit-testable, doesn't depend on any view.

- [x] **1.8** — Wire `HomeScreen` completion through `TaskCompletionCoordinator` — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 1.7
  - **Scope:** Replace inline `task.isCompleted = true; DailyRecordService.upsertRecord(...); ReminderService.cancelReminder(...)` sequences in `complete(_:)` and `undoCompletion()` with single coordinator calls.
  - **Done when:** Build green. Manual sim: complete + undo still works.

- [x] **1.9** — Wire `TaskDetailScreen` completion through `TaskCompletionCoordinator` — DONE (Claude)
  - **Files:** `Ember/Screens/TaskDetailScreen.swift`
  - **Deps:** 1.7
  - **Scope:** Same as 1.8 for the complete/incomplete toggle and delete path.
  - **Done when:** Build green. Manual sim: detail toggle + delete still cancels reminders and updates record.

- [x] **1.10** — Add `PrivacyInfo.xcprivacy` — DONE (Claude); UserDefaults CA92.1, FileTimestamp C617.1, SystemBootTime 35F9.1
  - **Files:** NEW `Ember/PrivacyInfo.xcprivacy`
  - **Deps:** none
  - **Scope:** Declare required reason APIs: `NSUserDefaults` (CA92.1), `FileTimestamp` (C617.1), `SystemBootTime` (35F9.1). No tracking, no domains.
  - **Done when:** Xcode project builds with the file included in main target's Copy Bundle Resources.

- [x] **1.11** — Enable `SWIFT_STRICT_CONCURRENCY = complete`, fix warnings — DONE (Claude); 0 warnings; used MainActor.assumeIsolated for timer callbacks
  - **Files:** `Ember/Ember.xcodeproj/project.pbxproj` + whichever source files emit warnings
  - **Deps:** 1.1–1.9
  - **Scope:** Flip the build setting on main target. Audit warnings. Add `@MainActor` / `Sendable` annotations as needed. Do NOT silence warnings with `@unchecked Sendable` unless the type really is thread-safe.
  - **Done when:** Build emits 0 strict-concurrency warnings.

- [x] **1.12** — Write `EmberLoggerTests` + `DateServiceTimezoneTests` — DONE (Claude); all pass
  - **Files:** NEW `EmberTests/EmberLoggerTests.swift`, NEW `EmberTests/DateServiceTimezoneTests.swift`
  - **Deps:** 1.1, 1.3
  - **Scope:** Logger: smoke test each level + subsystem. DateService: inject Honolulu + Tokyo timezones, verify `today` / `isNewDay` boundaries.
  - **Done when:** Both files added to EmberTests target; `xcodebuild test` runs them, all pass.

- [x] **1.13** — Write `TaskCompletionCoordinatorTests` + `ReminderServiceDateTests` — DONE (Claude); all pass
  - **Files:** NEW `EmberTests/TaskCompletionCoordinatorTests.swift`, NEW `EmberTests/ReminderServiceDateTests.swift`
  - **Deps:** 1.6, 1.7
  - **Scope:** Coordinator: happy path, double-complete idempotency, save failure rollback. ReminderService: inject clock, verify `UNCalendarNotificationTrigger.dateComponents` for various inputs.
  - **Done when:** Both files in target; all tests pass.

---

## Phase B — Visual

### Step 2 — Symbol effects pass

- [x] **2.1** — Create `EmberSymbolEffects` helper modifiers — DONE (Codex)
  - **Files:** NEW `Ember/DesignSystem/EmberSymbolEffects.swift`
  - **Deps:** none
  - **Scope:** Extension on `View` with named modifiers: `.completeBounce(_ trigger:)`, `.streakFlame()`, `.toastPulse()`, `.replaceCheck(_ isChecked:)`. Each respects `EmberPreferences.reducedMotionEnabled`.
  - **Done when:** File compiles. Each modifier is reusable.

- [x] **2.2** — Apply symbol effects to `HomeScreen` icons — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 2.1
  - **Scope:** `gearshape` `.symbolEffect(.bounce, value: showSettings)`; `plus` `.bounce` on tap; `arrow.uturn.backward` `.pulse` while toast visible; `line.3.horizontal` `.symbolEffect(.appear, isActive: isReordering)`.
  - **Done when:** Sim walk shows each icon animating on its trigger.

- [x] **2.3** — Apply symbol effects to `TaskDetailScreen` + `MorningRitualView` + `ReflectionScreen` — DONE (Codex)
  - **Files:** `Ember/Screens/TaskDetailScreen.swift`, `Ember/Screens/MorningRitualView.swift`, `Ember/Screens/ReflectionScreen.swift`
  - **Deps:** 2.1
  - **Scope:** `checkmark` `.bounce` on subtask check; `checkmark.circle.fill` `.replace` on toggle; `square.and.pencil` `.bounce` on save.
  - **Done when:** Sim walk confirms.

- [x] **2.4** — Apply `.variableColor.iterative` to `flame.fill` on `StreakScreen` — DONE (Codex)
  - **Files:** `Ember/Screens/StreakScreen.swift`, `Ember/Screens/CarryForwardView.swift`
  - **Deps:** 2.1
  - **Scope:** Flame uses infinite `.variableColor.iterative.reversing` — but skipped when Reduce Motion is on. CarryForward `exclamationmark.circle` / `info.circle` use `.bounce` on appear.
  - **Done when:** Flame flickers on Streak; static when Reduce Motion enabled in Settings.
  - **Note:** Added shared reduced-motion-aware helpers in `Ember/DesignSystem/EmberSymbolEffects.swift`; build and unit tests verified. Manual sim walk still recommended for visual feel.

---

### Step 3 — Hold-to-complete V2 + Bloom V2

- [x] **3.1** — Replace hold `Timer` with `TimelineView(.animation)` in `HomeScreen` — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 1.8
  - **Scope:** Hold progress driven by `TimelineView(.animation) { context in ... }` reading `Date.now - holdStartedAt`. Eliminates the 0.016s Timer. Smoother on ProMotion.
  - **Done when:** Hold still completes at 1.5s. CPU profile cleaner (no Timer fires).

- [x] **3.2** — Implement radial color wipe on `FocusModuleCard` — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift` (FocusModuleCard view)
  - **Deps:** 3.1
  - **Scope:** Replace bottom progress bar with a `RadialGradient` mask that grows from `pressedLocation` outward to fill the card over 1.5s. Slot accent color fades through at ~40% opacity.
  - **Done when:** Sim slow-mo recording shows smooth radial fill respecting touch origin.

- [x] **3.3** — Add `playEscalatingHoldCadence(progress:)` to `HapticService` — DONE (Codex)
  - **Files:** `Ember/Services/HapticService.swift`
  - **Deps:** none
  - **Scope:** New method. Internally throttles taps: 250ms intervals when progress < 0.5, 80ms when progress >= 0.85. Respects `EmberPreferences.hapticsEnabled`.
  - **Done when:** Unit test asserts tap intervals at boundary progress values.

- [x] **3.4** — Wire escalating cadence into HomeScreen hold tick — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 3.1, 3.3
  - **Scope:** From the TimelineView tick, call `HapticService.shared.playEscalatingHoldCadence(progress:)` each frame. Service handles throttling internally.
  - **Done when:** Manual device test: noticeable haptic ramp.

- [x] **3.5** — Extend `CompletionBloom` with `intensity: .standard | .third` — DONE (Codex)
  - **Files:** `Ember/Components/CompletionBloom.swift`
  - **Deps:** none
  - **Scope:** Add init param. `.third` triggers additional full-screen 8% ember flash for 120ms after the radial bloom. `.standard` unchanged.
  - **Done when:** Existing callers still compile (default param). Sim test of `.third` shows the flash.

- [x] **3.6** — Wire third-task flash + Transcendence delay — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 3.5
  - **Scope:** In `complete(_:)`, when `allCompleted` becomes true, render `CompletionBloom(intensity: .third)`. Existing 0.5s Transcendence delay stays; flash plays inside that window.
  - **Done when:** Completing 3rd task shows flash, then Transcendence presents ~0.5s later.
  - **Note:** Added `EmberTests/HapticServiceTests.swift` to satisfy 3.3 cadence boundary coverage; build and unit tests pass. UI test target was attempted, but simulator launch instability interrupted the run after two UI failures.

---

### Step 4 — Launch experience

- [x] **4.1** — Bundle Inter Tight font + OFL license — DONE (Codex)
  - **Files:** NEW `Ember/Resources/Fonts/InterTight-VariableFont_wght.ttf`, NEW `Ember/Resources/Fonts/OFL.txt`
  - **Deps:** none
  - **Scope:** Download Inter Tight from rsms.me/inter or GitHub releases. Add both files to Xcode project (Copy Bundle Resources on main target).
  - **Done when:** Files visible in Xcode navigator under target's resources.

- [x] **4.2** — Register font in `Info.plist` — DONE (Codex); added physical main app plist because generated plist settings did not emit `UIAppFonts`
  - **Files:** `Ember/Info.plist`
  - **Deps:** 4.1
  - **Scope:** Add `UIAppFonts` array containing `InterTight-VariableFont_wght.ttf`.
  - **Done when:** `UIFont.familyNames` includes `Inter Tight` at runtime.

- [x] **4.3** — Add `orbitHero` font case to `EmberTypography` — DONE (Codex); uses the bundled font's runtime PostScript name `InterTight-Regular`
  - **Files:** `Ember/DesignSystem/EmberTypography.swift`
  - **Deps:** 4.2
  - **Scope:** `static let orbitHero = Font.custom("InterTight", size: 58).monospacedDigit()`. Test fallback: if font missing, system serves the system mono replacement.
  - **Done when:** Compiles. Preview in SwiftUI canvas renders Inter Tight.

- [x] **4.4** — Apply `orbitHero` to Daily Orbit value — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 4.3
  - **Scope:** The `0/3` … `3/3` Text view swaps font to `EmberTypography.orbitHero`. SF Pro stays everywhere else.
  - **Done when:** Sim screenshot shows Inter Tight numerals.

- [x] **4.5** — Build `LaunchAssembly` orbit assembly animation — DONE (Codex)
  - **Files:** NEW `Ember/Screens/LaunchAssembly.swift`
  - **Deps:** none
  - **Scope:** `KeyframeAnimator`-driven view: 72 dots fade in scattered (random positions within bounds), then snap into ring formation over 0.8s. Calls completion callback when done.
  - **Done when:** Standalone preview shows the assembly. View is reusable.

- [x] **4.6** — Gate Daily Orbit on `hasAssembled` flag — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 4.5
  - **Scope:** New `@State private var hasAssembled: Bool = false`. On first appear (per cold launch only, tracked via session token), show `LaunchAssembly` overlay; on completion, set `hasAssembled = true` and reveal orbit. Subsequent navigation skips.
  - **Done when:** Cold launch shows assembly; warm/foreground does not.

- [x] **4.7** — Configure launch screen — DONE (Codex); added storyboard launch screen and `UILaunchStoryboardName`
  - **Files:** NEW `Ember/LaunchScreen.storyboard` (or modify `Info.plist` with `UILaunchScreen`)
  - **Deps:** none
  - **Scope:** Black background `#070707` + single centered ember dot. SwiftUI launch screen via `UILaunchScreen` dict preferred over storyboard.
  - **Done when:** Sim cold launch shows the launch screen for the real launch latency window.

---

### Step 5 — `matchedGeometryEffect` slot → detail

- [x] **5.1** — Add `@Namespace` + matchedGeometryEffect to `FocusModuleCard` — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** none
  - **Scope:** Add `@Namespace var taskCardNS` in HomeScreen. Attach `.matchedGeometryEffect(id: "card-\(task.id)", in: taskCardNS)` to card background; `id: "title-\(task.id)"` to title text; `id: "rail-\(task.id)"` to accent rail.
  - **Done when:** Compiles. No visible behavior change yet (only used on transition).

- [x] **5.2** — Add matching IDs to `TaskDetailScreen` header — DONE (Claude)
  - **Files:** `Ember/Screens/TaskDetailScreen.swift`
  - **Deps:** 5.1
  - **Scope:** Receive `namespace: Namespace.ID` via init. Attach matching `.matchedGeometryEffect` to detail-screen header background, title text, and accent rail (if present).
  - **Done when:** Build green. Header gets the same IDs as the source card.
  - **Note:** `namespace` param is `Namespace.ID?` (optional, defaults to nil) so existing callers and UI tests compile without change. On iOS 17 the optional is nil and the `#available` guard is not entered.

- [x] **5.3** — Switch routing to `NavigationTransition.zoom(sourceID:in:)` — DONE (Claude)
  - **Files:** `Ember/Navigation/EmberRouter.swift`, `Ember/ContentView.swift`, `Ember/Screens/HomeScreen.swift`
  - **Deps:** 5.2
  - **Scope:** iOS 18+ — apply `.navigationTransition(.zoom(sourceID: "card-\(task.id)", in: taskCardNS))` to the destination view. Falls back gracefully on iOS 17 (no morph, normal push).
  - **Done when:** Sim on iPhone 17 (iOS 18): tap slot → header morphs from card. Back gesture reverses.
  - **Note:** Namespace owned by `ContentView` (`@Namespace var taskCardNS`), passed as `cardNamespace: Namespace.ID` to `HomeScreen` and as `namespace: Namespace.ID?` to `TaskDetailScreen`. `EmberRouter.swift` did not need changes (route enum was already sufficient). All three matched IDs per task: card background, title text, accent rail.

---

### Step 6 — Micro-interaction pass

- [x] **6.1** — Upgrade orbit value number ticker — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** none
  - **Scope:** Changed `.contentTransition(.numericText())` → `.contentTransition(.numericText(countsDown: false))`. Animation upgraded to `EmberAnimation.bouncy`.
  - **Done when:** `0/3` → `1/3` rolls up smoothly.

- [x] **6.2** — Drag-to-reorder card rotation + shadow lift — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** none
  - **Scope:** `FocusModuleCard` gets `.rotationEffect(.degrees(isDragging ? 2 : 0))`. Shadow: resting 8%/radius 6 → dragging 45%/radius 22. Animations use `EmberAnimation.snappy`/`smooth`.
  - **Done when:** Sim drag shows tilt + shadow lift.

- [x] **6.3** — Toast scale-in entrance — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift` (undoToast view)
  - **Deps:** none
  - **Scope:** Transition is `.scale(0.92).combined(with: .opacity).combined(with: .move(edge: .bottom))`. Container animation upgraded to `EmberAnimation.bouncy`.
  - **Done when:** Toast pops in with subtle overshoot.

- [x] **6.4** — Idle breathing on orbit guide ring — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** none
  - **Scope:** `@State var lastInteractionAt: Date` in HomeScreen, reset in `startHold`/`dismissUndo`. New `IdleBreathingGuideRing` private struct: 1Hz Timer detects ≥8s idle, animates `breatheScale` 1.0↔1.02 on a 4s easeInOut.repeatForever. Stops on interaction. Respects Reduce Motion.
  - **Done when:** Leave sim idle 8s on Home → breathing starts. Tap anywhere → stops.

- [x] **6.5** — Add `bouncy`/`snappy`/`smooth` named tokens — DONE (Claude)
  - **Files:** `Ember/DesignSystem/EmberAnimations.swift`
  - **Deps:** none
  - **Scope:** Three static lets at top of `EmberAnimation`: `bouncy = .bouncy`, `snappy = .snappy`, `smooth = .smooth`. Migrated 5 ad-hoc `.spring(response:dampingFraction:)` call sites across HomeScreen to use the new tokens.
  - **Done when:** New tokens defined. ✓

---

### Step 7 — Surface treatment

- [x] **7.1** — Create `GrainOverlay` component — DONE (Codex)
  - **Files:** NEW `Ember/Components/GrainOverlay.swift`
  - **Deps:** none
  - **Scope:** SwiftUI view rendering a procedural noise texture via `CIFilter.randomGenerator()` at 2% opacity. Tiled to fill bounds.
  - **Done when:** Preview shows subtle grain. Performance: 60fps overlay on iPhone 17 sim.

- [x] **7.2** — Apply grain + corner vignette to `HomeScreen` — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 7.1
  - **Scope:** Overlay `GrainOverlay()` on the `#070707` background. Add corner vignette as a `RadialGradient` (transparent center → 3% black at corners).
  - **Done when:** Side-by-side screenshots before/after show subtle warmth difference.

- [x] **7.3** — Add slot rail top-edge highlight — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift` (FocusModuleCard rail rendering)
  - **Deps:** none
  - **Scope:** Rail gets a 1pt linear gradient: top edge ~15% brighter than slot accent base; fades over first 8pt of rail height. Reads as light catching a control surface.
  - **Done when:** Sim screenshot shows the highlight on all three slots.

---

## Phase C — Platform features

### Step 8 — Live Activity + Dynamic Island

- [x] **8.1** — Create `EmberLiveActivityWidget` extension target — DONE (Claude)
  - **Files:** `Ember/Ember.xcodeproj/project.pbxproj`, NEW `EmberLiveActivityWidget/EmberLiveActivityWidgetBundle.swift`
  - **Deps:** none
  - **Scope:** Xcode → File → New Target → Widget Extension → "Include Live Activity". App Group: `group.com.ember.focus`. Bundle ID: `com.ember.Ember.LiveActivity`.
  - **Done when:** Target builds. New scheme appears.

- [x] **8.2** — Define `FocusSessionAttributes` — DONE (Claude)
  - **Files:** NEW `Ember/Services/FocusSessionAttributes.swift` (shared with both targets via membership)
  - **Deps:** 8.1
  - **Scope:** `struct FocusSessionAttributes: ActivityAttributes` with fixed `taskID: String`, `taskTitle: String`, `startedAt: Date`. Content state `ContentState { var completedCount: Int }`.
  - **Done when:** Compiles in both main app and Live Activity targets.

- [x] **8.3** — Implement Live Activity lock screen UI — DONE (Claude)
  - **Files:** NEW `EmberLiveActivityWidget/FocusSessionLiveActivity.swift`
  - **Deps:** 8.2
  - **Scope:** `ActivityConfiguration(for: FocusSessionAttributes.self)` with a mini Daily Orbit view (12 dots) + task title + completion count.
  - **Done when:** Sim shows lock screen activity when started.

- [x] **8.4** — Implement Dynamic Island compact/expanded/minimal — DONE (Claude)
  - **Files:** `EmberLiveActivityWidget/FocusSessionLiveActivity.swift`
  - **Deps:** 8.3
  - **Scope:** Compact: trailing = "1/3" dots, leading = ember dot. Expanded: 3-dot progress + title. Minimal: single ember dot.
  - **Done when:** Sim DI states all render correctly.

- [x] **8.5** — Implement `FocusSessionService` — DONE (Claude)
  - **Files:** NEW `Ember/Services/FocusSessionService.swift`
  - **Deps:** 8.2
  - **Scope:** `static let shared`. Methods `start(for task:) async`, `update(completedCount:) async`, `end() async`. Wraps `ActivityKit.Activity` lifecycle in `if #available(iOS 16.1, *)`.
  - **Done when:** Unit-testable (mock auth + activity creation).

- [x] **8.6** — Add "Start focus session" button to `TaskDetailScreen` — DONE (Claude)
  - **Files:** `Ember/Screens/TaskDetailScreen.swift`
  - **Deps:** 8.5
  - **Scope:** Button visible when task is incomplete. Tap calls `FocusSessionService.shared.start(for: task)`. Button text toggles to "End focus session" when active.
  - **Done when:** Sim flow: tap start → lock screen activity appears.

- [x] **8.7** — Wire HomeScreen completion → Live Activity update — DONE (Claude)
  - **Files:** `Ember/Screens/HomeScreen.swift`, `Ember/Services/TaskCompletionCoordinator.swift`
  - **Deps:** 8.5, 1.7
  - **Scope:** Coordinator's `complete(_:)` checks if a session is active for that task → calls `FocusSessionService.update(completedCount:)`. Ends activity if `allCompleted` becomes true.
  - **Done when:** Complete a task during active session → DI updates immediately.

- [x] **8.8** — Implement `ScheduledSessionWatcher` — DONE (Claude)
  - **Files:** NEW `Ember/Services/ScheduledSessionWatcher.swift`
  - **Deps:** 8.5
  - **Scope:** Observes scheduled tasks on app launch + `.scenePhase` change. When a task's `scheduledTime` window arrives AND task is incomplete AND no session active AND user hasn't dismissed for that task today, auto-start a session.
  - **Done when:** Unit test: stub task with scheduled time = now, watcher starts session.

- [x] **8.9** — Add `autoStartScheduledSessions` toggle + dismissal storage — DONE (Claude)
  - **Files:** `Ember/Services/EmberPreferences.swift`, `Ember/Screens/SettingsScreen.swift`
  - **Deps:** 8.8
  - **Scope:** New `autoStartScheduledSessions: Bool = true` UserDefaults key. New `dismissedAutoSessions: [UUID: Date]` storage. Settings toggle UI. Live Activity action button to dismiss-for-today.
  - **Done when:** Toggle off → watcher no-ops. Dismiss action → no auto-start for that task that day.

- [x] **8.10** — Wire watcher into `EmberApp` lifecycle — DONE (Claude)
  - **Files:** `Ember/EmberApp.swift`
  - **Deps:** 8.8
  - **Scope:** Instantiate `ScheduledSessionWatcher` on app init. Hook to `.onChange(of: scenePhase)` to re-evaluate on foreground.
  - **Done when:** Background → foreground triggers a watcher pass.

---

### Step 9 — Interactive widgets + App Intents + Siri

- [x] **9.1** — Create `CompleteTaskIntent` `AppIntent` — DONE (Codex)
  - **Files:** NEW `EmberWidget/Intents/CompleteTaskIntent.swift` (shared with main app)
  - **Deps:** 1.7
  - **Scope:** `AppIntent` with `taskID: String` parameter. `perform()` resolves task in shared container → calls `TaskCompletionCoordinator.shared.complete(_:)` → returns `WidgetCenter.shared.reloadAllTimelines()`.
  - **Done when:** Intent invokable via Shortcuts app.
  - **Note:** Implemented against the shared App Group SwiftData store directly so the same intent compiles from the widget extension and app shortcut provider; it mirrors coordinator completion side effects by cancelling the reminder, updating `DailyRecord`, saving, and reloading widgets.

- [x] **9.2** — Create `AddTaskIntent` `AppIntent` — DONE (Codex)
  - **Files:** NEW `EmberWidget/Intents/AddTaskIntent.swift`
  - **Deps:** none
  - **Scope:** `AppIntent` with `title: String`. `perform()` opens app (via `openAppWhenRun = true`) with a deep link to `AddTaskView` pre-populated.
  - **Done when:** Siri "add focus" opens app with title pre-filled.
  - **Note:** Stores the pending title in App Group defaults and opens `ember://add?title=...`; Step 10 now consumes that pending title in `AddTaskView`.

- [x] **9.3** — Create `ShowTodayIntent` `AppIntent` — DONE (Codex)
  - **Files:** NEW `EmberWidget/Intents/ShowTodayIntent.swift`
  - **Deps:** none
  - **Scope:** `AppIntent` returning a `String` summary (e.g. "You have 1 of 3 done. Slot 2 is: Ship the migration."). Used for "Hey Siri, what are my three for today".
  - **Done when:** Siri returns spoken summary.

- [x] **9.4** — Register `EmberAppShortcutsProvider` — DONE (Codex)
  - **Files:** NEW `Ember/Services/EmberAppShortcutsProvider.swift`
  - **Deps:** 9.1, 9.2, 9.3
  - **Scope:** `AppShortcutsProvider` exposing the three intents with natural phrases: "Add focus to Ember", "What are my three for today", "Mark focus as done".
  - **Done when:** Settings → Siri & Search shows the shortcuts.

- [x] **9.5** — Wrap `EmberTodayWidget` rows in `Button(intent:)` — DONE (Codex)
  - **Files:** `EmberWidget/HomeScreenWidgetView.swift`, `EmberWidget/EmberWidget.swift`
  - **Deps:** 9.1
  - **Scope:** Each task row wraps in `Button(intent: CompleteTaskIntent(taskID: task.id))`. Add `+ Add focus` button at bottom triggering `AddTaskIntent`.
  - **Done when:** Add widget to home screen, tap a task → completes without opening app.
  - **Note:** `EmberWidget.swift` did not need a configuration change; interaction lives entirely in the widget view.

---

### Step 10 — System integrations

- [x] **10.1** — Spotlight indexing service — DONE (Codex)
  - **Files:** NEW `Ember/Services/SpotlightService.swift`
  - **Deps:** 1.7
  - **Scope:** `index(_ task:)` adds `CSSearchableItem`. `deindex(_:)` removes. Hooked from `AddTaskView` save, `TaskDetailScreen` save, and `TaskCompletionCoordinator` delete.
  - **Done when:** Search task title in Spotlight → result appears.
  - **Note:** Hooking required small necessary touches in `AddTaskView`, `TaskDetailScreen`, and `TaskCompletionCoordinator`; Spotlight entries include `ember://task/{uuid}` content URLs.

- [x] **10.2** — URL scheme + Universal Link handler — DONE (Codex)
  - **Files:** `Ember/Info.plist`, `Ember/EmberApp.swift`, `Ember/Navigation/EmberRouter.swift`
  - **Deps:** none
  - **Scope:** `CFBundleURLTypes` registers `ember://`. `EmberApp` `.onOpenURL` parses `ember://task/{uuid}` → router navigates to TaskDetailScreen.
  - **Done when:** `xcrun simctl openurl <udid> "ember://task/<uuid>"` opens the right detail screen.
  - **Note:** URL handling lives in `ContentView` so it can access both `EmberRouter` and `ModelContext`; router handles `ember://task/{uuid}` and `ember://add?title=...`. Add-task pending title storage now uses the same App Group key as `AddTaskIntent`.

- [x] **10.3** — Create `EmberShareExtension` target — DONE (Codex)
  - **Files:** `Ember/Ember.xcodeproj/project.pbxproj`, NEW `EmberShareExtension/ShareViewController.swift`, NEW `EmberShareExtension/Info.plist`
  - **Deps:** 9.2
  - **Scope:** Xcode → File → New Target → Share Extension. Accept `public.plain-text`. Controller forwards selected text to shared App Group, then via `AddTaskIntent` creates the task.
  - **Done when:** Safari → Share → "Add to Ember" → task created.
  - **Note:** Added `EmberShareExtension` target and embedded `.appex`; it accepts text/web URLs, writes the shared pending-title key, then opens `ember://add`.

- [x] **10.4** — Focus filter intent — DONE (Codex)
  - **Files:** NEW `Ember/Services/EmberFocusFilter.swift`, `Ember/Services/EmberPreferences.swift`, `Ember/Screens/HomeScreen.swift`
  - **Deps:** none
  - **Scope:** `SetFocusFilterIntent` with `showOnlyHighPriority: Bool` (= slot 01 only). Filter state stored in preferences. HomeScreen reads + hides slots 02/03 when active.
  - **Done when:** Settings → Focus → Work → Filter → Ember → "Show only slot 1" → toggling Work focus on filters Home.
  - **Note:** Implemented as `EmberFocusFilter.showOnlyPrimarySlot`; Home uses `@AppStorage` to render slot 01 only while active.

- [x] **10.5** — StandBy `accessoryRectangular` landscape variant — DONE (Codex)
  - **Files:** `EmberWidget/LockScreenWidgetView.swift`, `EmberWidget/EmberWidget.swift`
  - **Deps:** none
  - **Scope:** Existing `.accessoryRectangular` family already declared. Tune layout for landscape orientation (wider, larger orbit). Test in StandBy sim.
  - **Done when:** Phone on side + charging → StandBy shows Ember rectangular widget cleanly.
  - **Note:** Rectangular widget now switches to a wider StandBy-style layout via geometry, with a larger progress orbit and compact task list.

---

## Phase D — UX depth

### Step 11 — Streak repair

- [x] **11.1** — Add `isFrozen` to `DailyRecord` model — DONE (Codex)
  - **Files:** `Ember/Models/DailyRecord.swift`
  - **Deps:** none
  - **Scope:** New `var isFrozen: Bool = false` field. SwiftData handles migration automatically for additive changes. Verify the migration on a fresh sim install vs an upgrade.
  - **Done when:** Build green. Existing data loads cleanly.

- [x] **11.2** — Update `StreakService` + freeze tests — DONE (Codex)
  - **Files:** `Ember/Services/StreakService.swift`, NEW `EmberTests/StreakServiceFreezeTests.swift`
  - **Deps:** 11.1
  - **Scope:** Treat `isFrozen == true` days as transparent — streak passes through them. Tests: gap-with-freeze passes; 2 gaps with 1 freeze breaks.
  - **Done when:** Tests pass.

- [x] **11.3** — StreakScreen repair CTA — DONE (Codex)
  - **Files:** `Ember/Screens/StreakScreen.swift`, `Ember/Services/EmberPreferences.swift`
  - **Deps:** 11.2
  - **Scope:** When current streak just broke and `freezeUsedDates` has no entry for current month, show "Repair yesterday" CTA. Tap consumes the monthly freeze + flips yesterday's `DailyRecord.isFrozen = true`.
  - **Done when:** Sim: skip a day → CTA appears → tap → streak restored.

---

### Step 12 — Schedule timeline view

- [x] **12.1** — Create `ScheduleTimelineScreen` DONE (Codex)
  - **Files:** NEW `Ember/Screens/ScheduleTimelineScreen.swift`
  - **Deps:** none
  - **Scope:** Vertical timeline 6am–11pm with hour gridlines. Scheduled tasks render as cards positioned by `scheduledTime`. Empty hours = thin dividers.
  - **Done when:** Standalone preview with 3 scheduled tasks looks right.
  - **Note:** Added a dense dark timeline with a current-time marker and column handling for overlapping scheduled cards.

- [x] **12.2** — Add `.schedule` route to `EmberRouter` DONE (Codex)
  - **Files:** `Ember/Navigation/EmberRouter.swift`, `Ember/ContentView.swift`
  - **Deps:** 12.1
  - **Scope:** New route case + ContentView destination wiring.
  - **Done when:** Router can navigate to `.schedule`.
  - **Note:** Added the route case and wired the destination directly into the existing `NavigationStack`.

- [x] **12.3** — Add "View schedule" header link in `HomeScreen` DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift`
  - **Deps:** 12.2
  - **Scope:** Tiny "VIEW SCHEDULE" pill in header when `todayTasks.contains(where: \.scheduledTime != nil)`. Tap → navigate to `.schedule`.
  - **Done when:** Sim: schedule a task → pill appears → tap → timeline opens.
  - **Note:** The header pill sits under the live time readout and only appears when at least one of today’s tasks has a scheduled time.

---

### Step 13 — Reflection variety + past reflections

- [x] **13.1** — Create `ReflectionPrompts` service — DONE (Codex)
  - **Files:** NEW `Ember/Services/ReflectionPrompts.swift`
  - **Deps:** 1.3
  - **Scope:** Array of 10 curated prompts. `prompt(for date: Date) -> String` returns deterministic rotation via `dayOfYear % 10`. Uses injected DateService.
  - **Done when:** Same date → same prompt. Adjacent dates → different.

- [x] **13.2** — Wire `ReflectionScreen` to use rotating prompt — DONE (Codex)
  - **Files:** `Ember/Screens/ReflectionScreen.swift`
  - **Deps:** 13.1
  - **Scope:** Replace hardcoded prompt with `ReflectionPrompts.prompt(for: today)`.
  - **Done when:** Different prompt visible day-to-day in sim.

- [x] **13.3** — Build `PastReflectionSheet` + long-press hook — DONE (Codex)
  - **Files:** NEW `Ember/Screens/PastReflectionSheet.swift`, `Ember/Screens/StreakScreen.swift`
  - **Deps:** none
  - **Scope:** Sheet displays a single Reflection for a date. Long-press any calendar day on StreakScreen with a saved reflection → presents the sheet.
  - **Done when:** Sim: save reflection today → long-press today on calendar → sheet shows the text.
  - **Note:** Tap still opens the existing day-history sheet; long-press now opens the reflection-only archive sheet when that date has saved text.

---

## Phase E — Identity

### Step 14 — Theme palettes + OLED black

- [x] **14.1** — Define `EmberTheme` enum — DONE (Codex)
  - **Files:** NEW `Ember/DesignSystem/EmberTheme.swift`
  - **Deps:** none
  - **Scope:** `enum EmberTheme: String, CaseIterable { case ember, electric, bone, magma }`. Each case exposes accent + accent variants (pressed, subtle).
  - **Done when:** All 4 cases compile with full color spec.

- [x] **14.2** — Make `EmberColors` theme-aware — DONE (Codex)
  - **Files:** `Ember/DesignSystem/EmberColors.swift`
  - **Deps:** 14.1, 14.3
  - **Scope:** Convert `static let ember` to `static var ember: Color { currentTheme.accent }`. Same for slot 01 + accent-derived values.
  - **Done when:** Switching theme in Settings recolors the whole app on next render.

- [x] **14.3** — Add theme + OLED preferences storage — DONE (Codex)
  - **Files:** `Ember/Services/EmberPreferences.swift`
  - **Deps:** 14.1
  - **Scope:** `currentTheme: EmberTheme` + `oledBlackEnabled: Bool` UserDefaults keys with getters/setters.
  - **Done when:** Set/get round-trips correctly.

- [x] **14.4** — Theme picker UI in `SettingsScreen` — DONE (Codex)
  - **Files:** `Ember/Screens/SettingsScreen.swift`
  - **Deps:** 14.2, 14.3
  - **Scope:** Horizontal swatch picker showing 4 theme accents + OLED black toggle. Selection animates the app's accent globally.
  - **Done when:** Sim: pick electric → HomeScreen orbit + slot 01 turn cyan.

- [x] **14.5** — OLED background swap — DONE (Codex)
  - **Files:** `Ember/Screens/HomeScreen.swift` (and any screen using `#070707` directly)
  - **Deps:** 14.3
  - **Scope:** Background `#070707` becomes `#000000` when `oledBlackEnabled == true`. Grain overlay opacity drops to 1%.
  - **Done when:** Toggle in Settings flips background.
  - **Note:** Studio screens now read shared `EmberColors.studioBackground` and `EmberColors.ember`, so theme selection and OLED black carry across the dark-shell surfaces on next render.

---

### Step 15 — App icon variants

- [x] **15.1** — Design + add icon variants to Assets (Codex)
  - **Files:** `Ember/Assets.xcassets/AppIcon-Black.appiconset/`, `AppIcon-Minimal.appiconset/`, `AppIcon-Magma.appiconset/`
  - **Deps:** none
  - **Scope:** Three alternate icon sets: Black (all-black ember dot), Minimal (single ember dot on dark), Magma (deep red ember on near-black). 1024×1024 + standard sizes. User can provide PNGs OR agent generates programmatic ones.
  - **Done when:** Asset sets exist with required sizes; Xcode shows no warnings.

- [x] **15.2** — Configure `CFBundleIcons` for alternates (Codex)
  - **Files:** `Ember/Info.plist`
  - **Deps:** 15.1
  - **Scope:** Add `CFBundleAlternateIcons` dict declaring the three variants.
  - **Done when:** Settings → General → App icon list includes them (verifiable in sim).

- [x] **15.3** — `AppIconService` + picker UI (Codex)
  - **Files:** NEW `Ember/Services/AppIconService.swift`, `Ember/Screens/SettingsScreen.swift`
  - **Deps:** 15.2
  - **Scope:** Service wraps `UIApplication.shared.setAlternateIconName(_:)`. Settings picker grid shows current + alternates. Tap → switch.
  - **Done when:** Sim: switch icon → home screen icon changes on next app launch.
  - **Note:** Programmatic Black / Minimal / Magma icon PNGs were generated into asset catalogs and the picker/service compile cleanly. Generic iOS build succeeded. Simulator test/install verification was blocked during Step 15 by the preexisting `EmberShareExtension.appex` missing `CFBundleDisplayName` issue; RH-1 later resolved that install blocker.

---

## Release Hardening (v1)

Source of truth: `RELEASE_HARDENING_PLAN.md`.

- [x] **RH-1** — Fix share extension install blocker — DONE (Codex)
  - **Files:** `EmberShareExtension/Info.plist`, `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md`
  - **Scope:** Added non-empty `CFBundleDisplayName` (`Ember Share`) to the share extension plist.
  - **Verification:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` succeeded. Tests executed past app install and ran on `Clone 1 of iPhone 17`.

- [x] **RH-2** — Make App Store v1 iPhone-only — DONE (Codex)
  - **Files:** `Ember.xcodeproj/project.pbxproj`, `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md`
  - **Deps:** RH-1
  - **Scope:** Change main app target `TARGETED_DEVICE_FAMILY` from `"1,2"` to `1`; mark Step 16 deferred for v2.
  - **Verification:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded. Built app `UIDeviceFamily` is `[1]`.

- [x] **RH-3** — Treat warnings as release blockers — DONE (Codex)
  - **Files:** `EmberWidget/Intents/AddTaskIntent.swift`, `EmberWidget/Intents/CompleteTaskIntent.swift`, `EmberWidget/Intents/ShowTodayIntent.swift`, `Ember/Services/EmberAppShortcutsProvider.swift`, `Ember/Services/EmberFocusFilter.swift`, `Ember/Services/FocusSessionAttributes.swift`, `Ember/Services/FocusSessionService.swift`, `Ember/Screens/ScheduleTimelineScreen.swift`, `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md`
  - **Deps:** RH-2
  - **Scope:** Fixed App Intents static concurrency warnings, updated ActivityKit calls away from deprecated APIs, removed ActivityKit isolation warnings, and changed the timeline lane local from `var` to `let`.
  - **Verification:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded. `rg -n "warning:|error:" /tmp/ember-rh3-build.log` returned no matches.

---

## Phase F — Adaptive

### Step 16 — iPad layout (deferred to v2)

- [-] **16.1** — Branch `ContentView` on `horizontalSizeClass` — DEFERRED to v2
  - **Files:** `Ember/ContentView.swift`
  - **Deps:** none
  - **Scope:** iPad (`.regular` width) wraps content in `NavigationSplitView`. Sidebar: nav (orbit thumbnail + nav buttons). Detail: current screen.
  - **Done when:** iPad sim shows split view; iPhone sim unchanged.
  - **Note:** Deferred by RH-2. App Store v1 is iPhone-only.

- [-] **16.2** — Audit screens for fixed widths — DEFERRED to v2
  - **Files:** All under `Ember/Screens/`
  - **Deps:** 16.1
  - **Scope:** Look for `.frame(width:)` and hardcoded layout assumptions. Replace with `.frame(maxWidth:)` or container queries. Focus modules stay max ~600pt wide on iPad.
  - **Done when:** Every screen renders correctly at iPad sizes.
  - **Note:** Deferred by RH-2. App Store v1 is iPhone-only.

- [-] **16.3** — Enable iPad family + verify — DEFERRED to v2
  - **Files:** `Ember/Ember.xcodeproj/project.pbxproj`
  - **Deps:** 16.2
  - **Scope:** v2 should re-enable `TARGETED_DEVICE_FAMILY = 1,2`, build for iPad, and smoke test core flows.
  - **Done when:** App runs on iPad sim, all core flows work.
  - **Note:** Deferred by RH-2. App Store v1 is iPhone-only.

---

## File Structure Reference

Use this map before starting a new step. The active Xcode project root is the inner repo: `/Users/sheikhhassan/Desktop/iOS APP/Ember/Ember`.

```text
Ember/
├── ROADMAP.md                         # Atomic forward plan and coordination status
├── HANDOFF.md                         # Current app context, recent changes, QA notes
├── PROGRESS.md                        # Historical build/progress checklist
├── DESIGN_V2.md                       # Current dark studio design language
├── Ember.xcodeproj/
│   └── project.pbxproj                # Targets/build settings; uses synchronized filesystem groups
├── Ember/                             # Main app target
│   ├── EmberApp.swift                 # SwiftUI app entry, shared SwiftData container
│   ├── ContentView.swift              # Root NavigationStack and route destinations
│   ├── PrivacyInfo.xcprivacy          # Required reason API declarations
│   ├── Assets.xcassets/               # App icon/accent assets
│   ├── Components/                    # Reusable SwiftUI components
│   │   ├── AmbientGlow.swift
│   │   ├── CompletionBloom.swift      # Completion radial bloom component
│   │   ├── EmberButton.swift
│   │   ├── EmptyTaskSlot.swift
│   │   ├── GlassCardModifier.swift
│   │   ├── NoiseOverlay.swift
│   │   ├── StreakBadge.swift
│   │   ├── SubtaskRow.swift
│   │   └── TaskCard.swift             # Legacy/reusable task card component
│   ├── DesignSystem/                  # Shared visual tokens and view modifiers
│   │   ├── EmberAnimations.swift
│   │   ├── EmberColors.swift
│   │   ├── EmberCornerRadii.swift
│   │   ├── EmberGradients.swift
│   │   ├── EmberShadows.swift
│   │   ├── EmberSpacing.swift
│   │   ├── EmberSymbolEffects.swift   # Step 2 SF Symbol effect helpers
│   │   └── EmberTypography.swift
│   ├── Models/                        # SwiftData models
│   │   ├── DailyRecord.swift
│   │   ├── EmberTask.swift
│   │   ├── Reflection.swift
│   │   └── Subtask.swift
│   ├── Navigation/
│   │   └── EmberRouter.swift          # Route enum and observable navigation state
│   ├── Screens/                       # Main user-facing flows
│   │   ├── AddTaskSheet.swift
│   │   ├── AddTaskView.swift
│   │   ├── CarryForwardView.swift
│   │   ├── HomeScreen.swift           # Daily Orbit, task slots, hold/reorder, covers
│   │   ├── MorningRitualView.swift
│   │   ├── ReflectionScreen.swift
│   │   ├── SettingsScreen.swift
│   │   ├── StreakScreen.swift
│   │   ├── TaskDetailScreen.swift
│   │   └── TranscendenceView.swift
│   ├── Services/                      # Backend seams, persistence helpers, platform services
│   │   ├── AudioService.swift
│   │   ├── DailyRecordService.swift
│   │   ├── DateService.swift          # EmberClock seam, day-boundary logic
│   │   ├── EmberLogger.swift
│   │   ├── EmberPreferences.swift     # UserDefaults keys: sound/haptics/reduced motion/morning ritual
│   │   ├── HapticService.swift
│   │   ├── ReminderService.swift
│   │   ├── StreakService.swift
│   │   └── TaskCompletionCoordinator.swift
│   └── Utilities/
│       ├── Color+Hex.swift
│       ├── Date+Extensions.swift
│       └── View+Extensions.swift
├── EmberTests/                        # Unit tests
│   ├── DateServiceTimezoneTests.swift
│   ├── EmberLoggerTests.swift
│   ├── EmberTests.swift
│   ├── ReminderServiceDateTests.swift
│   ├── TaskCompletionCoordinatorTests.swift
│   └── TestHelpers.swift
├── EmberUITests/                      # UI tests
│   ├── EmberUITests.swift
│   └── EmberUITestsLaunchTests.swift
└── EmberWidget/                       # Widget extension source
    ├── EmberWidget.swift              # Widget registrations
    ├── EmberWidgetBundle.swift
    ├── EmberWidgetProvider.swift
    ├── HomeScreenWidgetView.swift
    ├── LockScreenWidgetView.swift
    ├── SharedDataProvider.swift       # Widget-side SwiftData/App Group reader
    ├── Info.plist
    └── Assets.xcassets/
```

Quick orientation:
- The app uses Xcode synchronized filesystem groups, so new files under `Ember/`, `EmberTests/`, and `EmberWidget/` are picked up by target membership unless explicitly excepted in `project.pbxproj`.
- Widget target shares main app models through synchronized group exceptions in `project.pbxproj`; keep widget-safe code out of main-app-only services.
- `HomeScreen.swift` contains private nested views for `DailyOrbitView`, `FocusModuleCard`, and `EmptyFocusModule`.
- `TaskCompletionCoordinator` is the canonical mutation path for complete/uncomplete/delete/reminder coordination.
- Reduced-motion preference is `EmberPreferenceKey.reducedMotionEnabled`; use `@AppStorage` or existing helpers for animated UI.
- Build with: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build`.

---

## Verification rhythm

After each task:
1. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' build` — zero warnings, zero errors.
2. `xcodebuild test -only-testing:EmberTests -only-testing:EmberUITests` — all pass.
3. Manual sim walk if user-visible.
4. Update this file's checkbox.
5. Update `PROGRESS.md` if it represents a meaningful milestone.
6. Update `HANDOFF.md` "Recent Changes" at the end of each Step (not each sub-task).
7. Commit with `<task-id>: <title>` subject.

---

## Open questions parked

- **Step 15.1** — Resolved: programmatic geometric icon variants were generated locally for the first pass.
- **Step 4.1** — User downloads Inter Tight ttf, or agent fetches via `curl` from rsms.me?
- **Step 8 sim** — Live Activity needs iPhone 14 Pro+ sim for Dynamic Island. Confirm test device.

Surface these to user when the relevant step starts; don't block earlier steps.
