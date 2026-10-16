# Spec: Google sign-in (Android)

Status: open
Labels: ready-for-agent

## Problem Statement

- A User can only sign in with a Username and password, which they must invent and remember.
- New shop owners drop off at sign-up; most already have a Google account on their Android phone.

## Solution

- A "Continue with Google" button on the sign-in and sign-up pages adds Google as a second Sign-in method.
- A User who joined with Google picks a Username from a few suggestions, or types their own, before reaching Home.
- Ships behind a feature flag: on in development, off in staging and production until a Play-installed build is proven.

## User Stories

1. As a new User, I want to join with my Google account, so that I don't have to invent a password.
2. As a returning Google User, I want one tap to sign in, so that I reach my shop quickly; cancelling the Google dialog does nothing, and being offline shows the usual "needs internet" message.
3. As a new Google User, I want suggested Usernames plus a custom option, so that I get a valid, available Username without guessing; if I close the app mid-pick, I'm asked again on next launch.
4. As a User on a shared shop phone, I want sign-out to also forget my Google account, so that the next person chooses their own.
5. As a password User whose email matches a Google account, I want Google sign-in to be refused with a clear message, so that nobody who registered my email first can take over my data.

## Implementation Decisions

Backend (`jabhouy-api`, written by the app owner as a learning task, sent as a PR for the API's owner to review):
- Better Auth gains the Google social provider, configured with the Web OAuth client ID and secret of each environment's Cloud project.
- The client ID and secret are Worker secrets/vars per environment (dev now, production later); the local example vars file lists both names; the generated `Env` type is refreshed.
- Account linking is disabled. Password sign-up never verifies email, so linking would allow pre-registration account takeover. Google sign-in with an existing email therefore fails.
- No new endpoints. Username availability uses the username plugin's built-in availability check; setting a Username uses the existing update-user endpoint, which enforces uniqueness and format.
- The `/privacy` page is updated to mention Google sign-in (name, email, profile photo) and the analytics the app already sends.

App:
- Google OAuth setup: one Cloud project per flavor; Android clients per package name + SHA-1, including the Play App Signing key for production. The Web and Android clients of a flavor must live in the same project.
- Dev OAuth lives in its own Cloud project `jabhouy-dev`, separate from the dev Firebase project `dev-jabhouy`; that is fine because sign-in does not go through Firebase. Its Android client exists (the downloaded "installed"-type JSON); the app never reads that file, so it stays out of both repos.
- New `Feature.googleSignIn` flag, following the existing three-edit recipe; development on, staging and production off.
- `google_sign_in` 7.x (v7 API: `initialize` once with `serverClientId`, then `authenticate`). The Web client ID is read per flavor from the existing env files alongside `BASE_URL`.
- `AuthService` gains, rather than being subclassed or pushing logic into `ApiService`:
  - `signInWithGoogle()`: refuses offline; returns `null` on cancel; otherwise posts the ID token to Better Auth's social sign-in and caches the User. Returns `ApiResponse`, like the rest of auth.
  - `usernameSuggestions(User)`: about three candidates from name and email, valid under the plugin's rules (3–30 chars, letters, digits, `_`, `.`), filtered by the availability check.
  - `signout()`: after the server sign-out succeeds and the flag is on, also signs out of Google; a failure there is ignored.
  - `GoogleSignIn` is a constructor dependency, defaulting to the singleton.
- `SigninBloc` gains a Google event; one shared button widget sits on both pages, visible only with the flag on, and reports success through the existing `AuthSignedIn` listener.
- Username gate: a new choose-Username route. The router's redirect decision becomes a pure function of the auth state and path: an authenticated User without a Username goes to the picker, one with a Username leaves it for Home.
- The picker saves through the existing profile update and re-emits the updated User to `AuthBloc`; a taken name shows the server's error.
- New strings go through the l10n ARB files.

## Testing Decisions

- Tests assert observable behavior (what is posted, what is cached, what is returned, where the redirect goes), never call order or private state.
- `AuthService` seam (prior art: the existing auth service test with mocked `ApiService`, `ApiCookies`, `ConnectivityService`): Google success posts the token and caches; cancel returns `null` with no API call; offline is refused; suggestions drop taken names; sign-out signs out of Google.
- Redirect seam (new; no router tests exist): signed out → sign-in; authenticated without Username → picker; with Username on the picker → Home.
- Backend has no test suite; verify by hand on the dev Worker: availability check via curl, then the device walk-through.
- Device walk-through on an Android device (never `iPad (wireless)`): new Google User → picker → Home; kill on picker → picker again; sign out → account chooser shown; Google with a password User's email → refused.
- Analyzer stays at the 3-issue, zero-error baseline; `melos run test` passes.

## Out of Scope

- iOS and the iOS PWA.
- Staging flavor OAuth setup.
- Account linking, unlinking, and adding a password to a Google-only User.
- Google API access (Drive etc.) and any scopes beyond openid, email, profile.
- Turning the flag on in production.

## Further Notes

- Intended end state, deferred to later specs: one User reachable by both Google and Username + password; Google added to an existing password User; several Users per Shop. Order: shared Shops, then set-password for Google Users, then Account linking (needs verified email first).

- Production rollout, later: prod Cloud project clients (upload key and Play App Signing SHA-1), consent screen published with `/privacy` as the policy link and the API domain authorized, prod secrets, prod env key, a Play internal-testing build, then flip the flag.
- Shop data still belongs to one User today. Until several Users per Shop exists (a separate feature, planned next), a Shop shared across phones must use one Username and password.
- A missing Play App Signing SHA-1 fails only on Play-installed builds, with a vague developer error; this is why the flag stays off in production first.
- Not verified locally: Better Auth 1.7's ID-token sign-in, the availability endpoint path, and the exact error when linking is disabled (the API has no installed dependencies).
