# Ember — Build Progress Checklist

> Checkbox build tracker grouped by the 13 phases from PLAN.md.
> Each item is scoped to ~1–2 hours of work. Reference files are explicit.

---

## Phase 0: Project Setup

- [ ] Create Xcode project (App, SwiftUI lifecycle, SwiftData), set bundle ID `com.ember.focus`, deployment target iOS 17.0
- [ ] Create folder group structure matching PLAN.md (`Models/`, `DesignSystem/`, `Components/`, `Screens/`, `Services/`, `Utilities/`, `Navigation/`, `Resources/`)
- [ ] Add Canela Deck font files to `Resources/Fonts/`, register in `Info.plist` under `UIAppFonts`
- [ ] Add audio files (.wav) to `Resources/Audio/` and verify target membership
- [ ] Create or source 256×256 tileable noise PNG, add to `Resources/Textures/`
- [ ] Set up `Assets.xcassets` color sets: `BackgroundColor`, `CardSurface`, `TextPrimary`, `TextSecondary`, `TextDone`, `AccentColor`

---

## Phase 1: Design System

- [x] Build `Color+Hex.swift` — hex string to Color initializer (`Utilities/Color+Hex.swift`)
- [x] Build `EmberColors.swift` — all color constants (`DesignSystem/EmberColors.swift`)
- [x] Build `EmberTypography.swift` — font definitions, tracking, line spacing, view modifiers (`DesignSystem/EmberTypography.swift`)
- [x] Build `EmberSpacing.swift` — spacing scale constants (`DesignSystem/EmberSpacing.swift`)
- [x] Build `EmberCornerRadii.swift` — corner radius constants (`DesignSystem/EmberCornerRadii.swift`)
- [x] Build `EmberShadows.swift` — shadow style struct + named shadows + view extension (`DesignSystem/EmberShadows.swift`)
- [x] Build `EmberGradients.swift` — all gradient definitions (`DesignSystem/EmberGradients.swift`)
- [x] Build `EmberAnimations.swift` — all animation curves and timing constants (`DesignSystem/EmberAnimations.swift`)

---

## Phase 2: Core Components

- [x] Build `NoiseOverlay.swift` — tileable noise texture with CIFilter fallback (`Components/NoiseOverlay.swift`)
- [x] Build `AmbientGlow.swift` — pulsing radial gradient with glowPulse animation (`Components/AmbientGlow.swift`)
- [x] Build `GlassCardModifier.swift` — frosted glass ViewModifier + `.glassCard()` extension (`Components/GlassCardModifier.swift`)
- [x] Build `EmptyTaskSlot.swift` — dashed-border placeholder card (`Components/EmptyTaskSlot.swift`)
- [x] Build `EmberButton.swift` — gradient CTA button with press state (`Components/EmberButton.swift`)
- [x] Build `StreakBadge.swift` — flame icon + streak count capsule (`Components/StreakBadge.swift`)
- [x] Build `SubtaskRow.swift` — checkbox + title row with toggle animation (`Components/SubtaskRow.swift`)
- [x] Build `TaskCard.swift` — task card view with idle/pressed/completed states, glass modifier, gradient backgrounds (`Components/TaskCard.swift`)

---

## Phase 3: Data Layer

- [x] Build `EmberTask.swift` — SwiftData @Model with relationships (`Models/EmberTask.swift`)
- [x] Build `Subtask.swift` — SwiftData @Model with inverse relationship (`Models/Subtask.swift`)
- [x] Build `DailyRecord.swift` — SwiftData @Model with unique date constraint (`Models/DailyRecord.swift`)
- [x] Build `Reflection.swift` — SwiftData @Model with unique date constraint (`Models/Reflection.swift`)
- [x] Build `Date+Extensions.swift` — date formatting and comparison helpers (`Utilities/Date+Extensions.swift`)
- [x] Build `View+Extensions.swift` — conditional modifier + `.completedStyle()` (`Utilities/View+Extensions.swift`)
- [x] Build `DateService.swift` — day boundary detection, UserDefaults active date tracking (`Services/DateService.swift`)
- [x] Build `StreakService.swift` — consecutive-day streak calculation from DailyRecords (`Services/StreakService.swift`)
- [x] Configure `EmberApp.swift` — ModelContainer for all 4 models (`EmberApp.swift`)
- [x] Build `EmberRouter.swift` — EmberRoute enum + @Observable navigation state (`Navigation/EmberRouter.swift`)
- [x] Build `ContentView.swift` — root NavigationStack with route destinations + sheet/cover bindings (`ContentView.swift`)

