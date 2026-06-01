# Security Policy

## Supported Versions

The `main` branch is the supported development branch.

## Reporting A Vulnerability

Please do not open a public issue for a vulnerability. Email the maintainer with:

- A clear description of the issue.
- Reproduction steps.
- Impact and affected files or features.
- Any suggested fix, if available.

Maintainer contact: `smhassan223@gmail.com`

## Security And Privacy Baseline

thre is intended to be local-first:

- No analytics SDKs.
- No backend sync.
- No third-party auth.
- No crash-reporting SDK.
- No tracking.

Any PR that adds networking, analytics, auth, crash reporting, remote config, sync, or third-party SDKs must update:

- `README.md`
- `Ember/PrivacyInfo.xcprivacy`
- App permissions and privacy documentation
- Relevant tests
