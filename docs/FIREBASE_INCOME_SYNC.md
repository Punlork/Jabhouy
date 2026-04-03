# Firebase income sync

This app now supports an optional Firebase sync layer for the `Income` feature.

## What it does

- The **main device** captures Android bank notifications locally with `NotificationListenerService`.
- The app stores every tracked notification in the local Drift database first.
- When Firebase is configured, the app mirrors those records to Cloud Firestore.
- **Sub devices** read the same Firestore collection and save the records into their own local database for display.

The UI still reads from Drift, so the income page keeps working offline after data has been synced once.

## Current scope model

The sync path is:

`income_sync_scopes/{scopeId}/notifications/{fingerprint}`

`scopeId` is resolved in this order:

1. `FIREBASE_INCOME_SCOPE_ID` from your env file
2. the cached backend auth user id
3. the cached email
4. the cached username

This keeps the first integration simple for the current app.

If the same signed-in account is used on multiple devices, the backend user id is usually enough for sharing the income feed.

If you want multiple different backend users to share the same feed, set the same `FIREBASE_INCOME_SCOPE_ID` on those devices for now, or move later to a backend-issued Firebase custom auth/workspace model.

## Preferred native flavor setup

For multiple Firebase projects by flavor, use the native Firebase config files first.

### Android

The Gradle Google services plugin is now wired in and supports flavor-specific files.

Place one file per flavor:

```txt
android/app/src/development/google-services.json
android/app/src/staging/google-services.json
android/app/src/production/google-services.json
```

Each file can point to a different Firebase project.

Recommended mapping:

- `development` -> dev Firebase project
- `staging` -> staging Firebase project
- `production` -> production Firebase project

If no `google-services.json` is present, the Android build skips the Google services plugin and the app falls back to env-based Firebase initialization.

### iOS

For iOS flavor separation, add the matching `GoogleService-Info.plist` per scheme/build configuration in Xcode.

This repository is still safe without those native iOS files because the app can fall back to env-based Firebase runtime options.

## Env fallback values

If you are not using native Firebase config files yet, or you want a fallback path, add these values to the env file used by the flavor you run:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID_ANDROID=your_android_app_id
FIREBASE_APP_ID_IOS=your_ios_app_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket

# Optional shared scope override
FIREBASE_INCOME_SCOPE_ID=shared-income-scope
```

If both native config and env values are missing, the app intentionally falls back to local-only income tracking.

## Firebase console setup

### 1. Create Firebase projects

For multi-flavor setup, create one Firebase project per environment if you want hard separation between dev, staging, and production data.

Add the matching Android and iOS apps for each flavor/project pair.

Example:

- `com.pl.shop.management.dev` -> development Firebase project
- `com.pl.shop.management.stg` -> staging Firebase project
- `com.pl.shop.management` -> production Firebase project

### 2. Enable Cloud Firestore

Create Firestore in the same project.

### 3. Choose Firestore rules

Because this app currently uses a custom backend auth flow instead of Firebase Auth, secure production-grade Firestore access still needs backend participation.

For development or internal testing, you can start with temporary permissive rules:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /income_sync_scopes/{scopeId}/notifications/{notificationId} {
      allow read, write: if true;
    }
    match /income_sync_scopes/{scopeId}/_system/{documentId} {
      allow read, write: if true;
    }
  }
}
```

Do **not** keep those rules for production.

## Recommended production hardening

For production, move to one of these:

- backend-issued Firebase custom tokens
- Firebase Auth linked to your app users
- backend proxy writes instead of direct client Firestore writes

That lets you write proper Firestore rules around a verified user or workspace identity.

## How sync behaves in the app

- Main device:
  - captures notifications
  - saves to Drift
  - uploads to Firestore when online
  - retries backlog uploads when connectivity returns
  - renews a single active main-device claim for the shared scope

- Sub device:
  - does not capture bank notifications
  - listens to Firestore
  - stores synced records locally for the Income page

## Single-main rule

Only one device can act as the active `main` device for a shared sync scope.

- A second device can still be set to `main` locally.
- But it cannot save local demo/native captures or upload them while another main claim is active.
- If the active main stops refreshing its claim, another main device can take over after the claim becomes stale.

## What is not included yet

- Firebase Cloud Messaging push alerts
- QR or invite-code pairing flow
- production-grade Firebase auth bridging with the existing backend

Firestore sync is integrated now; FCM can be added after the Firebase project files and auth strategy are finalized.