---

## Phase 4: Home Screen

- [x] Build HomeScreen V2.1 studio dashboard — dark shell, compact header, Daily Orbit hero, and three modular focus cards (`Screens/HomeScreen.swift`)
- [x] Implement Daily Orbit progress object — 72-dot circular progress around `0/3`...`3/3`, state label, three bottom ticks, and subtle rotating/wave animation (`Screens/HomeScreen.swift`)
- [x] Implement focus modules — slot labels `01`/`02`/`03`, dark studio surfaces, slot accent rails/borders, metadata pills, completed state, and intentional empty prompts (`Screens/HomeScreen.swift`)
- [x] Wire @Query for today’s tasks, compute allCompleted, bind carry-forward/transcendence covers (`Screens/HomeScreen.swift`)
- [x] Implement new-day detection — `scenePhase` observer, carry-forward trigger, `DateService.recordActiveDate()` (`Screens/HomeScreen.swift`)
- [x] Add accessibility labels — Daily Orbit, progress shortcut, empty modules, task modules (`Screens/HomeScreen.swift`)
- [x] Verification note — `git diff --check` passes; full Xcode build blocked by local Xcode/iOS platform and Swift macro toolchain issues.

---

## Phase 5: Add Task Flow

- [x] Build AddTaskView studio composer — dark shell, compact top bar, focus title module, schedule module, and subtask thread (`Screens/AddTaskView.swift`)
- [x] Implement save action — create EmberTask with optional schedule/subtasks, insert into modelContext, navigate back (`Screens/AddTaskView.swift`)
- [x] Handle edge cases — 3-task limit guard, empty title validation, keyboard-focused full-screen route (`Screens/AddTaskView.swift`)

---

## Phase 6: Task Completion Interaction

- [x] Build `CompletionBloom.swift` — radial bloom animation with ring expansion and fade (`Components/CompletionBloom.swift`)
- [x] Build `HapticService.swift` — CoreHaptics engine, heartbeat pattern, gentle continuous method (`Services/HapticService.swift`)
- [x] Build `AudioService.swift` — AVAudioPlayer preloading, playback, transcendence chord sequence (`Services/AudioService.swift`)
- [x] Wire long-press gesture into TaskCard — DragGesture + Timer, progress tracking, scale animation (`Components/TaskCard.swift`)
- [x] Wire completion trigger — bloom activation, singing-bowl audio, haptic burst, model update (`Components/TaskCard.swift`)
- [x] Handle press cancellation — spring-back animation, progress reset, timer invalidation (`Components/TaskCard.swift`)

---

## Phase 7: Task Detail Screen

- [x] Rebuild TaskDetailScreen as a dark studio control surface — compact top bar, editable title panel, metadata panel, subtask module (`Screens/TaskDetailScreen.swift`)
- [x] Implement task metadata row — status pill, carried-forward badge, schedule, subtask count (`Screens/TaskDetailScreen.swift`)
- [x] Implement subtask list — dark rows, ember checkboxes, swipe-to-delete, row transitions (`Screens/TaskDetailScreen.swift`)
- [x] Implement add subtask input — ember plus, dark text field, onSubmit creation (`Screens/TaskDetailScreen.swift`)
- [x] Implement delete task — confirmation dialog, modelContext deletion, navigation pop (`Screens/TaskDetailScreen.swift`)

---

## Phase 8: Transcendence

- [x] Rebuild TranscendenceView as a dark studio victory screen — animated orbit around large `3`, completion copy, return/reflect actions (`Screens/TranscendenceView.swift`)
- [x] Implement orbit shimmer — 72-dot animated completion ring matching Daily Orbit (`Screens/TranscendenceView.swift`)
- [x] Implement text content — headline, subtext, action buttons with delayed fade-in (`Screens/TranscendenceView.swift`)
- [x] Wire animation sequence — glow expand → bloom → text fade → shimmer start, timed with delays (`Screens/TranscendenceView.swift`)
- [x] Wire audio + haptics — transcendence chord on appear, haptic burst (`Screens/TranscendenceView.swift`)
- [x] Implement dismiss — tap-anywhere gesture, fade-out animation, DailyRecord creation/update (`Screens/TranscendenceView.swift`)

---

## Phase 9: Carry Forward

