# Jabhouy

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Jabhouy is a Flutter app for small-shop operations. It helps a seller manage inventory, customer debt/loan records, customer data, and bank-notification-based income tracking from a single mobile-first interface.

## What the app does

The app is organized around a few core workflows:

- **Shop inventory**: create, edit, delete, search, and filter items by category.
- **Loan management**: track customer loans, payment status, dates, and customer associations.
- **Customer management**: maintain a reusable customer list for loan and shop flows.
- **Income tracking**: capture supported bank notifications on Android, parse income signals, and persist them locally with sync status.
- **Profile and session management**: sign in, sign up, sign out, and restore a previous session when possible.
- **App settings and diagnostics**: manage theme/language/device role and inspect income diagnostics logs when troubleshooting capture/sync behavior.

## Offline-first behavior

The app now uses an offline-first approach for the main operational flows:

- **Local database first**: shop items, categories, customers, and loaners are stored in a local Drift database.
- **Read from cache offline**: when the device is offline, the app shows cached data instead of failing immediately.
- **Queue writes locally**: create, update, and delete operations are saved locally with sync metadata.
- **Reconnect sync**: pending local changes are pushed when connectivity returns.
- **Income backlog retry**: captured income notifications stay local and are retried for remote sync when connectivity is restored and the device can upload.
- **Offline session restore**: if a user has already signed in successfully on the device, the app can restore that cached session offline and revalidate it later when online again.

First-time sign-in still requires internet access.

## Tech stack

- **Flutter**
- **BLoC** for state management
- **GoRouter** for navigation
- **Drift + SQLite** for local persistence
- **SharedPreferences** for lightweight local state such as cookies, cached session data, and app preferences
- **connectivity_plus** for connectivity awareness
- **Firebase Core + Firebase Messaging** for token lifecycle and notification fan-out support
- **Backend notification endpoint integration** (via HTTP) for income sync delivery

## Project structure

Important areas in the repository:

- `lib/app/`: app bootstrap, routing, shared services, dependency injection, theme, and utilities
- `lib/auth/`: authentication flow and session handling
- `lib/shop/`: product and category management
- `lib/customer/`: customer management
- `lib/loaner/`: loan tracking
- `lib/income/`: bank notification parsing, local income records, diagnostics, and sync coordination
- `android/app/src/main/kotlin/`: Android notification listener service for bank notification capture
- `docs/CI_CD_SETUP.md`: CI/CD, Patrol, and Fastlane setup details

## Flavors

The app includes three flavors:

- `development`
- `staging`
- `production`

Entry points:

- `lib/main_development.dart`
- `lib/main_staging.dart`
- `lib/main_production.dart`

## Getting started

### 1. Install dependencies

```sh
flutter pub get
```

### 2. Configure environment

This project uses environment files such as `.env` and `.env.dev`.

Make sure the backend base URL and any required runtime configuration are available before running the app.

### 3. Run a flavor

```sh
# Development
flutter run --flavor development --target lib/main_development.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor production --target lib/main_production.dart
```

### 4. Build a flavor

```sh
# Development
flutter build apk --flavor development --target lib/main_development.dart

# Staging
flutter build apk --flavor staging --target lib/main_staging.dart

# Production
flutter build apk --flavor production --target lib/main_production.dart
```

### 5. Bump app version

```sh
# Preview the next patch/build version
./scripts/bump_pubspec_version.sh --dry-run

# Update pubspec.yaml from 1.0.9+14 to 1.0.10+15
./scripts/bump_pubspec_version.sh
```

## Development notes

- Preferences such as theme, locale, and view mode are stored locally.
- The local database is used as the source for offline UI rendering.
- Sync state is tracked per record so failed background syncs can be retried later.
- Income notifications are captured only on Android and require notification-listener permission.
- Device role matters for income upload: **main** device can upload local captures; **sub** devices focus on receiving updates.
- The repository currently keeps Android/iOS/web targets; macOS and Windows desktop targets are not currently included.
- The app includes Patrol test scaffolding, and CI/CD automation is documented separately.

## CI/CD

- **Fastlane Android release** workflow is currently active in GitHub Actions
- **Patrol** test scaffolding exists under `patrol_test/` (the Patrol CI job is currently commented out)
- Setup details live in [`docs/CI_CD_SETUP.md`](docs/CI_CD_SETUP.md)

## Localization

The project uses Flutter localization with ARB files under `lib/l10n/arb`.

To add or update translations:

1. Edit the ARB files in `lib/l10n/arb`
2. Run the app or generate localizations manually:

```sh
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## Income sync and device roles

The income feature layers remote delivery on top of local Drift persistence.

- Main devices capture supported ABA / Chip Mong / ACLEDA notifications locally.
- Upload from local capture is allowed only when the device role is **main** and the app is online.
- Firebase setup is used for app-level messaging/token flows, while notification delivery is coordinated through the backend notification endpoint.
- If runtime config or connectivity is unavailable, the app continues in local-first mode and retries when conditions improve.

Implementation and operational notes live in [`docs/FIREBASE_INCOME_SYNC.md`](docs/FIREBASE_INCOME_SYNC.md).

For multiple Firebase projects by flavor, place `google-services.json` in:

- `android/app/src/development/`
- `android/app/src/staging/`
- `android/app/src/production/`

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
