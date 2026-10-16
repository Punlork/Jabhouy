# 03: Sign in with Google from the sign-in page

**Repository:** `Jabhouy`

**What to build:** With the Google sign-in flag on, the sign-in page shows "Continue with Google". Tapping it picks a Google account, signs in through the backend, caches the User and lands on Home, exactly as a password sign-in does. Cancelling the Google dialog does nothing; offline shows the usual "needs internet" message; a Google email that belongs to a password User shows the server's refusal.

**Blocked by:** 01

**Status:** resolved

- [x] `Feature.googleSignIn` added by the three-edit recipe: on in development, off in staging and production
- [x] `google_sign_in` 7.x added; the `jabhouy-dev` Web client ID is read per flavor from the env files as the server client ID; the example env file names the key
- [x] `AuthService` signs in with Google: refuses offline, returns `null` on cancel, otherwise posts the ID token, caches the User and returns `ApiResponse`; `GoogleSignIn` is a constructor dependency
- [x] `SigninBloc` handles a Google event; one shared button widget, hidden when the flag is off, reports success through the existing `AuthSignedIn` listener
- [x] Button and error strings are in the l10n ARB files
- [x] `AuthService` tests: success posts the token and caches; cancel makes no API call; offline is refused
- [x] On an Android dev device (never `iPad (wireless)`), a Google account reaches Home and survives an app restart
- [x] Analyzer baseline holds; workspace tests pass

## Comments

- 2026-10-16: Code done, device check pending (status stays `claimed`).
  - `AuthService.signInWithGoogle()` (`lib/auth/service/auth_service.dart`): offline refused with the same message as password sign-in; Google `canceled` returns `null`; other Google errors throw and the bloc shows `googleSignInFailed`. `GoogleSignIn.initialize` runs once, lazily, with `GOOGLE_SERVER_CLIENT_ID` from the env file.
  - The sign-in page now shows every `SigninFailure` itself, and both sign-in posts pass `showSnackBar: false`. Side effect: the password path's offline message, which was returned but never shown, now appears.
  - Device check needs: an Android device or emulator with a Google account, and the `jabhouy-dev` Android OAuth client registered for `com.pl.shop.management.dev` with the debug SHA-1 `D5:4E:6D:0A:D4:90:E4:34:E8:E6:91:4D:63:18:9D:FD:11:C1:6B:D8`.
- 2026-10-16: Device check passed on NX769J (Android 16), release dev build signed with `dev-upload-keystore.jks` (SHA-1 `EE:2B:D0:36:…:9B:B9`, registered on the `jabhouy-dev` Android client). Note: debug runs are signed with the machine's debug key, which needs its own Android client to use Google sign-in.