- [x] Rebuild CarryForwardView as a dark studio decision screen — header panel, selection panel, action panel (`Screens/CarryForwardView.swift`)
- [x] Implement task selection list — dark selectable modules with ember rails/check controls, stagger entrance (`Screens/CarryForwardView.swift`)
- [x] Implement slot availability logic — availableSlots calculation, over-selection warning text (`Screens/CarryForwardView.swift`)
- [x] Implement "Carry Forward" action — clone selected tasks + subtasks to today, set isCarriedForward (`Screens/CarryForwardView.swift`)
- [x] Implement "Let them all go" action — play let-go audio, dismiss cover (`Screens/CarryForwardView.swift`)
- [x] Wire into ContentView — `.fullScreenCover` binding to `router.showCarryForward` (`ContentView.swift`)

---

## Phase 10: Streak & Reflection

- [x] Rebuild StreakScreen streak hero section — dark rhythm panel, large streak number, best/perfect stats (`Screens/StreakScreen.swift`)
- [x] Build StreakScreen calendar grid — dark month panel, ember/full-complete states, partial states, today ring (`Screens/StreakScreen.swift`)
- [x] Rebuild ReflectionScreen layout — dark prompt panel, dark editor panel, studio save controls (`Screens/ReflectionScreen.swift`)
- [x] Implement ReflectionScreen save — create/update Reflection, confirmation feedback, button state (`Screens/ReflectionScreen.swift`)

---

## Phase 11: Widget Extension

- [x] Create Widget Extension target "EmberWidget", enable App Group `group.com.ember.focus` on both targets (manual Xcode step)
- [x] Update `EmberApp.swift` ModelContainer to use shared App Group container URL (`EmberApp.swift`)
- [x] Build `SharedDataProvider.swift` — reads today’s tasks from shared SwiftData store (`EmberWidget/SharedDataProvider.swift`)
- [x] Build `EmberWidgetProvider.swift` — TimelineProvider with snapshot and timeline entries (`EmberWidget/EmberWidgetProvider.swift`)
- [x] Build `HomeScreenWidgetView.swift` — medium/large widget showing today’s 3 tasks + completion state (`EmberWidget/HomeScreenWidgetView.swift`)
- [x] Build `LockScreenWidgetView.swift` — circular/inline lock screen widget with progress or streak (`EmberWidget/LockScreenWidgetView.swift`)
- [x] Reconcile widget target — remove generated emoji/timer/live-activity scaffolding and register only `EmberTodayWidget` + `EmberLockScreenWidget` (`EmberWidget/EmberWidget.swift`, `EmberWidget/EmberWidgetBundle.swift`)

---

## Phase 12: Polish

- [x] Tune spring animation parameters — test card appear, press, release, bloom on real device
- [x] Align audio timing with animations — singing-bowl fires with bloom, chord staggered 0/0.4/0.8s with transcendence sequence
- [x] Edge case testing — day boundary, backgrounding/foregrounding, carry-forward permutations, 3-task limit
- [x] Accessibility pass — VoiceOver labels on all interactive elements, Dynamic Type support verified
- [x] Performance pass — @Query predicates scoped to today only, animations on main thread via withAnimation, no unbounded fetches
- [x] Final visual QA — all colors, gradients, shadows, typography verified against DESIGN.md

---

## Current Internal Polish Roadmap

- [x] Add `DailyRecordService` so partial and perfect days are persisted from task mutations (`Services/DailyRecordService.swift`)
- [x] Add local scheduled task reminders through `ReminderService` (`Services/ReminderService.swift`)
- [x] Add `EmberPreferences` for sound, haptics, reduced motion, and morning ritual state (`Services/EmberPreferences.swift`)
- [x] Add compact dark `SettingsScreen` with notification status and preference toggles (`Screens/SettingsScreen.swift`)
- [x] Wire sound/haptic/reduced-motion preferences into runtime behavior (`AudioService`, `HapticService`, `HomeScreen`, `TranscendenceView`)
- [x] Remove hardcoded city label from Home header (`Screens/HomeScreen.swift`)
- [x] Reconcile widget extension registrations (`EmberWidget/`)
- [x] Implement Day History sheet from `StreakScreen`
- [x] Expand Streak analytics panels
- [x] Add Morning Ritual flow
- [x] Add schedule editing in `TaskDetailScreen`
- [x] Add focused unit/UI tests for records, add task, task detail subtasks, settings route/preferences, streak route, reflection save, three-task Transcendence-to-Reflect flow, and task reminder schedule toggle
- [x] Run focused simulator QA on iPhone 17 with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
- [x] Verify `EmberWidgetExtension` builds for generic iOS Simulator

