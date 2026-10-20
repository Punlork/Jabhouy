# P3 Step 3: Sign-in screen redesign

Status: done (uncommitted; device check pending)
Blocked by: none

- Light-theme sign-in (screen ១៣): `បន្តជាមួយ Google` first, `ឬ`, Username or email + password, outlined `ចូល`.
- Remove the sign-up page, route and link (decision 37). Keep Choose Username for new Google users.
- `FEATURE_GOOGLE_SIGN_IN` must be on in production before release (note for Phase 6).

**Done when:** sign-in works with password and Google; no route leads to sign-up.

## Comments

- Sign-in restyled to canvas ១៣ (light page, dark Google pill first, `ឬ`, labeled fields, outlined `ចូល`). The `ឬ` divider hides with the Google button when `FEATURE_GOOGLE_SIGN_IN` is off.
- Sign-up removed: page, `SignupBloc`, route, `AppRoutes.signup`, `AuthService.signup`, redirect entry. `/signup` now redirects to sign-in. Unused `signUp*` l10n strings left in place.
- Canvas `ភ្លេចលេខសម្ងាត់?` link not built: there is no reset flow in the API client.
- Phase 6 note: `FEATURE_GOOGLE_SIGN_IN` must be on in production before release, since Google is the only way to create an account (decision 37).
