# thre

thre is a native iOS focus app built around one constraint: choose the three tasks that matter today, work through them deliberately, and close the day with rhythm and reflection.

The Xcode project is still named `Ember` internally, but the portfolio-facing app name is `thre`.

## Status

This project is complete for portfolio use. It includes a polished iPhone-first SwiftUI app, seeded screenshot routes, widgets, Live Activity support, reminders, focus-filter plumbing, share extension support, Spotlight indexing, tests, and a privacy manifest.

App Store/TestFlight work is intentionally parked for later. Before public shipping, the app still needs final signing/archive/upload decisions, hosted privacy and support URLs, App Store metadata decisions, and a real review of any account/auth claims. The Apple and Google sign-in buttons in onboarding are portfolio UI only; they complete onboarding locally and do not connect to auth or a backend.

## Highlights

- Three-task daily focus model with fixed slots.
- First-run onboarding with promise, slot explanation, rhythm payoff, and optional personalization screens.
- Dark studio visual system with warm ember accent, tactile cards, animated orbit progress, and subtle route transitions.
- Add task, task detail, subtasks, schedule timeline, carry-forward, reflection, rhythm/streak, transcendence, and settings flows.
- SwiftData persistence with App Group storage fallback for widget access.
- Home Screen widgets, Lock Screen/StandBy widgets, and Live Activity focus sessions.
- Reminder scheduling, haptics, local preferences, app shortcuts/intents, share extension, and Spotlight indexing.
- UI-test launch routes for stable screenshots and demo capture.

## Tech Stack

- SwiftUI
- SwiftData
- WidgetKit
- ActivityKit
- App Intents
- UserNotifications
- CoreSpotlight
- XCTest

## Project Layout

- `Ember/` - main iOS app target.
- `Ember/DesignSystem/` - colors, spacing, typography, gradients, shadows, animation, and transition tokens.
- `Ember/Screens/` - feature screens and presentation flows.
- `Ember/Components/` - reusable SwiftUI building blocks.
- `Ember/Models/` - SwiftData models.
- `Ember/Services/` - persistence helpers, reminders, streaks, widgets/session support, logging, haptics, preferences, shortcuts, and indexing.
- `Ember/Navigation/` - route handling and deep links.
- `EmberWidget/` - widget and Live Activity extension code.
- `EmberShareExtension/` - share extension.
- `EmberTests/` and `EmberUITests/` - unit and UI test coverage.
- `ThreScreenshots/iPhone-17/` - current portfolio screenshot set.

## Current Metadata

- Display name: `thre`
- Internal project name: `Ember`
- Bundle identifier: `com.ember.Ember`
- Marketing version: `1.0`
- Build number: `1`
- Deployment target: iOS `26.2`
- Device family: iPhone for the main app target
- URL scheme: `ember://`
- App Group: `group.com.ember.focus`
- Privacy manifest: `Ember/PrivacyInfo.xcprivacy`

## Screenshots And Demo

Current screenshot set:

- `ThreScreenshots/iPhone-17/00-onboarding-promise.png`
- `ThreScreenshots/iPhone-17/01-onboarding-slots.png`
- `ThreScreenshots/iPhone-17/02-onboarding-rhythm.png`
- `ThreScreenshots/iPhone-17/03-onboarding-account.png`
- `ThreScreenshots/iPhone-17/04-home.png`
- `ThreScreenshots/iPhone-17/05-morning-ritual.png`
- `ThreScreenshots/iPhone-17/08-schedule.png`
- `ThreScreenshots/iPhone-17/09-rhythm.png`
- `ThreScreenshots/iPhone-17/10-reflection.png`
- `ThreScreenshots/iPhone-17/11-carry-forward.png`
- `ThreScreenshots/iPhone-17/12-transcendence.png`
- `ThreScreenshots/iPhone-17/13-settings.png`

## Verification

Set `DEVELOPER_DIR` explicitly because some machines may have `xcode-select` pointed at Command Line Tools instead of Xcode.

Build:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -quiet -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData-Portfolio CODE_SIGNING_ALLOWED=NO build
```

Build for testing:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -quiet build-for-testing -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData-Portfolio CODE_SIGNING_ALLOWED=NO
```

Focused unit tests, when the simulator launcher is stable:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -quiet test -project Ember.xcodeproj -scheme Ember -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/EmberDerivedData-Portfolio CODE_SIGNING_ALLOWED=NO -only-testing:EmberTests
```

Diff and plist checks:

```sh
git diff --check
plutil -lint Ember/Info.plist EmberShareExtension/Info.plist EmberWidget/Info.plist Ember/PrivacyInfo.xcprivacy
```

Full simulator test runs may fail before tests execute with `NSMachErrorDomain -308` from `IDELaunchiPhoneSimulatorLauncher`. Treat that as simulator launcher instability unless there is an app crash log or a failing assertion.

## UI-Test Launch Routes

Use simulator environment variables for stable screenshots and demo routes:

```sh
SIMCTL_CHILD_EMBER_UI_TESTING=1
SIMCTL_CHILD_EMBER_DISABLE_MORNING_RITUAL=1
SIMCTL_CHILD_EMBER_UI_TESTING_ROUTE=homeSeeded
```

Supported `EMBER_UI_TESTING_ROUTE` values:

- `homeSeeded`
- `morningRitual`
- `addTask`
- `taskDetail`
- `schedule`
- `streak`
- `reflection`
- `carryForward`
- `transcendence`
- `settings`

Optional onboarding page override:

```sh
SIMCTL_CHILD_EMBER_UI_TESTING_ONBOARDING_PAGE=account
```

Supported onboarding pages:

- `choose`
- `rhythm`
- `account`
- `daily`

Optional seeded titles:

```sh
SIMCTL_CHILD_EMBER_UI_TESTING_ADD_TASK_TITLE="Shape the launch slice"
SIMCTL_CHILD_EMBER_UI_TESTING_TASK_TITLE="Shape the launch slice"
```

## Privacy

`Ember/PrivacyInfo.xcprivacy` currently declares:

- No tracking.
- No collected data types.
- Accessed API reasons for UserDefaults, file timestamps, and system boot time.

Re-check the manifest before App Store submission if analytics, networking, crash reporting, sync, backend auth, or any third-party SDK is added.

## App Store Later

Before posting to the App Store, revisit:

- Final signing, archive, and upload flow.
- Hosted privacy policy URL.
- Hosted support URL.
- App Store category, age rating, pricing, and availability.
- Final screenshots and preview video.
- Final marketing copy, keywords, subtitle, and promotional text.
- Whether onboarding auth UI should be removed, relabeled, or connected to real auth.
- iPad support, if desired.

Suggested metadata draft:

- Name: `thre`
- Subtitle: `Choose the three that matter.`
- Promotional text: `Shape each day around three deliberate focuses, then close the loop with reflection and rhythm.`
- Short description: `thre is a calm daily focus app built around one constraint: choose three tasks, finish what matters, and see your rhythm over time.`
- Keywords: `focus, tasks, productivity, planner, habits, streak, routine, reminders, reflection`

## Contributors

- Sheikh Hassan - creator, product direction, design direction, and owner.
- OpenAI Codex - AI development collaborator for implementation, cleanup, documentation, and repository preparation.