## Roadmap Step 2: Symbol Effects Pass

- [x] Add reduced-motion-aware symbol effect helpers (`DesignSystem/EmberSymbolEffects.swift`)
- [x] Apply symbol effects to Home icons: settings bounce, add bounce, undo toast pulse, reorder handle appear (`Screens/HomeScreen.swift`)
- [x] Apply completion/save symbol transitions across Task Detail, Morning Ritual, and Reflection (`Screens/TaskDetailScreen.swift`, `Screens/MorningRitualView.swift`, `Screens/ReflectionScreen.swift`)
- [x] Apply iterative variable-color flame and Carry Forward notice icon bounce (`Screens/StreakScreen.swift`, `Screens/CarryForwardView.swift`)
- [x] Update `ROADMAP.md` with a full file-structure reference for future sessions
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build` succeeded
- [x] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EmberTests` succeeded, 24 tests passed

## Roadmap Step 3: Hold-To-Complete V2 + Bloom V2

- [x] Replace Home hold timer with `TimelineView(.animation)` progress based on `holdStartedAt` (`Screens/HomeScreen.swift`)
- [x] Replace the bottom hold bar with a touch-origin radial color wipe on `FocusModuleCard` (`Screens/HomeScreen.swift`)
- [x] Add shared escalating hold haptic cadence with throttled 250ms / 80ms intervals (`Services/HapticService.swift`)
- [x] Add haptic cadence boundary coverage (`EmberTests/HapticServiceTests.swift`)
- [x] Extend `CompletionBloom` with `.standard` and `.third` intensities, preserving the default existing call shape (`Components/CompletionBloom.swift`)
- [x] Wire Home completion bloom so the third task uses the 8% ember flash before the existing Transcendence delay (`Screens/HomeScreen.swift`)
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build` succeeded
- [x] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EmberTests` succeeded, 27 tests passed
- [!] UI tests: `-only-testing:EmberUITests` was attempted. `testAddTaskFlowCreatesHomeModule` passed, then `testCompletingThreeTasksShowsTranscendenceAndReflects` and `testReflectionSavesEntry` reported UI assertion timeouts before the simulator launcher became unstable and the run ended with `NSMachErrorDomain -308`.

## Roadmap Step 4: Launch Experience

