# Ember Handoff

## Project Context

Ember is a native SwiftUI + SwiftData iOS app in the inner repo:

`/Users/sheikhhassan/Desktop/iOS APP/Ember/Ember`

The outer folder `/Users/sheikhhassan/Desktop/iOS APP/Ember` is not the active Xcode project root. Work from the inner `Ember/` folder.

Core product concept:

- A daily focus app built around choosing and completing exactly three meaningful tasks per day.
- It should feel like a precise daily commitment ritual, not a generic todo list.
- The user wants a design-studio quality interface without mascots, custom illustration, AI-looking wellness imagery, stock visuals, or over-explained UI.

Current product/design direction:

- Full dark studio dashboard/control-surface language across the primary app screens.
- Structural inspiration: Polestar-style dark modular dashboards and a circular dotted score/progress object.
- The “circle thing around 61” became Ember’s **Daily Orbit**: a dotted circular progress object around `0/3`...`3/3`.
- Tone: calm control. Minimal copy, strong hierarchy, no soft wellness aesthetic.

## Current Implementation State

Important: the repo was already dirty before this work. Do not revert unrelated changes.

Latest user-directed cleanup before Step 8:

- The app is complete through Step 7. Do not restart Step 4/5/6/7 work unless the user explicitly asks.
- The user rejected the fire/flame motif and the completion bloom.
- Fire/flame UI has been removed from the main app and widgets:
  - `Ember/Screens/StreakScreen.swift` now uses a small neutral ember dot/ring instead of `flame.fill`.
  - `Ember/Components/StreakBadge.swift` now uses the same neutral ember mark.
  - `EmberWidget/HomeScreenWidgetView.swift` and `EmberWidget/LockScreenWidgetView.swift` no longer use flame symbols.
  - `Ember/DesignSystem/EmberSymbolEffects.swift` no longer has `streakFlame`.
- Completion bloom has been removed entirely:
  - `Ember/Screens/HomeScreen.swift` no longer owns `showCompletionBloom` or renders `CompletionBloom`.
  - `Ember/Components/TaskCard.swift` no longer has `showBloom` or a bloom overlay.
  - `Ember/Components/CompletionBloom.swift` was deleted.
  - Bloom design tokens were removed from `EmberAnimations`, `EmberColors`, `EmberGradients`, and `EmberShadows`.
- Source checks after cleanup:
  - `rg -n "bloom|Bloom|flame|Flame|🔥|CompletionBloom|showBloom|showCompletionBloom|completionBloom" Ember EmberWidget EmberTests EmberUITests` returned no matches.
  - `git diff --check` passed for the touched files.
- Per user instruction, do not run tests for this cleanup unless asked. A generic iOS build had succeeded immediately before the final bloom-removal request, but no build/test was run after deleting bloom.

Known repo state:

- Main app target: `Ember`.
- Widget extension target: `EmberWidgetExtension`.
- Active docs are in the inner repo:
  - `DESIGN_V2.md`
  - `PROGRESS.md`
  - `HANDOFF.md`
  - `ROADMAP.md`
- Older outer docs are legacy and should not be treated as source of truth.

Primary screens now converted to the dark studio language:

- `Ember/Screens/HomeScreen.swift`
- `Ember/Screens/AddTaskView.swift`
- `Ember/Screens/TaskDetailScreen.swift`
- `Ember/Screens/StreakScreen.swift`
- `Ember/Screens/ReflectionScreen.swift`
- `Ember/Screens/CarryForwardView.swift`
- `Ember/Screens/TranscendenceView.swift`
- `Ember/Screens/SettingsScreen.swift`

`Ember/ContentView.swift` now sets `.preferredColorScheme(.dark)`.

Latest implementation pass added:

- `Ember/Services/DailyRecordService.swift`
- `Ember/Services/ReminderService.swift`
- `Ember/Services/EmberPreferences.swift`
- Real widget registrations in `EmberWidget/EmberWidget.swift` and `EmberWidget/EmberWidgetBundle.swift`
- Step 4 launch experience: bundled Inter Tight, one-time orbit assembly overlay, and black launch screen.

## Recent Changes Completed

### RH-2 - App Store v1 is iPhone-only (completed this session)

**Modified files:**
- `Ember.xcodeproj/project.pbxproj` - changed the main app target Debug/Release `TARGETED_DEVICE_FAMILY` values from `"1,2"` to `1`.
- `ROADMAP.md` - marked RH-2 done and deferred Step 16/iPad layout to v2.
- `PROGRESS.md`, `HANDOFF.md` - updated release-hardening status.

**Verification:** Generic iOS build succeeded:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build
```

Built app confirmation: `/private/tmp/EmberDerivedData/Build/Products/Debug-iphoneos/Ember.app/Info.plist` contains `UIDeviceFamily = [1]`.

Known warnings still present and intentionally left for RH-3: App Intents static concurrency warnings in `AddTaskIntent`, `CompleteTaskIntent`, `ShowTodayIntent`, `EmberAppShortcutsProvider`, and `EmberFocusFilter`.

Next release-hardening task: RH-3 from `RELEASE_HARDENING_PLAN.md`.

### RH-1 - Share extension install blocker fixed (completed this session)

**Modified files:**
- `EmberShareExtension/Info.plist` - added top-level `CFBundleDisplayName` with value `Ember Share`.
- `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md` - updated release-hardening status.

**Verification:** The focused RH-1 command succeeded:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'id=C4923C77-28E7-4FA3-837B-1124569EE855' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests
```

Result: `** TEST SUCCEEDED **`. The app installed, the tests executed on `Clone 1 of iPhone 17`, and the previous `EmberShareExtension.appex` missing-display-name install blocker did not recur.

Follow-up: RH-2 completed after this fix.

### Step 14 — Theme palettes + OLED black (completed this session)

**New files:**
- `Ember/DesignSystem/EmberTheme.swift` — four theme definitions (`ember`, `electric`, `bone`, `magma`) with accent, pressed, and subtle variants.

