# CI/CD: Patrol UI tests + Fastlane

This project uses **Patrol** for native UI tests and **Fastlane** with **GitHub Actions** for builds and optional deployment.

## Quick reference

| Task | Command |
|------|--------|
| Run Patrol UI tests locally (Android) | `patrol test --flavor development` |
| Run a single Patrol test | `patrol test -t patrol_test/example_test.dart --flavor development` |
| Check Patrol setup | `patrol doctor` |
| Android: build dev APK | `cd android && bundle exec fastlane build_dev` |
| Android: build release / deploy | `cd android && bundle exec fastlane build_release` or `beta` |
| iOS: build dev | `cd ios && bundle exec fastlane build_dev` |
| iOS: deploy to TestFlight | `cd ios && bundle exec fastlane beta` |

---

## 1. Patrol (UI testing)

### Local setup

1. **Install Patrol CLI** (once per machine):

   ```bash
   dart pub global activate patrol_cli
   ```

   Ensure `$HOME/.pub-cache/bin` is on your `PATH`.

2. **Add dev dependency** (already in `pubspec.yaml`):

   ```bash
   flutter pub add patrol --dev
   ```

3. **Config** is in `pubspec.yaml` under `patrol:` (app name, flavor `development`, Android package and iOS bundle id for the dev flavor).

4. **Run tests** with an Android emulator or iOS simulator running:

   ```bash
   flutter pub get
   patrol test --flavor development
   ```

### Writing tests

- Tests live in **`patrol_test/`** (see `patrol_test/example_test.dart`).
- Use `patrolTest()` and `$` (Patrol’s tester) for finders and native actions (e.g. `$.platform.mobile.pressHome()`).
- Docs: [Patrol – Getting started](https://patrol.leancode.pl/getting-started), [Write your first test](https://patrol.leancode.pl/documentation/write-your-first-test).

### CI (GitHub Actions)

- Workflow: **`.github/workflows/patrol-fastlane.yaml`**
- **Patrol (Android)** job: starts an Android emulator (API 34) and runs `patrol test --flavor development`.
- No extra secrets required for the Patrol job.

---

## 2. Fastlane

### Local setup

1. **Ruby + Bundler** (Android and iOS):

   ```bash
   cd android && bundle install
   cd ../ios  && bundle install
   ```

2. **Android**

   - Run lanes from `android/`:
     - `bundle exec fastlane build_dev` – debug dev APK  
     - `bundle exec fastlane build_staging` – release staging APK  
     - `bundle exec fastlane build_release` – production release APK  
     - `bundle exec fastlane internal` – build staging + upload to Play **internal**  
     - `bundle exec fastlane beta` – build release + upload to Play **beta**
   - For **supply** (Play Store): copy store metadata into `android/fastlane/metadata` (e.g. from `fastlane/metadata/android`) and configure **Google Play service account** (JSON key).

3. **iOS**

   - Run lanes from `ios/`:
     - `bundle exec fastlane build_dev` – debug, no code signing (CI-friendly)  
     - `bundle exec fastlane build_staging` / `build_release` – archive + IPA (needs signing)  
     - `bundle exec fastlane staging` – build staging + upload to **TestFlight**  
     - `bundle exec fastlane beta` – build production + upload to **TestFlight**
   - For TestFlight/App Store: configure **App Store Connect API key** and/or **match** (or other signing).

### CI (GitHub Actions)

- **Patrol & Fastlane** workflow: `.github/workflows/patrol-fastlane.yaml`
  - On **push to `main`**: after Patrol passes, **Fastlane Android** runs `build_dev`, **Fastlane iOS** runs `build_dev` (no signing).
  - No secrets required for these build-only steps.

### Secrets for deployment (optional)

Configure in **GitHub → Settings → Secrets and variables → Actions** if you want to deploy from CI:

**Android (Play Store)**

- `ANDROID_KEYSTORE_PATH` – path to keystore in runner (or use `key.properties` and upload keystore as artifact / use a custom step).
- `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD`
- For **supply**: Google Play service account JSON (e.g. `SUPPLY_JSON_KEY_DATA` or path).

**iOS (TestFlight / App Store)**

- `APP_STORE_CONNECT_API_KEY_*` or **match** secrets (`MATCH_PASSWORD`, etc.) if you use match for signing.
- See [Fastlane – GitHub Actions](https://docs.fastlane.tools/best-practices/continuous-integration/github/).

---

## 3. Workflow summary

| Trigger | What runs |
|--------|------------|
| Push / PR to `main` | Patrol Android UI tests (emulator) |
| Push to `main` (after Patrol) | Android: `fastlane build_dev`; iOS: `fastlane build_dev` |

To add **deploy** steps (e.g. Play internal/beta, TestFlight), add jobs or steps that call `fastlane internal` / `fastlane beta` (Android) or `fastlane staging` / `fastlane beta` (iOS) and set the required secrets.

---

## 4. Links

- [Patrol docs](https://patrol.leancode.pl/)
- [Fastlane for Android](https://docs.fastlane.tools/getting-started/android/setup/)
- [Fastlane for iOS](https://docs.fastlane.tools/getting-started/ios/setup/)
- [Fastlane + GitHub Actions](https://docs.fastlane.tools/best-practices/continuous-integration/github/)
