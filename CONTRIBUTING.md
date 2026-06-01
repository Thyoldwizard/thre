# Contributing

Thanks for helping improve thre. The project is a local-first SwiftUI iOS app, so contributions should preserve the calm three-task product model and the privacy baseline.

## Good First Contributions

- Documentation fixes.
- Accessibility labels, VoiceOver improvements, and Dynamic Type polish.
- Focused unit tests for services and date/streak behavior.
- UI test launch route improvements.
- Screenshot and visual QA documentation.
- Small widget or Live Activity reliability fixes.

## Development Workflow

1. Fork the repository and create a branch.
2. Keep changes focused and explain the user-facing impact.
3. Run the relevant checks before opening a PR:

```sh
git diff --check
plutil -lint Ember/Info.plist EmberShareExtension/Info.plist EmberWidget/Info.plist Ember/PrivacyInfo.xcprivacy Ember/Ember.entitlements EmberWidgetExtension.entitlements
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -quiet -project Ember.xcodeproj -scheme Ember -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/EmberDerivedData-OSS CODE_SIGNING_ALLOWED=NO build
```

4. Add or update tests when behavior changes.
5. Include screenshots for visible UI changes.

## Design Principles

- Preserve the three-task constraint.
- Keep the app local-first unless a roadmap issue explicitly proposes otherwise.
- Avoid fake integrations. If a surface looks connected to a third-party service, it should either work or clearly be removed.
- Prefer existing design-system tokens in `Ember/DesignSystem/`.
- Keep App Store/signing changes separate from feature work.

## Pull Request Expectations

PRs should include:

- What changed.
- Why it changed.
- How it was tested.
- Screenshots for UI changes.
- Any known limitations or follow-up work.