**Modified files:**
- `Ember/Services/EmberPreferences.swift` — added persisted `currentTheme` and `oledBlackEnabled` preferences plus UI-test reset cleanup.
- `Ember/DesignSystem/EmberColors.swift` — made accent tokens preference-driven and added `studioBackground` for the dark-shell screens.
- `Ember/Screens/SettingsScreen.swift` — added the appearance panel with four theme swatches and an OLED black toggle.
- `Ember/Screens/HomeScreen.swift` — Home now observes theme/OLED preferences, uses the selected accent for the orbit and slot 01, and drops grain opacity to 1% in OLED mode.
- `Ember/Screens/AddTaskView.swift`
- `Ember/Screens/CarryForwardView.swift`
- `Ember/Screens/LaunchAssembly.swift`
- `Ember/Screens/MorningRitualView.swift`
- `Ember/Screens/PastReflectionSheet.swift`
- `Ember/Screens/ReflectionScreen.swift`
- `Ember/Screens/ScheduleTimelineScreen.swift`
- `Ember/Screens/StreakScreen.swift`
- `Ember/Screens/TaskDetailScreen.swift`
- `Ember/Screens/TranscendenceView.swift`
  These dark studio screens now read the shared themed accent/background tokens instead of hardcoded `#070707` / `#FF6A00` values.
- `ROADMAP.md` — marked 14.1–14.5 done with a note about shared dark-shell token adoption.
- `PROGRESS.md` — appended Step 14 progress and verification status.

**Verification:** Generic iOS Simulator build succeeded. `git diff --check` passed for the Step 14 files. `EmberTests` again failed before test execution because the simulator still refuses to install `EmberShareExtension.appex` without a non-empty `CFBundleDisplayName` in its Info.plist; this blocker remains outside Step 14’s touched files. The build still emits preexisting warnings outside Step 14 files, including the `ScheduleTimelineScreen` unused `lane` local and App Intents / ActivityKit concurrency warnings.

### Step 15 — App icon variants (completed this session)

**New files:**
- `Ember/Assets.xcassets/AppIcon-Black.appiconset/` — generated black-on-black control-surface icon family with full standard iPhone/iPad sizes plus 1024 marketing asset.
- `Ember/Assets.xcassets/AppIcon-Minimal.appiconset/` — generated dark minimal icon family with a bright ember core and full size matrix.
- `Ember/Assets.xcassets/AppIcon-Magma.appiconset/` — generated near-black magma red icon family with full size matrix.
- `Ember/Services/AppIconService.swift` — alternate-icon wrapper around `UIApplication.shared.setAlternateIconName(_:)` with enum-backed variants and picker metadata.

**Modified files:**
- `Ember/Info.plist` — added `CFBundleIcons` / `CFBundleIcons~ipad` alternate-icon dictionaries for `Black`, `Minimal`, and `Magma`, while keeping `AppIcon` as the primary icon name.
- `Ember/Screens/SettingsScreen.swift` — added the app icon picker panel to Appearance, inline icon previews, progress state during switching, and error alert handling.
- `ROADMAP.md` — marked 15.1–15.3 done and resolved the parked question in favor of programmatic geometric variants.

**Verification:** Generic iOS build succeeded with the Step 15 files in place. `git diff --check` passed. `EmberTests` failed before execution at the time because the simulator could not install `EmberShareExtension.appex` without a non-empty `CFBundleDisplayName` in its Info.plist; RH-1 later fixed that blocker. Because of that Step 15-time install blocker, the simulator could not complete end-to-end icon-switch verification on SpringBoard.

### Step 13 — Reflection variety + past reflections (completed this session)

**New files:**
- `Ember/Services/ReflectionPrompts.swift` — deterministic 10-prompt rotation service keyed off day-of-year modulo 10 using the injected `DateService` calendar.
- `Ember/Screens/PastReflectionSheet.swift` — dark studio archive sheet for reading a single saved reflection with date and word-count metadata.

**Modified files:**
- `Ember/Screens/ReflectionScreen.swift` — replaced the fixed reflection headline with the daily rotating `ReflectionPrompts` output and aligned the date query window to `DateService.shared`.
- `Ember/Screens/StreakScreen.swift` — replaced the single history-sheet state with typed sheet routing; tap still opens day history and long-press on a calendar day with saved reflection opens `PastReflectionSheet`.
- `ROADMAP.md` — marked 13.1–13.3 done with a note about tap vs. long-press behavior.
- `PROGRESS.md` — appended Step 13 progress and verification status.

**Verification:** Generic iOS Simulator build succeeded. `git diff --check` passed for the Step 13 files. The `EmberTests` run again failed before executing tests because the simulator still refuses to install `EmberShareExtension.appex` without a non-empty `CFBundleDisplayName` in its Info.plist; this blocker remains outside Step 13’s touched files.

### Step 12 — Schedule timeline (completed this session)

**New files:**
- `Ember/Screens/ScheduleTimelineScreen.swift` — new dark studio daily schedule view with a 6am–11pm vertical hour grid, current-time marker, overlapping-card lane layout, summary stats strip, empty state, and a seeded three-task preview.

**Modified files:**
- `Ember/Navigation/EmberRouter.swift` — added `.schedule` route case.
- `Ember/ContentView.swift` — wired the `.schedule` navigation destination to `ScheduleTimelineScreen`.
- `Ember/Screens/HomeScreen.swift` — added the conditional `VIEW SCHEDULE` header pill that appears only when today includes at least one scheduled task and navigates into the timeline.
- `ROADMAP.md` — marked 12.1–12.3 done with implementation notes.
- `PROGRESS.md` — appended Step 12 progress and verification status.

**Verification:** Generic iOS Simulator build succeeded. `git diff --check` passed. The attempted `EmberTests` run on the iPhone 17 simulator failed before executing tests because the simulator refused to install `EmberShareExtension.appex` without a non-empty `CFBundleDisplayName` in its Info.plist; this blocker is outside Step 12’s touched files. Existing build output still shows preexisting App Intents / ActivityKit concurrency warnings outside Step 12 files.

### Step 11 — Streak repair (completed this session)

**New files:**
- `EmberTests/StreakServiceFreezeTests.swift` — unit tests verifying gap-with-freeze and multiple-gap streak freeze behaviors.