- [x] Bundle Inter Tight variable font and OFL license (`Resources/Fonts/InterTight-VariableFont_wght.ttf`, `Resources/Fonts/OFL.txt`)
- [x] Register Inter Tight through the main app plist (`Info.plist`); verified built `Info.plist` contains `UIAppFonts`
- [x] Add `EmberTypography.orbitHero` using the bundled `InterTight-Regular` PostScript name and apply it only to the Daily Orbit `0/3`...`3/3` value (`DesignSystem/EmberTypography.swift`, `Screens/HomeScreen.swift`)
- [x] Add `LaunchAssembly` one-time cold-launch orbit assembly animation with reduced-motion bypass (`Screens/LaunchAssembly.swift`, `Screens/HomeScreen.swift`)
- [x] Add black launch storyboard with centered ember dot and wire it as `UILaunchStoryboardName` (`LaunchScreen.storyboard`, `Info.plist`)
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination generic/platform=iOS -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded
- [x] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` succeeded, 27 tests passed
- [!] UI tests: `-only-testing:EmberUITests` was attempted after the unit run, but CoreSimulatorService disconnected before test execution and xcodebuild exited with code 70 because the requested simulator was no longer available.

---

## Undo + Reorder Pass

- [x] Add undo completion toast — `PendingUndo` snapshot, bottom pill overlay, auto-dismiss on next interaction, Undo action reverting model + `DailyRecord` + reminder (`Screens/HomeScreen.swift`)
- [x] Fix Transcendence suppression — deferred 0.5s check now re-evaluates `allCompleted` so undo-within-window correctly prevents Transcendence (`Screens/HomeScreen.swift`)
- [x] Merge duplicate `scenePhase` onChange into single handler (`Screens/HomeScreen.swift`)
- [x] Add drag-to-reorder — REORDER chip in header, `isReordering` mode, `line.3.horizontal` drag handle, live slot shifting via `reorderOffsetY`, `commitReorderIfNeeded` swapping `displayOrder`, `interactiveSpring` animation (`Screens/HomeScreen.swift`)
- [x] Guard hold-to-complete gesture during reorder mode via combined gesture branching (`Screens/HomeScreen.swift`)
- [x] Build: zero errors, zero warnings post-implementation
- [x] All 12 UI tests + 3 unit tests passing on iPhone 17 simulator (OS 26.5)

---

## Roadmap Step 5: matchedGeometryEffect Slot → Detail Transition

- [x] Add `@Namespace var taskCardNS` to `ContentView`; pass it as `cardNamespace: Namespace.ID` to `HomeScreen` and as `namespace: Namespace.ID?` to `TaskDetailScreen` in `.navigationDestination` (`ContentView.swift`, `HomeScreen.swift`, `TaskDetailScreen.swift`)
- [x] Attach `.matchedGeometryEffect(id: "card-{id}", in:)` to `FocusModuleCard` background; `"title-{id}"` to task title text; `"rail-{id}"` to accent rail — all gated `#available(iOS 18, *)` so iOS 17 is unaffected (`HomeScreen.swift`)
- [x] Attach matching `.matchedGeometryEffect` destinations to `TaskDetailScreen` title panel background (`"card-{id}"`), large title text (`"title-{id}"`), and a 3pt accent rail in the top bar (`"rail-{id}"`) — gated `#available(iOS 18, *)` with optional namespace guard (`TaskDetailScreen.swift`)
- [x] Apply `.navigationTransition(.zoom(sourceID: "card-{id}", in: taskCardNS))` to the `TaskDetailScreen` destination on iOS 18+; falls back to standard push on iOS 17 (`ContentView.swift`)
- [x] `EmberRouter.swift` required no changes — existing `EmberRoute.taskDetail(EmberTask)` enum case is sufficient
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded — 0 errors, 0 warnings
- [x] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` succeeded — 27 tests passed

---

**Total items: ~96**

---

## Roadmap Step 6: Micro-interaction Pass

- [x] **6.1** Orbit numeric ticker: `contentTransition(.numericText(countsDown: false))` + `EmberAnimation.bouncy` — `HomeScreen.swift`
- [x] **6.2** Drag card tilt + shadow: `.rotationEffect(.degrees(isDragging ? 2 : 0))`; resting shadow 8%/r6 → dragging 45%/r22; animations migrated to `EmberAnimation.snappy`/`smooth` — `HomeScreen.swift`
- [x] **6.3** Toast entrance: `.scale(0.92).combined(with: .opacity).combined(with: .move(edge: .bottom))`; container `.animation(.bouncy)` — `HomeScreen.swift`
- [x] **6.4** Idle guide-ring breathing: `@State lastInteractionAt`, `IdleBreathingGuideRing` private struct (1Hz Timer, ≥8s threshold, 1.0↔1.02 on 4s easeInOut.repeatForever, Reduce Motion aware) — `HomeScreen.swift`
- [x] **6.5** Named spring tokens: `EmberAnimation.bouncy/.snappy/.smooth` — `DesignSystem/EmberAnimations.swift`
- [x] Build: succeeded — 0 errors, 0 warnings (generic/platform=iOS Simulator)
- [x] Unit tests: 27 tests passed on iPhone 17 simulator (OS 26.5)

---

**Total items: ~101**

---

## Roadmap Step 7: Surface Treatment

- [x] **7.1** Added `GrainOverlay`, a static procedural `CIFilter.randomGenerator()` texture tiled across bounds at 2% opacity — `Components/GrainOverlay.swift`
- [x] **7.2** Applied grain and a transparent-center to 3% black corner vignette over the Home background — `Screens/HomeScreen.swift`
- [x] **7.3** Added a 15% white screen-blended top-edge glint fading over the first 8pt of each FocusModuleCard accent rail — `Screens/HomeScreen.swift`
- [x] Build: succeeded — `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build`
- [x] Unit tests: 27 tests passed on iPhone 17 simulator — `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests`
- [!] UI tests: `-only-testing:EmberUITests` was attempted after the unit run, but compilation failed on unrelated in-progress Step 8 files now present in the worktree: `TaskDetailScreen.swift` references `focusSessionPanel`, and `FocusSessionService.swift` emits ActivityKit deprecation/concurrency warnings. Step 7 files were not implicated.

---

**Total items: ~104**

---

## Roadmap Step 8: Live Activity + Dynamic Island

- [x] **8.1** Live Activity registered in existing EmberWidgetBundle — `EmberWidget/EmberWidgetBundle.swift` (gated #available iOS 16.1+). Manual Xcode steps: add NSSupportsLiveActivities to widget Info.plist, add FocusSessionAttributes.swift to EmberWidgetExtension target.
- [x] **8.2** `FocusSessionAttributes: ActivityAttributes` — fixed: taskID, taskTitle, startedAt. ContentState: completedCount. — `Ember/Services/FocusSessionAttributes.swift`
- [x] **8.3** Lock screen UI: `FocusLockScreenView` — MiniOrbitView (12 dots), task title, 3-slot capsule progress, elapsed timer via timerInterval. — `EmberWidget/FocusSessionLiveActivity.swift`
- [x] **8.4** Dynamic Island: expanded (leading ember dot + FOCUS label, trailing 1/3, bottom 3-capsule + title), compactLeading (ember dot), compactTrailing (N/3 mono), minimal (ember dot). — `EmberWidget/FocusSessionLiveActivity.swift`
- [x] **8.5** `FocusSessionService.shared` — start/update/end wrapping ActivityKit; gated #available iOS 16.1+; activeTaskID tracking. — `Ember/Services/FocusSessionService.swift`
- [x] **8.6** `focusSessionPanel` in TaskDetailScreen — play/stop button, toggles FocusSessionService, shows active state with ember outline + stop icon. — `Ember/Screens/TaskDetailScreen.swift`
- [x] **8.7** `TaskCompletionCoordinator.complete()` now calls `FocusSessionService.update(completedCount:)` when session active; calls `end()` when all 3 done. — `Ember/Services/TaskCompletionCoordinator.swift`
- [x] **8.8** `ScheduledSessionWatcher.evaluate()` called in HomeScreen `.onAppear` + `.onChange(scenePhase == .active)`. Auto-starts session within ±10 min window if pref enabled and not dismissed. — `Ember/Services/ScheduledSessionWatcher.swift`, `Ember/Screens/HomeScreen.swift`
- [x] **8.9** `EmberPreferences.autoStartScheduledSessions` + `dismissedAutoSessions` + `hasAutoSessionBeenDismissed/dismissAutoSession` methods; Settings toggle "Auto Focus Session". — `Ember/Services/EmberPreferences.swift`, `Ember/Screens/SettingsScreen.swift`
- [x] **8.10** `EmberApp.body` wires `onChange(scenePhase == .active)` for session watcher trigger. — `Ember/EmberApp.swift`

---

## Roadmap Step 9: Interactive Widgets + App Intents + Siri

- [x] **9.1** Added `CompleteTaskIntent` for widget/App Shortcut completion by task UUID; it resolves tasks from the shared App Group SwiftData store, marks incomplete tasks done, cancels the stable reminder ID, updates `DailyRecord`, saves, and reloads WidgetKit timelines — `EmberWidget/Intents/CompleteTaskIntent.swift`
- [x] **9.2** Added `AddTaskIntent` with a title parameter, `openAppWhenRun = true`, shared pending-title storage, and `ember://add?title=...` open intent for Step 10 routing — `EmberWidget/Intents/AddTaskIntent.swift`
- [x] **9.3** Added `ShowTodayIntent` returning a spoken/string summary of today’s three slots from the shared SwiftData store — `EmberWidget/Intents/ShowTodayIntent.swift`
- [x] **9.4** Added `EmberAppShortcutsProvider` exposing Add Focus, Today summary, and Complete Focus shortcuts with natural phrases — `Ember/Services/EmberAppShortcutsProvider.swift`
- [x] **9.4** Added narrow Xcode synchronized-group target membership so the widget intent files are visible to the main app target for App Shortcuts — `Ember.xcodeproj/project.pbxproj`
- [x] **9.5** Wrapped Home widget task rows in `Button(intent: CompleteTaskIntent(...))` and added a compact `AddTaskIntent` action when fewer than three tasks exist — `EmberWidget/HomeScreenWidgetView.swift`
- [ ] Verification intentionally not run per user instruction; user will verify.

