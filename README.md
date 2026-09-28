# Jabhouy

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Jabhouy is a Flutter app for running a small shop from one phone: inventory, customer loans, and income read from bank notifications.
It works offline first: every change is saved on the device at once and reaches the server when there is a connection.

## What it does

- **Shop inventory**: items with single, pack and custom variants, three price tiers, categories, and photos.
- **Loans**: who owes what, since when, and whether it is paid, tied to a reusable customer list.
- **Income tracking** (Android, off in production for now): captures ABA, Chip Mong and ACLEDA notifications on one *main* phone and shares them with *sub* devices.
- **Khmer and English**, light and dark themes, grid and list views.

A change made offline shows up immediately, is queued, and is sent when the phone reconnects.
A failed send is retried with backoff instead of being dropped, and it keeps the server's reason for diagnostics.
First-time sign-in needs a connection; after that, a cached session opens offline.

## How it is built

A pub workspace: the app shell in `lib/` and six packages in `packages/`, with one sync engine behind every feature.

| Package | Role |
| --- | --- |
| `jabhouy_core` | Drift schema, `Result`, feature flags, shared models. Pure Dart |
| `jabhouy_sync` | The outbox-driven sync engine. Pure Dart |
| `jabhouy_net` | HTTP transport and connectivity |
| `jabhouy_ui` | Theme, assets and shared widgets |
| `jabhouy_l10n` | Translations |
| `jabhouy_shop` | The shop feature, extracted as a package |

[ARCHITECTURE.md](ARCHITECTURE.md) explains the layers, how a write reaches the server, and what the tests enforce.
[The restructure record](docs/ARCHITECTURE_RESTRUCTURE.md) explains why it has this shape.

Stack: Flutter 3.47 (pinned with FVM), BLoC, GoRouter, Drift over SQLite, get_it, Firebase Messaging, Melos.

## Getting started

```bash
fvm install
fvm flutter pub get
cp .env.example .env && cp .env.example .env.dev   # then fill in the backend URL
fvm dart run melos run run:dev
```

Firebase is optional: without `google-services.json`, income stays local-only.
For per-flavor Firebase projects, place it in `android/app/src/<development|staging|production>/`.

## Everyday commands

```bash
fvm dart run melos run analyze    # analyze the workspace
fvm dart run melos run test       # every test suite
fvm dart run melos run gen        # regenerate Drift and copyWith code
fvm dart run melos run build:prod # release APK with production flags
./scripts/bump_pubspec_version.sh # bump version and build number
```

`melos run` works too after `dart pub global activate melos`.

## Flavors and feature flags

| Flavor | Entry point | App name | Income |
| --- | --- | --- | --- |
| development | `lib/main_development.dart` | [DEV] Jabhouy | on |
| staging | `lib/main_staging.dart` | [STG] Jabhouy | on |
| production | `lib/main_production.dart` | Jabhouy | off |

Background sync — saves that never wait for the server — is on in all three.
Each flavor reads its flags from `config/features/<flavor>.json`.
To ship or hold back a feature, change its value there; the melos scripts, fastlane lanes and VS Code launch configs already pass the file.
[ARCHITECTURE.md](ARCHITECTURE.md#switching-a-feature-off-for-a-release) covers adding a flag.

## CI

Every push and pull request to `main` runs analyze and all tests.
A push to `main` then builds a signed production APK with fastlane and publishes a GitHub release, but only if that check passed.
Details are in [docs/CI_CD_SETUP.md](docs/CI_CD_SETUP.md); income sync and device roles are in [docs/FIREBASE_INCOME_SYNC.md](docs/FIREBASE_INCOME_SYNC.md).

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