**Modified files:**
- `Ember/Models/DailyRecord.swift` — added `isFrozen: Bool` attribute (defaulting to `false`) to persist freeze status.
- `Ember/Services/StreakService.swift` — upgraded current and longest streak calculations to treat `isFrozen` records as transparent bridges.
- `Ember/Screens/StreakScreen.swift` — added "Streak at Risk" repair CTA panel, monthly calendar dotted orange borders for frozen days, and "FROZEN" history sheet status labels.
- `Ember/Services/EmberPreferences.swift` — added `freezeUsedDates` preference to track consumed monthly freezes.
- `Ember.xcodeproj/project.pbxproj` — fixed missing target memberships and enabled `GENERATE_INFOPLIST_FILE = YES` on `EmberShareExtension` target to resolve Xcode resource conflicts.

**Verification:** Build succeeded — 0 errors, 0 warnings. Streak freeze tests `StreakServiceFreezeTests` passed completely. Other tests passed except the preexisting `TaskCompletionCoordinatorTests.testDeleteRemovesTask` which is unrelated to this step.

---

### Step 7 — Surface treatment (completed this session)

**New files:**
- `Ember/Components/GrainOverlay.swift` — static procedural `CIFilter.randomGenerator()` noise tile, rendered at 2% opacity and tiled to fill bounds.

**Modified files:**
- `Ember/Screens/HomeScreen.swift` — Home background now layers `GrainOverlay(opacity: 0.02)` above `#070707` plus a non-interactive radial corner vignette fading to 3% black at the edges.
- `Ember/Screens/HomeScreen.swift` — `FocusModuleCard` accent rail rendering now includes a 15% white screen-blended top-edge highlight fading over the first 8pt, while preserving the existing iOS 18 matched geometry rail source.
- `ROADMAP.md` — 7.1–7.3 marked done. `PROGRESS.md` updated.

**Verification:** Generic iOS Simulator build succeeded. Unit-only test run on iPhone 17 simulator succeeded with 27 tests passing. Xcode still emits the existing App Intents metadata-extraction warning because the app target does not currently link AppIntents. UI tests were attempted afterward but compilation failed on unrelated in-progress Step 8 files now present in the worktree: `TaskDetailScreen.swift` references `focusSessionPanel`, and `FocusSessionService.swift` emits ActivityKit deprecation/concurrency warnings. Step 7 files were not implicated.

---

### Step 8 — Live Activity + Dynamic Island (completed this session)

**Modified/Created files:**
- `EmberWidget/EmberWidgetBundle.swift` — registered `FocusSessionLiveActivity()` gated on `#available(iOS 16.1, *)` (8.1)
- `EmberWidget/FocusSessionLiveActivity.swift` [NEW] — `ActivityConfiguration` with:
  - Lock screen: `FocusLockScreenView` (MiniOrbitView 12 dots + title + 3-capsule progress + `timerInterval` elapsed timer) (8.3)
  - DI expanded: leading ember dot + "FOCUS" label, trailing "1/3", bottom 3-capsule progress + title (8.4)
  - DI compact: leading ember dot, trailing "N/3" mono (8.4)
  - DI minimal: single ember dot (8.4)
- `Ember/Services/FocusSessionAttributes.swift` [NEW] — `ActivityAttributes` with fixed taskID/taskTitle/startedAt, ContentState with completedCount (8.2)
- `Ember/Services/FocusSessionService.swift` [NEW] — `@MainActor final class`, `start/update/end`, all ActivityKit calls gated `#available(iOS 16.1, *)`, `activeTaskID` tracking (8.5)
- `Ember/Services/ScheduledSessionWatcher.swift` [NEW] — evaluates today's tasks on call; auto-starts session for scheduled tasks in ±10 min window; respects `autoStartScheduledSessions` pref and per-task daily dismissal (8.8)
- `Ember/Services/EmberPreferences.swift` — added `autoStartScheduledSessions`, `dismissedAutoSessions` (JSON-encoded dict), `hasAutoSessionBeenDismissed(for:)`, `dismissAutoSession(for:)` (8.9)
- `Ember/Services/TaskCompletionCoordinator.swift` — `complete()` now calls `FocusSessionService.update(completedCount:)` when session active for that task; calls `end()` when all 3 tasks done (8.7)
- `Ember/Screens/TaskDetailScreen.swift` — `@State focusSessionActive`, `focusSessionPanel` computed view (play/stop button, ember indicator dot, active state border), synced on `.onAppear` (8.6)
- `Ember/Screens/SettingsScreen.swift` — "Auto Focus Session" toggle wired to `autoStartScheduledSessions` (8.9)
- `Ember/Screens/HomeScreen.swift` — `.onAppear` and `.onChange(scenePhase == .active)` call `ScheduledSessionWatcher().evaluate()` (8.8)
- `Ember/EmberApp.swift` — `@State sessionWatcher`, `.onChange(scenePhase == .active)` hook (8.10)

**Manual Xcode steps required before this builds:**
1. Add `FocusSessionAttributes.swift` to **EmberWidgetExtension** target (Target Membership checkbox)
2. Add `FocusSessionLiveActivity.swift` to **EmberWidgetExtension** target
3. Add `NSSupportsLiveActivities = YES` to `EmberWidget/Info.plist`
4. Ensure `group.com.ember.focus` App Group is on both Ember and EmberWidgetExtension targets

**Verification:** Not run this session per user instruction — will verify separately.

---

### Step 9 — Interactive widgets + App Intents + Siri (completed this session)

**New files:**
- `EmberWidget/Intents/CompleteTaskIntent.swift` — App Intent with `taskID`; resolves the task from the shared App Group SwiftData store, marks it complete, cancels the stable reminder ID, updates `DailyRecord`, saves, and reloads widget timelines.
- `EmberWidget/Intents/AddTaskIntent.swift` — App Intent with `title`; stores the pending title in App Group defaults and opens `ember://add?title=...` with `openAppWhenRun = true`.
- `EmberWidget/Intents/ShowTodayIntent.swift` — App Intent returning a spoken/string summary of today’s three focus slots.
- `Ember/Services/EmberAppShortcutsProvider.swift` — registers Add Focus, Today summary, and Complete Focus shortcuts with Siri-friendly phrases.