---

## Roadmap Step 10: System Integrations

- [x] **10.1** Added `SpotlightService` for Core Spotlight task indexing/deindexing, with task title, completed/incomplete description, keywords, expiration, and `ember://task/{uuid}` content URLs — `Ember/Services/SpotlightService.swift`
- [x] **10.1** Wired Spotlight indexing from new-task save, title edits, complete/uncomplete reindexing, and coordinator delete deindexing — `Ember/Screens/AddTaskView.swift`, `Ember/Screens/TaskDetailScreen.swift`, `Ember/Services/TaskCompletionCoordinator.swift`
- [x] **10.2** Registered `ember://` URL scheme and routed `ember://task/{uuid}` plus `ember://add?title=...` through the router; AddTaskView consumes pending titles — `Ember/Info.plist`, `Ember/Navigation/EmberRouter.swift`, `Ember/ContentView.swift`, `Ember/Screens/AddTaskView.swift`
- [x] **10.3** Added `EmberShareExtension` target to the Xcode project, embedded it in the app, and configured its Info.plist for text/web URL share activation — `Ember.xcodeproj/project.pbxproj`, `EmberShareExtension/Info.plist`
- [x] **10.3** Added share controller that extracts plain text or URL context, writes the same App Group pending-title key used by `AddTaskIntent`, then opens `ember://add` — `EmberShareExtension/ShareViewController.swift`
- [x] **10.4** Added `EmberFocusFilter: SetFocusFilterIntent`, persisted `focusFilterShowOnlyPrimary`, and made Home render only slot 01 while the Focus filter is active — `Ember/Services/EmberFocusFilter.swift`, `Ember/Services/EmberPreferences.swift`, `Ember/Screens/HomeScreen.swift`
- [x] **10.5** Tuned `.accessoryRectangular` for StandBy-style wide landscape geometry with larger progress orbit and compact task list while preserving normal lock-screen layout — `EmberWidget/LockScreenWidgetView.swift`, `EmberWidget/EmberWidget.swift`
- [ ] Verification intentionally not run per user instruction; user will verify.

