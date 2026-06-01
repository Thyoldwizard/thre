# Roadmap

This roadmap tracks public, open-source work. App Store distribution is intentionally separated from normal feature contributions because it touches signing, hosted policies, and release operations.

## Near Term

- Harden CI once GitHub-hosted runners provide Xcode 26+ broadly.
- Add more unit coverage around reminders, carry-forward, and route seeding.
- Add accessibility labels and VoiceOver snapshots for primary flows.
- Run a Dynamic Type pass on onboarding, task detail, schedule, and settings.
- Expand documentation for widgets, Live Activities, and App Intents.
- Add screenshot capture instructions for every UI-test route.

## Good First Issues

- Improve README screenshot captions and alt text.
- Add tests for `ReflectionPrompts`.
- Add tests for `DateService` edge cases around daylight saving time.
- Document each UI-test route with expected screen state.
- Audit hard-coded colors outside `Ember/DesignSystem/`.

## Help Wanted

- Accessibility review from someone who uses VoiceOver regularly.
- Localization preparation and string extraction.
- Widget reliability testing on different families and simulator sizes.
- CI matrix tuning for Xcode 26+ runner availability.

## App Store Readiness

- Hosted privacy policy URL.
- Hosted support URL.
- Final App Store screenshots and preview video.
- Category, age rating, pricing, and availability decisions.
- Signing, archive, TestFlight, and upload workflow.
- Bundle identifier and App Group naming migration, if the project moves fully from `Ember` to `thre`.

## Non-Goals For Now

- Backend sync.
- Analytics SDKs.
- Third-party auth.
- Team/collaboration features.
- Expanding beyond the three-task daily model.