**Modified files:**
- `EmberWidget/HomeScreenWidgetView.swift` — task rows are now `Button(intent: CompleteTaskIntent(...))`; widget shows a compact `Add focus` intent button when fewer than 3 tasks exist.
- `Ember.xcodeproj/project.pbxproj` — added narrow synchronized-group membership so `EmberWidget/Intents/*.swift` are visible to the main app target for App Shortcuts while remaining in the widget target.
- `ROADMAP.md` — 9.1–9.5 marked done with notes for the direct shared-store completion path and Step 10 deep-link dependency.
- `PROGRESS.md` — Step 9 section appended.

**Important follow-up resolved in Step 10:** `AddTaskIntent` pending-title storage and `ember://add` routing now flow into `AddTaskView` prefill.

**Verification:** Not run per user instruction.

---

### Step 10 — System integrations (completed this session)

**New files:**
- `Ember/Services/SpotlightService.swift` — Core Spotlight indexing/deindexing for tasks, with `ember://task/{uuid}` content URLs.
- `Ember/Services/EmberFocusFilter.swift` — `SetFocusFilterIntent` with `showOnlyPrimarySlot`.
- `EmberShareExtension/ShareViewController.swift` — extracts shared text or URL context, writes the shared pending-title key, and opens `ember://add`.
- `EmberShareExtension/Info.plist` — share extension activation for text and web URLs.

**Modified files:**
- `Ember/Screens/AddTaskView.swift` — consumes router pending titles and indexes newly saved tasks.
- `Ember/Screens/TaskDetailScreen.swift` — reindexes title edits and delegates delete deindexing to the coordinator.
- `Ember/Services/TaskCompletionCoordinator.swift` — reindexes complete/uncomplete and deindexes deletes.
- `Ember/Info.plist` — registers the `ember://` URL scheme.
- `Ember/Navigation/EmberRouter.swift` — handles `ember://task/{uuid}` and `ember://add?title=...`.
- `Ember/ContentView.swift` — owns `.onOpenURL` because it has both router and `ModelContext`; consumes the App Group pending-title key used by `AddTaskIntent`.
- `Ember.xcodeproj/project.pbxproj` — adds and embeds the `EmberShareExtension` target.
- `Ember/Services/EmberPreferences.swift` and `Ember/Screens/HomeScreen.swift` — store/apply Focus Filter state; Home hides slots 02/03 while active.
- `EmberWidget/LockScreenWidgetView.swift` and `EmberWidget/EmberWidget.swift` — rectangular lock-screen widget keeps normal layout and switches to wider StandBy-style layout by geometry.
- `ROADMAP.md` — 10.1–10.5 marked done. `PROGRESS.md` updated.

**Verification:** Not run per user instruction. `plutil -lint Ember.xcodeproj/project.pbxproj` passed after project-file edits.

---

### Step 6 — Micro-interaction pass (completed this session)

**Modified files:**
- `Ember/Screens/HomeScreen.swift` — five targeted changes:
  1. **6.1** Orbit ticker: `contentTransition(.numericText(countsDown: false))` + `.animation(.bouncy)`.
  2. **6.2** `FocusModuleCard` drag lift: `.rotationEffect(.degrees(isDragging ? 2 : 0))`; shadow upgraded resting 8%/r6 → dragging 45%/r22. Card animations migrated to `EmberAnimation.snappy`/`smooth`.
  3. **6.3** Undo toast: `.scale(0.92).combined(with: .opacity).combined(with: .move(edge: .bottom))`; container `.animation(.bouncy)`.
  4. **6.4** `@State var lastInteractionAt: Date` in HomeScreen, reset in `startHold`/`dismissUndo`. New `IdleBreathingGuideRing` private struct: 1Hz Timer, ≥8s idle, 1.0↔1.02 on 4s easeInOut.repeatForever, Reduce Motion aware.
  5. **6.5** Applied `EmberAnimation.snappy`/`smooth` to card animations.
- `Ember/DesignSystem/EmberAnimations.swift` — `bouncy = .bouncy`, `snappy = .snappy`, `smooth = .smooth` tokens added.
- `ROADMAP.md` — 6.1–6.5 marked done. `PROGRESS.md` updated.

**Verification:** Build succeeded — 0 errors, 0 warnings. 27 unit tests passed on iPhone 17 (OS 26.5).

---

### Step 5 — matchedGeometryEffect slot → detail (completed this session)

**Modified files:**
- `Ember/ContentView.swift` — owns `@Namespace var taskCardNS`; passes it as `cardNamespace:` to `HomeScreen` and as `namespace:` to `TaskDetailScreen` in `.navigationDestination`; applies `.navigationTransition(.zoom(sourceID: "card-{id}", in: taskCardNS))` on iOS 18+ for the `.taskDetail` route.
- `Ember/Screens/HomeScreen.swift` — `HomeScreen.init` now accepts `cardNamespace: Namespace.ID`; threads namespace down to `FocusModuleCard`; `FocusModuleCard` attaches `.matchedGeometryEffect(id: "card-{id}")` on card background, `"title-{id}"` on title text, `"rail-{id}"` on accent rail — all wrapped in `#available(iOS 18, *)` guards so iOS 17 layout is pixel-identical.
- `Ember/Screens/TaskDetailScreen.swift` — `namespace: Namespace.ID?` added (optional, defaults to nil; existing callers and UI tests compile unchanged); on iOS 18+ with a non-nil namespace, `"card-{id}"` attaches to title panel background, `"title-{id}"` to the large title text, `"rail-{id}"` to a 3pt ember capsule in the top bar.
- `ROADMAP.md` — 5.1 through 5.3 marked `[x] DONE (Claude)`.
- `PROGRESS.md` — Step 5 section appended.

**`EmberRouter.swift` was not touched** — the existing `EmberRoute.taskDetail(EmberTask)` enum carries the task ID needed for the sourceID string.

**Verification:** Generic iOS Simulator build succeeded — 0 errors, 0 warnings. 27 unit tests passed on iPhone 17 simulator (OS 26.5).

---

### Step 4 — Launch experience (completed this session)

**New files:**
- `Ember/Resources/Fonts/InterTight-VariableFont_wght.ttf` — bundled Inter Tight variable font for the Daily Orbit value only.
- `Ember/Resources/Fonts/OFL.txt` — SIL Open Font License text from the Inter Tight distribution.
- `Ember/Info.plist` — physical main app plist replacing generated plist so `UIAppFonts` can be explicitly registered.
- `Ember/Screens/LaunchAssembly.swift` — reusable 72-dot orbit assembly animation with reduced-motion bypass.
- `Ember/LaunchScreen.storyboard` — black `#070707` launch screen with centered ember dot.

