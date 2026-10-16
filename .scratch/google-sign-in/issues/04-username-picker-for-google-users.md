# 04: Username picker for Google Users

**Repository:** `Jabhouy`

**What to build:** A User signed in without a Username cannot reach Home: they land on a choose-Username page showing about three available suggestions from their name and email, plus a custom field. Saving a free Username takes them to Home; a taken one shows the server's error. Killing the app on the picker brings them back to it on next launch.

**Blocked by:** 02, 03

**Status:** claimed

- [x] A choose-Username route exists, and the redirect function sends an authenticated User without a Username there and one with a Username away from it
- [x] `AuthService` offers suggestions valid under the username plugin's rules (3–30 chars, letters, digits, `_`, `.`), filtered by the availability endpoint
- [x] The picker saves through the existing profile update and re-emits the updated User to `AuthBloc`
- [x] Strings are in the l10n ARB files
- [x] Tests: redirect cases for the gate; suggestions drop taken names
- [ ] Device check: new Google User → picker → Home; kill on picker → picker again
- [x] Analyzer baseline holds; workspace tests pass

## Comments

- 2026-10-16: Code done, device check pending (status stays `claimed`).
  - Gate: `authRedirect` sends an authenticated User without a Username (`User.hasUsername`) to `/choose_username`, and one with a Username away from it. The router does not re-run its redirect when auth changes and the app opens on Home before the session is known, so Home's existing auth listener also sends such a User to the picker; that is what covers "killed on the picker".
  - Suggestions: `AuthService.usernameSuggestions` builds candidates from name (`_` and `.`), email local part, and both plus a random 3-digit suffix, keeps valid ones, checks each with `/auth/is-username-available`, returns up to 3. A non-Latin name yields nothing and falls back to email.
  - Picker loads suggestions with a `FutureBuilder` on `AuthService` (one read; no bloc), saves through `ProfileBloc.UpdateProfile` (keeping name and image), then `AuthSignedIn(user.copyWith(username))`. A taken name shows the server's error via `ApiService`'s snackbar.
