# Deployment & Versioning Strategy

This document describes how the ShredMembers app is deployed and versioned across web, iOS and Android.

## Deployment Channels

| Channel | URL / Target | Trigger | Platform |
|---|---|---|---|
| Web App | https://web.shredmember.app (via `web-shredmembers.web.app`) | Push to `main` | Flutter Web |
| Landing Page | https://shredmember.app | Push to `main` | Static HTML |
| Billing | https://shredmember.app/billing | Push to `main` | Static HTML + Stripe |
| Android | Google Play Console | Git tag `v*.*.*` | Flutter Android |
| iOS | App Store Connect | Git tag `v*.*.*` | Flutter iOS |

## Branch Strategy

- `main` is the production branch.
- `feature/*` or `fix/*` branches are merged into `main` via pull requests.
- Every push to `main` deploys the web app and landing page automatically.
- Mobile releases are triggered by Git tags.

## Versioning

We use **Semantic Versioning** for the mobile apps:

```
MAJOR.MINOR.PATCH+BUILD
```

Example in `pubspec.yaml`:

```yaml
version: 1.2.0+15
```

- `1.2.0` is the user-visible version number.
- `+15` is the build number which must increase for every store upload.

### iOS and Android share the same version

Because Flutter uses a single codebase, iOS and Android always use the same `pubspec.yaml` version and build number. The pipeline builds both platforms from the same Git tag.

Only split versions in exceptional cases (e.g. an iOS-specific hotfix that cannot wait for the next shared release).

### Web app has no fixed public version

The web app is deployed continuously on every push to `main`. There is no separate user-visible version number. Users always receive the latest build.

## Release Workflow

1. Develop features and push to `main`.
2. Web and landing page are deployed automatically.
3. At the end of a sprint, decide whether the mobile apps are store-ready.
4. If yes, update `pubspec.yaml`:
   - Bump `MAJOR.MINOR.PATCH` for new features or bugfixes.
   - Increase `+BUILD` by 1.
5. Commit and push the version change.
6. Create and push a Git tag:

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

7. The CI/CD pipeline builds the Android App Bundle (AAB) and iOS archive from the same tag.
8. Upload the artifacts to Google Play Console and App Store Connect manually.

## Sprint-Based Releases

Sprints are a good boundary for mobile releases:

- During the sprint, every push goes to the web app immediately.
- At the end of the sprint, the mobile stores receive a new version (e.g. `v1.1.0`).
- Critical bugfixes after a store release become `v1.1.1`.

## CI/CD Pipeline

A GitHub Actions workflow can automate the following:

- On every push to `main`:
  - `flutter build web --release`
  - `firebase deploy --only hosting:web-shredmembers`
  - `firebase deploy --only hosting:shredmembers` (landing + billing)
- On every Git tag `v*.*.*`:
  - `flutter build appbundle --release` (Android)
  - `flutter build ios --release` (iOS, requires macOS runner)
  - Upload artifacts to the workflow run

Store submission itself (Google Play Console, App Store Connect) must still be done manually or via fastlane with appropriate credentials.

## Manual Fallback

If the pipeline is not ready, the manual commands are:

```bash
# Web app
flutter build web --release
firebase deploy --only hosting:web-shredmembers

# Landing page
firebase deploy --only hosting:shredmembers

# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```