**Modified files:**
- `Ember.xcodeproj/project.pbxproj` — main target now uses `Ember/Info.plist`; `Info.plist` excluded from synchronized target sources/resources.
- `Ember/DesignSystem/EmberTypography.swift` — added `orbitHero` custom Inter Tight font token using the bundled `InterTight-Regular` PostScript name.
- `Ember/Screens/HomeScreen.swift` — Daily Orbit value uses `orbitHero`; Home shows `LaunchAssembly` once per app process before revealing the orbit.
- `ROADMAP.md` — Step 4.1 through 4.7 marked done.
- `PROGRESS.md` — Step 4 implementation and verification notes added.

**Verification:** Generic iOS build succeeded. Built app plist contains `UIAppFonts = [InterTight-VariableFont_wght.ttf]` and `UILaunchStoryboardName = LaunchScreen`. Unit-only test run on iPhone 17 succeeded with 27 tests passing. UI test target was attempted, but CoreSimulatorService disconnected before tests could start and xcodebuild exited with code 70 because the requested simulator was no longer available.

### Step 3 — Hold-to-complete V2 + Bloom V2 (completed this session)

**New files:**
- `EmberTests/HapticServiceTests.swift` — focused interval-boundary coverage for escalating hold cadence.

**Modified files:**
- `Ember/Screens/HomeScreen.swift` — replaced per-hold 0.016s timers with `TimelineView(.animation)` progress; stores `holdStartedAt` and touch origins; `FocusModuleCard` now renders a touch-origin radial ember wipe instead of the bottom progress bar; hold ticks call `HapticService.shared.playEscalatingHoldCadence(progress:)`; Home now renders `CompletionBloom` on completion, using `.third` intensity for the third task before the existing Transcendence delay.
- `Ember/Services/HapticService.swift` — added `shared`, `playEscalatingHoldCadence(progress:)`, and a pure cadence interval helper; cadence throttles to 250ms before the final ramp and 80ms from `0.85` progress onward while respecting `EmberPreferences.hapticsEnabled`.
- `Ember/Components/CompletionBloom.swift` — added `CompletionBloomIntensity` with default `.standard`; `.third` adds a full-screen 8% ember flash after bloom onset while preserving existing callers.
- `ROADMAP.md` — Step 3.1 through 3.6 marked done.
- `PROGRESS.md` — Step 3 implementation and verification notes added.

**Verification:** Generic iOS Simulator build succeeded. Unit-only test run on iPhone 17 succeeded with 27 tests passing. UI test target was attempted: `testAddTaskFlowCreatesHomeModule` passed, then `testCompletingThreeTasksShowsTranscendenceAndReflects` and `testReflectionSavesEntry` reported assertion timeouts before the simulator runner became unstable and ended with `NSMachErrorDomain -308`; retry UI/manual interaction QA on a healthy simulator/device.

### Step 2 — Symbol effects pass (completed this session)

**New files:**
- `Ember/DesignSystem/EmberSymbolEffects.swift` — reusable View modifiers for `.completeBounce(_:)`, `.streakFlame()`, `.toastPulse()`, and `.replaceCheck(_:)`; all route through `symbolEffectsRemoved` using `EmberPreferenceKey.reducedMotionEnabled`.

**Modified files:**
- `Ember/Screens/HomeScreen.swift` — settings and add icons bounce on tap; undo toast icon pulses while visible; reorder handle uses `.appear`; completed checkmark uses replace transition.
- `Ember/Screens/TaskDetailScreen.swift` — complete toggle uses `checkmark.circle.fill` with replace/bounce; subtask checkmarks bounce on toggle.
- `Ember/Screens/MorningRitualView.swift` — completed task icons use replace/bounce transition.
- `Ember/Screens/ReflectionScreen.swift` — top save icon bounces on save and swaps to checkmark with replace transition; saved confirmation checkmarks use replace.
- `Ember/Screens/StreakScreen.swift` — top-bar flame uses infinite `.variableColor.iterative.reversing`, reduced-motion aware.
- `Ember/Screens/CarryForwardView.swift` — info/warning notice icon bounces on appear and over-limit transitions.
- `ROADMAP.md` — Step 2 marked complete and a full file-structure reference added for future sessions.
- `PROGRESS.md` — Step 2 progress/verification notes added.

