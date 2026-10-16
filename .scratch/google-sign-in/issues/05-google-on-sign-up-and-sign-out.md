# 05: Google on the sign-up page, and sign-out forgets the Google account

**Repository:** `Jabhouy`

**What to build:** The sign-up page shows the same "Continue with Google" button when the flag is on. Signing out also signs out of Google, so on a shared phone the next tap on the button shows the account chooser instead of reusing the last account.

**Blocked by:** 03

**Status:** claimed

- [x] The shared button appears on the sign-up page, behaving as on sign-in
- [x] After a successful server sign-out with the flag on, `AuthService` signs out of Google; a failure there is ignored
- [x] Test: sign-out signs out of Google
- [ ] Device check: sign out, tap Google → account chooser shown
- [x] Analyzer baseline holds; workspace tests pass

## Comments

- 2026-10-16: Code done, device check pending (status stays `claimed`).
  - Sign-up page provides a `SigninBloc` for the shared button and listens to it like the sign-in page.
  - `AuthService` takes `flags` (DI passes `getIt<FeatureFlags>()`); after a successful `/sign-out` with the flag on it initializes Google if needed and calls `signOut`, swallowing any error.
