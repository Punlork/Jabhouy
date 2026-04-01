# Jabhouy

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Jabhouy is a Flutter app for small shop operations. It helps a seller manage products, customer debt/loan records, categories, customer data, and account access from a single mobile-first interface.

## What the app does

The app is organized around a few core workflows:

- **Shop inventory**: create, edit, delete, search, and filter items by category.
- **Loan management**: track customer loans, payment status, dates, and customer associations.
- **Customer management**: maintain a reusable customer list for loan and shop flows.
- **Profile and session management**: sign in, sign up, sign out, and restore a previous session when possible.

## Offline-first behavior

The app now uses an offline-first approach for the main operational flows:

- **Local database first**: shop items, categories, customers, and loaners are stored in a local Drift database.
- **Read from cache offline**: when the device is offline, the app shows cached data instead of failing immediately.
- **Queue writes locally**: create, update, and delete operations are saved locally with sync metadata.
- **Reconnect sync**: pending local changes are pushed when connectivity returns.
- **Offline session restore**: if a user has already signed in successfully on the device, the app can restore that cached session offline and revalidate it later when online again.

First-time sign-in still requires internet access.

## Tech stack

- **Flutter**
- **BLoC** for state management
- **GoRouter** for navigation
- **Drift + SQLite** for local persistence
- **SharedPreferences** for lightweight local state such as cookies, cached session data, and app preferences
- **connectivity_plus** for connectivity awareness

## Project structure

Important areas in the repository:

- `lib/app/`: app bootstrap, routing, shared services, dependency injection, theme, and utilities
- `lib/auth/`: authentication flow and session handling
- `lib/shop/`: product and category management
- `lib/customer/`: customer management
- `lib/loaner/`: loan tracking
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

## Development notes

- Preferences such as theme, locale, and view mode are stored locally.
- The local database is used as the source for offline UI rendering.
- Sync state is tracked per record so failed background syncs can be retried later.
- The app currently includes Patrol-based native UI testing setup, while CI/CD automation is documented separately.

## CI/CD

- **Patrol** is used for native UI testing under `patrol_test/`
- **Fastlane** is used for build and deployment automation
- Setup details live in [`docs/CI_CD_SETUP.md`](docs/CI_CD_SETUP.md)

## Localization

The project uses Flutter localization with ARB files under `lib/l10n/arb`.

To add or update translations:

1. Edit the ARB files in `lib/l10n/arb`
2. Run the app or generate localizations manually:

```sh
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
