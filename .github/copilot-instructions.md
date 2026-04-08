# Copilot instructions for Jabhouy

## Build, test, and lint commands

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/income_test.dart
flutter test test/income_test.dart --plain-name "IncomeSummary groups income by bank and totals expenses"
patrol test --flavor development
patrol test -t patrol_test/example_test.dart --flavor development
flutter build apk --flavor development --target lib/main_development.dart
flutter build apk --flavor staging --target lib/main_staging.dart
flutter build apk --flavor production --target lib/main_production.dart
cd android && bundle exec fastlane build_dev
cd android && bundle exec fastlane build_release
cd ios && bundle exec fastlane build_dev
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## High-level architecture

- This is a Flutter mobile app for shop operations with three main tabs in `HomePage`: **shop**, **loaner**, and **income**. Auth, profile, customer management, and category management hang off that shell.
- Flavor entrypoints live in `lib/main_development.dart`, `lib/main_staging.dart`, and `lib/main_production.dart`. Development loads `.env.dev`; staging/production load `.env`.
- `bootstrap()` is the real startup path. It sets the global `BlocObserver`, preserves the native splash, initializes Firebase runtime options, persists Android Firebase sync config, registers all dependencies in GetIt, initializes FCM, and only then runs `App`.
- `App` provides the long-lived `AuthBloc` and `AppBloc`. `AppBloc` owns app-wide preferences such as locale, theme, grid/list mode, and the income device role. Routing is centralized in `lib/app/routes/app_routes.dart` with `GoRouter` redirects based on `AuthBloc` state.
- There is no separate repository layer. Each feature service talks to the backend through `BaseService`/`ApiService` **and** manages local Drift persistence in the same class:
  - `ShopService`
  - `CategoryService`
  - `CustomerService`
  - `LoanerService`
  - `IncomeService`
- The app is intentionally offline-first for operational data. Drift (`AppDatabase`) stores customers, categories, shop items, loaners, and bank notifications locally. Feature services read from Drift streams for UI rendering, then sync remote changes when connectivity returns.
- Auth is also partially offline-aware. `AuthService.bootstrapSession()` restores a cached user from `SharedPreferences` plus persisted cookies when possible, then revalidates online later.
- The income feature is the most cross-cutting subsystem:
  - `NotificationTrackingBridge` receives Android bank notification payloads.
  - `IncomeService` stores them in Drift and exposes filtered streams plus summary data.
  - `FirebaseIncomeSyncService` optionally mirrors notifications to Firestore, syncs remote notifications back down, and enforces a single active **main device** claim per shared scope.
  - If Firebase config is missing, income stays local-only.

## Key conventions

- Prefer feature barrel imports such as `package:my_app/app/app.dart`, `package:my_app/auth/auth.dart`, and `package:my_app/shop/shop.dart` instead of deep file imports when the barrel already exports what you need.
- Keep business logic in services and blocs, not widgets. Widgets mostly dispatch bloc events, read bloc state, and pass existing blocs through navigation.
- Nested routes rely on `GoRouter` `extra` maps to receive the active bloc instances and selected models. Match the existing keys expected in `AppRoutes` (`shop`, `category`, `loanerBloc`, `customerBloc`, `existingItem`, `existingLoaner`) instead of recreating state in form pages.
- For CRUD features backed by Drift, follow the existing offline-first pattern:
  - write to Drift first
  - use negative IDs for unsynced local records created offline
  - mark pending/error sync with `syncStatus`
  - soft-delete with `isDeleted` before remote deletion
  - replay changes from `syncPendingChanges()` when connectivity is available
- Backend calls should go through `BaseService` / `ApiService` and return `ApiResponse<T>` with explicit parsers, not ad-hoc `http` usage.
- User/session and app preferences are stored in `SharedPreferences`. Existing persisted keys cover auth session caching, locale, theme, grid mode, income device role, and Firebase runtime fallback values.
- Drift schema changes require all three steps together: update `AppDatabase`, update `schemaVersion` and migrations, then regenerate `lib/app/service/database/app_database.g.dart`.
- User-facing text is localized from ARB files under `lib/l10n/arb`; after changing translations, regenerate localizations with `flutter gen-l10n --arb-dir="lib/l10n/arb"`.
- The analyzer config extends `very_good_analysis`, but this repo intentionally relaxes some defaults such as line length and public API docs.
- The income feature has release-mode differences: some demo/debug actions are intentionally guarded by `kReleaseMode`. Preserve those checks when touching the income UI or setup flow.
- Keep the answer short and focused on the question. If you need to ask for clarification, ask one question at a time and wait for the answer before asking another.