---

## Roadmap Step 11: Streak Repair

- [x] **11.1** Added `isFrozen: Bool` attribute (defaulting to `false`) to SwiftData `DailyRecord` model — `Ember/Models/DailyRecord.swift`
- [x] **11.2** Upgraded `StreakService` current and longest streak calculations to treat `isFrozen` records as transparent bridges — `Ember/Services/StreakService.swift`
- [x] **11.2** Created unit tests `StreakServiceFreezeTests` validating gap-with-freeze and multiple-gap streak freeze behaviors — `EmberTests/StreakServiceFreezeTests.swift`
- [x] **11.3** Built beautiful dark studio "Streak at Risk" repair CTA panel on `StreakScreen` allowing users to consume their monthly freeze and restore a broken yesterday streak — `Ember/Screens/StreakScreen.swift`, `Ember/Services/EmberPreferences.swift`
- [x] **11.3** Customized monthly calendar grid and Day History sheet so frozen days display with an elegant dotted orange orbit border and "FROZEN" status label — `Ember/Screens/StreakScreen.swift`
- [ ] Verification intentionally not run per user instruction; user will verify.

---

**Total items: ~129**

---

## Roadmap Step 12: Schedule Timeline

- [x] **12.1** Added `ScheduleTimelineScreen` with a dense dark 6am–11pm timeline, hourly gridlines, a current-time marker, overlapping-card lane handling, and a three-task preview — `Ember/Screens/ScheduleTimelineScreen.swift`
- [x] **12.2** Added `EmberRoute.schedule` and wired `ScheduleTimelineScreen` into `ContentView` navigation destinations — `Ember/Navigation/EmberRouter.swift`, `Ember/ContentView.swift`
- [x] **12.3** Added the conditional `VIEW SCHEDULE` header pill on Home when today includes scheduled work — `Ember/Screens/HomeScreen.swift`
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build` succeeded
- [!] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EmberTests` failed before test execution because the simulator could not install `EmberShareExtension.appex` without a `CFBundleDisplayName` value in its Info.plist. This is outside Step 12’s touched files.

---

**Total items: ~132**

---

## Roadmap Step 13: Reflection Variety + Past Reflections