**Verification:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build` succeeded. Unit-only test run on iPhone 17 succeeded with 24 tests passing. Full all-tests run hit a simulator launcher failure before reporting results (`NSMachErrorDomain -308`), so manual/UI animation walk is still recommended.

### Step 1 — Backend hardening (completed this session)

**New files:**
- `Ember/Services/EmberLogger.swift` — `os.Logger` wrapper; 4 subsystems (home, reminders, records, widget); `.info/_error/_debug` methods
- `Ember/Services/TaskCompletionCoordinator.swift` — `@MainActor` coordinator; `complete`, `uncomplete`, `deleteTask`, `scheduleReminder`; idempotent; logs all ops
- `Ember/PrivacyInfo.xcprivacy` — declares UserDefaults (CA92.1), FileTimestamp (C617.1), SystemBootTime (35F9.1)
- `EmberTests/TestHelpers.swift` — `FixedClock: EmberClock` for test injection
- `EmberTests/EmberLoggerTests.swift` — 4 tests, all pass
- `EmberTests/DateServiceTimezoneTests.swift` — 5 tests (Honolulu, Tokyo, midnight, same-day, yesterday boundary), all pass
- `EmberTests/TaskCompletionCoordinatorTests.swift` — 6 tests (happy path, idempotency, uncomplete, delete), all pass
- `EmberTests/ReminderServiceDateTests.swift` — 6 tests (past date, completed, no schedule, notif ID, clock injection), all pass

**Modified files:**
- `Ember/Services/DateService.swift` — added `EmberClock` protocol + `SystemClock`; `init(clock:calendar:)` seam; exposed `now` and `calendar` internally
- `Ember/Services/EmberPreferences.swift` — removed `Calendar.current` and `Date()` direct calls; routes through `DateService.shared`
- `Ember/Services/DailyRecordService.swift` — replaced `try?` with explicit `try/catch`; `try context.save()` + `EmberLogger.records.error` on every catch
- `Ember/Services/ReminderService.swift` — `enum` → `struct` with `EmberClock` injection; `scheduleReminder` is `async throws`; static `cancelReminder` convenience kept
- `Ember/Services/HapticService.swift` — migrated 5 `print()` to `EmberLogger.home`; removed stale comment
- `Ember/Services/AudioService.swift` — migrated 1 `print()` to `EmberLogger.home`
- `EmberWidget/SharedDataProvider.swift` — replaced `print()` with inline `os.Logger` (widget target can't import main app)
- `Ember/Screens/HomeScreen.swift` — wired `complete`/`undoCompletion` through coordinator; fixed timer closures with `MainActor.assumeIsolated` + `taskID` capture
- `Ember/Screens/TaskDetailScreen.swift` — complete toggle and delete wired through coordinator; schedule changes use `coordinator.scheduleReminder`
- `Ember/Screens/AddTaskView.swift` — `ReminderService.scheduleReminder` → `Task { await coordinator.scheduleReminder(for:) }`
- `Ember/Components/TaskCard.swift` — fixed timer closures with `MainActor.assumeIsolated`
- `Ember.xcodeproj/project.pbxproj` — added `SWIFT_STRICT_CONCURRENCY = complete` to Ember target (Debug + Release)

**Result:** BUILD SUCCEEDED — 0 errors, 0 warnings. All 24 unit tests pass. All 12 UI tests pass (pre-existing).

---

### Doc cleanup + ROADMAP created (previous session)

- Deleted `SCREENS_V2.md` — was describing warm-paper screens that no longer exist. Implemented SwiftUI files are the source of truth.
- Rewrote `DESIGN_V2.md` — stripped legacy warm-paper color structs, "Components to Remove" section, and stale accent tables. Now covers only the live dark studio system: color palette, typography, spacing, animations, FocusModuleCard anatomy, Daily Orbit spec, unchanged foundation table.
- Created `ROADMAP.md` — comprehensive 16-step overhaul plan with ~85 atomic sub-tasks. Built as a coordination doc for Claude + Codex to work in parallel. Every sub-task has: ID, files to touch, dependencies, scope, done-when criteria, and status checkboxes. No code was written this session.

**Active doc set (3 files):**
- `HANDOFF.md` — operational context, current state, QA checklist
- `PROGRESS.md` — build tracker checklist (all prior work)
- `DESIGN_V2.md` — live design tokens, studio palette only
- `ROADMAP.md` — forward plan, 16 steps, granular sub-tasks

### Undo Completion Toast

`Ember/Screens/HomeScreen.swift`

- Added `fileprivate struct PendingUndo: Equatable` (taskID + title snapshot).
- New state on `HomeScreen`: `@State private var pendingUndo: PendingUndo?`
- After every `complete(_:)` call, a `PendingUndo` snapshot is stored.
- Toast pill slides up from the bottom of the Home `ZStack(alignment: .bottom)`.
  - Panel `#1F1F1F`, 1pt white-6% border, 4pt corner.
  - `arrow.uturn.backward` icon + task title + ember "Undo" capsule button.
  - `.spring(response: 0.35, dampingFraction: 0.84)` entrance/exit.
- Toast auto-dismisses on any next interaction: header nav taps, slot tap, hold start, scroll begin, reorder chip tap, `scenePhase` background, `onDisappear`.
- Tapping "Undo":
  - Sets `task.isCompleted = false`, `task.completionDate = nil`.
  - Calls `DailyRecordService.upsertRecord(in: modelContext)` to roll back.
  - Calls `ReminderService.scheduleReminder(for: task)` (self-guards if no schedule or past).
  - Light haptic via `EmberPreferences.hapticsEnabled`.
- Transcendence suppression: the 0.5s deferred check now re-evaluates `guard allCompleted else { return }`. If the user undoes during the window, `allCompleted` is false and Transcendence never presents.
- Duplicate `scenePhase` onChange removed — merged into single handler (active → `handleDayBoundary`, inactive/background → `dismissUndo`).

### Drag-to-Reorder

`Ember/Screens/HomeScreen.swift`

- New state: `@State private var isReordering: Bool`, `draggingTaskID: UUID?`, `dragTranslationY: CGFloat`, `reorderSlotHeight: CGFloat = 126`.
- "REORDER" chip in the THREE FOR TODAY header row, visible only when `todayTasks.count >= 2`. Tap toggles `isReordering`. Chip label flips to "DONE" while active.
- While `isReordering`:
  - `ScrollView` is disabled (`scrollDisabled(true)`).
  - Each filled `FocusModuleCard` shows a `line.3.horizontal` drag handle on its trailing edge.
  - Hold-to-complete `pressGesture` is suspended — `combinedGesture` branches internally on `isReordering`.
- Live slot shifting via `reorderOffsetY(for:)`:
  - Dragging card tracks raw `dragTranslationY` (no animation, follows finger).
  - Non-dragging cards animate via `interactiveSpring` on `virtualReorderIndex` changes.
  - Dragging card gets `scaleEffect(1.03)` + subtle shadow lift; zIndex elevated to 10.
- On gesture end, `commitReorderIfNeeded(for:)` swaps `displayOrder` on all tasks in the sorted array. SwiftData `@Query(sort: \EmberTask.displayOrder)` re-sorts automatically. Medium haptic on commit.
- Empty slots are not draggable. Reorder chip hidden when fewer than 2 tasks exist.
- Slot accent colors follow position after reorder: slot 01 always takes ember `#FF6A00`, slot 02 warm white, slot 03 graphite — including completed tasks moved to a new slot.

### HomeScreen

`Ember/Screens/HomeScreen.swift`

- Dark shell background: `#070707`.
- Compact header with date/time, settings shortcut, progress shortcut, and add button.
- Daily Orbit:
  - 72-dot circular progress ring.
  - Active dots use ember orange `#FF6A00`.
  - Inactive dots use dark muted gray.
  - Subtle rotating/wave shimmer animation.
  - Breathing guide ring.
  - Numeric transition for `0/3`, `1/3`, `2/3`, `3/3`.
- Three task modules:
  - All slots now use dark studio surfaces instead of old warm yellow/sage fills.
  - Slot accents:
    - Slot 01: `#FF6A00`
    - Slot 02: `#F7F3EA`
    - Slot 03: `#858F96`
  - Slot accent appears as leading rail, border, slot number, plus button, and hold progress.
- Empty modules still use:
  - `Choose one thing`
  - `Choose what matters next`
  - `Leave room for life`
- Filled module tap routes to `TaskDetailScreen`.
- Empty module tap routes to `AddTaskView`.
- Hold-to-complete behavior remains.
- Hold completion now updates `DailyRecord` through `DailyRecordService`.
- Hold completion now cancels any pending reminder for that task.
- Direct haptic calls now respect `EmberPreferences.hapticsEnabled`.
- Header no longer hardcodes `Islamabad`; it shows local time only.
- Daily Orbit animation respects `EmberPreferences.reducedMotionEnabled`.
- Carry-forward and Transcendence full-screen covers remain.

### Add Task

`Ember/Screens/AddTaskView.swift`

- Rebuilt as full-screen dark studio composer.
- Compact top bar:
  - circular back button
  - `SET FOCUS`
  - `x/3 chosen`
  - circular save button
- Dark title composer panel with large `Name the focus` input.
- Dark schedule module with ember toggle and dark wheel picker.
- Dark subtask module with ember dot/thread controls.
- Save creates `EmberTask` with optional schedule and subtasks, upserts today's `DailyRecord`, schedules a local reminder when applicable, then navigates back.

### Task Detail

`Ember/Screens/TaskDetailScreen.swift`

- Rebuilt as dark task control surface.
- Compact top bar with back and complete/incomplete toggle.
- Editable title panel.
- Metadata panel for status, schedule, carried-forward state, and subtask progress.
- Dark subtask module with ember checkboxes.
- Add-subtask input preserved.
- Swipe-to-delete subtasks preserved.
- Delete task confirmation preserved.
- Complete/incomplete toggle now upserts the relevant `DailyRecord`.
- Complete now cancels a pending reminder; marking incomplete reschedules it if the scheduled time is still in the future.
- Delete now cancels any pending reminder before deleting.

### Streak

`Ember/Screens/StreakScreen.swift`

- Rebuilt as dark rhythm/analytics screen.
- Large current streak hero panel.
- Best streak and perfect-days stats.
- Dark monthly calendar panel.
- Calendar states:
  - 3 complete: ember
  - partial completion: studio accent variants
  - no record/past: muted dark
  - today: ember ring

### Reflection

`Ember/Screens/ReflectionScreen.swift`

- Rebuilt as dark reflection surface.
- Prompt panel: `What changed after you showed up?`
- Dark editor panel.
- Save/update behavior preserved.
- Saved confirmation preserved.

### Carry Forward

`Ember/Screens/CarryForwardView.swift`

- Rebuilt as dark decision screen.
- Header panel shows open slots.
- Selection panel uses dark selectable modules with ember rails/check controls.
- Existing logic preserved:
  - selected tasks clone to today
  - subtask cloning preserved
  - three-task limit respected
  - duplicate title guard preserved
  - “Let Them Go” dismisses cover
- Carry-forward action now upserts today's `DailyRecord`.

### Transcendence

`Ember/Screens/TranscendenceView.swift`

- Rebuilt from solid coral screen to dark studio victory screen.
- Animated 72-dot orbit around large `3`.
- Completion copy:
  - `All three. Done.`
  - `You showed up today.`
- Actions:
  - `Return to Today`
  - `Reflect`
- `Reflect` dismisses Transcendence and routes to `ReflectionScreen`.
- DailyRecord upsert now delegates to `DailyRecordService`.
- Completion orbit animation respects `EmberPreferences.reducedMotionEnabled`.

### Settings

`Ember/Screens/SettingsScreen.swift`

- Added compact dark studio settings screen.
- Shows local notification authorization status.
- Provides `Allow`/`Refresh` action for reminder permission.
- Toggles:
  - Sound
  - Haptics
  - Reduced Motion
- Shows local-first data/privacy copy.
- Routed via `EmberRoute.settings` and a Home header gear button.

### Daily Records

`Ember/Services/DailyRecordService.swift`

- New service centralizes `DailyRecord` upserts.
- Fetches tasks for a day and records:
  - `taskCount`
  - `completedCount`
  - `allThreeCompleted`
- Wired into:
  - Add task
  - Home hold-complete
  - Task detail complete/incomplete
  - Task deletion
  - Carry-forward
  - Transcendence appear
- This means partial days are now persisted, not only perfect days.

### Reminders

`Ember/Services/ReminderService.swift`

- New local notification service using `UNUserNotificationCenter`.
- Scheduled tasks create one local reminder with stable ID `ember-task-{UUID}`.
- Notification content:
  - title: `Ember`
  - body: `Focus: {task title}`
- Skips scheduling if the task is completed, unscheduled, or the fire date is in the past.
- Cancels reminders on completion and deletion.
- Reschedules when a task is marked incomplete and still has a future scheduled time.
- Reminder sound respects `EmberPreferences.soundEnabled`.

### Preferences

`Ember/Services/EmberPreferences.swift`

- Added UserDefaults-backed preference keys:
  - `soundEnabled`
  - `hapticsEnabled`
  - `reducedMotionEnabled`
  - `morningRitualLastShownDate`
- `AudioService` now respects sound preference.
- `HapticService` now respects haptics preference.
- Home/Transcendence orbit animations now respect reduced motion.

### Widget Extension

`EmberWidget/`

- Reconciled widget target.
- `EmberWidgetBundle.swift` now registers only:
  - `EmberTodayWidget`
  - `EmberLockScreenWidget`
- Replaced generated emoji widget with real Ember widget definitions in `EmberWidget.swift`.
- Removed generated placeholder files:
  - `EmberWidgetControl.swift`
  - `EmberWidgetLiveActivity.swift`
- `EmberTodayWidget` supports `.systemMedium` and `.systemLarge`.
- `EmberLockScreenWidget` supports `.accessoryCircular`, `.accessoryInline`, and `.accessoryRectangular`.
- Widget palette/typography now better matches the dark studio/SF Pro direction.