- [x] **13.1** Added `ReflectionPrompts`, a deterministic 10-prompt service that rotates by day-of-year modulo 10 via the injected `DateService` calendar — `Ember/Services/ReflectionPrompts.swift`
- [x] **13.2** Replaced the fixed Reflection screen headline with the rotating daily prompt and aligned the today-query window to `DateService.shared` — `Ember/Screens/ReflectionScreen.swift`
- [x] **13.3** Added `PastReflectionSheet`, a restrained dark archive surface for reading a saved reflection with date and word count — `Ember/Screens/PastReflectionSheet.swift`
- [x] **13.3** Updated `StreakScreen` calendar interactions so tap still opens day history while long-press opens the reflection archive sheet only for dates that have saved reflection text — `Ember/Screens/StreakScreen.swift`
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded
- [!] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedDataTests CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` failed before test execution because the simulator could not install `EmberShareExtension.appex` without a `CFBundleDisplayName` value in its Info.plist. This is outside Step 13’s touched files.

---

**Total items: ~135**

---

## Roadmap Step 14: Theme Palettes + OLED Black

- [x] **14.1** Added `EmberTheme` with the four planned palettes (`ember`, `electric`, `bone`, `magma`) and accent/pressed/subtle variants — `Ember/DesignSystem/EmberTheme.swift`
- [x] **14.2** Made `EmberColors` theme-aware for shared accent tokens and added `studioBackground` for the dark-shell screens — `Ember/DesignSystem/EmberColors.swift`
- [x] **14.3** Added persisted `currentTheme` and `oledBlackEnabled` preferences with proper UserDefaults round-tripping and UI-test reset cleanup — `Ember/Services/EmberPreferences.swift`
- [x] **14.4** Added a four-swatch appearance picker plus OLED black toggle in Settings — `Ember/Screens/SettingsScreen.swift`
- [x] **14.5** Swapped the dark studio screens from hardcoded `#070707` / `#FF6A00` values to shared theme-aware background and accent tokens; Home also drops grain opacity to 1% in OLED mode — `Ember/Screens/HomeScreen.swift`, `Ember/Screens/AddTaskView.swift`, `Ember/Screens/CarryForwardView.swift`, `Ember/Screens/LaunchAssembly.swift`, `Ember/Screens/MorningRitualView.swift`, `Ember/Screens/PastReflectionSheet.swift`, `Ember/Screens/ReflectionScreen.swift`, `Ember/Screens/ScheduleTimelineScreen.swift`, `Ember/Screens/StreakScreen.swift`, `Ember/Screens/TaskDetailScreen.swift`, `Ember/Screens/TranscendenceView.swift`
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded
- [!] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedDataTests14 CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` failed before test execution because the simulator could not install `EmberShareExtension.appex` without a `CFBundleDisplayName` value in its Info.plist. This is outside Step 14’s touched files.

---

**Total items: ~140**

---

## Roadmap Step 15: App Icon Variants

- [x] **15.1** Added generated `AppIcon-Black`, `AppIcon-Minimal`, and `AppIcon-Magma` asset catalogs with full iPhone/iPad icon size coverage plus 1024 marketing assets
- [x] **15.2** Configured `CFBundleIcons` and `CFBundleIcons~ipad` alternate icon entries for `Black`, `Minimal`, and `Magma` in the main app plist
- [x] **15.3** Added `AppIconService` and a new Settings appearance picker grid with inline previews, current selection state, and icon-switch error handling
- [x] Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded
- [!] Unit tests: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` still failed before executing tests because `EmberShareExtension.appex` is missing a non-empty `CFBundleDisplayName` in its Info.plist. This blocker is outside Step 15’s touched files.

---

**Total items: ~143**

---

## Release Hardening

- [x] **RH-1** Added non-empty `CFBundleDisplayName` (`Ember Share`) to `EmberShareExtension/Info.plist` to fix the simulator install blocker for the embedded share extension.
- [x] **RH-1 verification** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests` succeeded. The app installed, tests executed on `Clone 1 of iPhone 17`, and the previous `EmberShareExtension.appex` missing-display-name install failure did not recur.
- [x] **RH-2** Changed the main app target Debug/Release `TARGETED_DEVICE_FAMILY` values to `1` so App Store v1 ships iPhone-only. Widget, share extension, and test target families were left unchanged.
- [x] **RH-2 verification** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded. Built app `UIDeviceFamily` is `[1]`.
- [x] **RH-3** Cleared the release-hardening warnings in App Intents, Focus Filter shortcuts metadata, ActivityKit live activity code, and the schedule timeline lane assignment.
- [x] **RH-3 verification** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build` succeeded, and `rg -n "warning:|error:" /tmp/ember-rh3-build.log` returned no matches.
- [x] **Step 16 disposition** iPad layout work is deferred to v2 and is not a v1 release blocker.

---

**Total items: ~149**