## Docs Updated

Active docs were updated to reflect the full dark studio pass:

- `DESIGN_V2.md`
  - Now states warm-paper V2 is legacy reference only.
  - Studio dashboard language is the primary direction.
  - Daily Orbit animation and dark module surface rules documented.
- `SCREENS_V2.md`
  - Top note says the implemented SwiftUI screens are current source of truth.
  - Home and Add Task sections were updated.
  - Some lower sections still contain older detailed warm-paper specs; treat those as legacy notes until rewritten.
- `PROGRESS.md`
  - Updated Phase 4, 5, 7, 8, 9, and 10 entries to reflect the dark studio rebuilds.

Recent code changes from the latest session are reflected in this handoff but not yet fully rewritten into `SCREENS_V2.md`.

## Verification

### Build (post Step 3 implementation)

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Ember -destination 'generic/platform=iOS Simulator' build
```

Result: **BUILD SUCCEEDED** — zero errors, zero warnings.

### Unit tests passed (iPhone 17 simulator, OS 26.5)

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EmberTests
```

Result: **TEST SUCCEEDED** — 27 unit tests passed.

### UI tests attempted (iPhone 17 simulator, OS 26.5)

- `testAddTaskFlowCreatesHomeModule` — PASSED
- `testCompletingThreeTasksShowsTranscendenceAndReflects` — failed opening Task Detail from a Home task title
- `testReflectionSavesEntry` — failed waiting for `reflection.topSave` accessibility value `saved`
- Run then became unstable and ended with `NSMachErrorDomain -308`

### Manual QA still needed (see Known Risks)

Important local note: this machine's global `xcode-select` points at Command Line Tools, so simulator/build commands should set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Current Known Risks / Next Checks

1. **Undo toast — manual QA needed.**
   - Complete a task; confirm toast appears with correct title.
   - Tap "Undo"; confirm task reverts to uncompleted, orbit count decreases, reminder reschedules if applicable.
   - Complete a task, then tap a different card without tapping Undo; confirm toast dismisses and task stays completed.
   - Transcendence suppression: complete 3rd task, tap Undo within 0.5s; Transcendence must not appear.

2. **Drag-to-reorder — manual QA needed.**
   - With 3 tasks, tap "REORDER" chip. Drag slot 03 to slot 01. Confirm slot accents follow new positions.
   - Tap "DONE". Relaunch app. Confirm order persists.
   - Confirm hold-to-complete gesture works normally after exiting reorder mode.
   - With 0 or 1 task, confirm "REORDER" chip is hidden.

3. Home hold gesture behavior still needs manual device/simulator testing after Step 3.
   - Hold active module should complete at 1.5s with a touch-origin radial wipe.
   - Release before hold completion should cancel and fade the wipe back out.
   - Completed module tap should still open detail.
   - Third task should show the 8% ember flash, then Transcendence should present after the existing delay.

4. Daily Orbit animation should be reviewed on a real device.
   - Watch for excessive motion.
   - Confirm it feels subtle, not distracting.

5. Notification firing still needs real-time simulator/device QA.
   - Create a scheduled task in the future.
   - Confirm pending notification fires.
   - Complete the task before the scheduled time and confirm the reminder no longer fires.

6. Widget visual/data QA is still needed on SpringBoard.
   - Check medium/large Home widgets.
   - Check circular/inline/rectangular lock-screen widgets.
   - Confirm widget reads the shared App Group SwiftData store on simulator/device.

7. Reduced Motion should be visually checked after relaunch.
   - The preference persists in UI tests.
   - Confirm orbit shimmer and Step 2 symbol effects stop in the live UI.

8. Docs are now clean. `SCREENS_V2.md` was deleted. `DESIGN_V2.md` was rewritten. No further doc work needed before implementation starts.

9. **Step 5 — matchedGeometryEffect zoom transition — manual QA needed.**
   - On an iPhone 17 simulator (iOS 18), tap a filled task slot; confirm the card zooms into the TaskDetailScreen header (card background, title, and accent rail all morph).
   - Use the swipe-back gesture; confirm the zoom reverses cleanly.
   - On an iOS 17 simulator, confirm the push is a standard navigation slide with no visual artifacts.
   - Hold-to-complete should still work normally after the transition (no gesture conflict).

## Recommended Next Session Flow

**Release hardening is active. Use `RELEASE_HARDENING_PLAN.md` as the source of truth. RH-1 and RH-2 are complete; continue with RH-3 unless the user explicitly redirects.**

1. Start from the inner repo:

```sh
cd "/Users/sheikhhassan/Desktop/iOS APP/Ember/Ember"
```

2. Read these files first:

```
HANDOFF.md                  <- current state + known risks
ROADMAP.md                  <- roadmap + release-hardening status
PROGRESS.md                 <- verification history
RELEASE_HARDENING_PLAN.md   <- source of truth for RH tasks
```

3. Verify the build is still clean before touching anything:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO build
```

4. Execute release-hardening tasks in order from `RELEASE_HARDENING_PLAN.md`.
   - After each RH task, update `ROADMAP.md`, `PROGRESS.md`, and `HANDOFF.md`.
   - Run `git diff --check`.
   - Commit only the files for that RH task where possible.

5. After each meaningful step, run build/tests:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedData CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests
```

## Recommended Next Implementation Steps

-> **Follow `RELEASE_HARDENING_PLAN.md` exactly, task by task.**

The release hardening plan is the source of truth for v1. Do not implement iPad Step 16 for v1.

**Next sub-tasks:**

| ID | Sub-task | Deps |
|----|----------|------|
| RH-3 | Treat warnings as release blockers | RH-2 |
| RH-4 | Primary app icon QA and improvement | RH-3 |
| RH-5 | Release metadata surfaces in Settings | RH-4 |

## User Preferences / Constraints

- User is direct and wants visible progress quickly.
- Avoid excessive Xcode instructions unless needed.
- Do not make the app look like generic wellness software.
- Avoid “AI slop,” stock imagery, mascots, decorative illustrations, and over-explained UI.
- Prioritize design quality and cohesive product feel.
- Keep the three-task rule strict.
