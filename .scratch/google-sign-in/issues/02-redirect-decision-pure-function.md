# 02: Prefactor: the redirect decision as a pure, tested function

**Repository:** `Jabhouy`

**What to build:** Routing behaves exactly as today, but the router's redirect decision is a pure function of the auth state and the path, so the Username gate in 04 can be added and tested without building the router.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The router delegates its redirect to the new function; no behaviour changes
- [x] Tests cover: signed out on a protected path → sign-in; signed out on sign-in/sign-up → stays; authenticated on an unknown path → Home; authenticated on an allowed path → stays
- [x] Analyzer stays at the 3-issue, zero-error baseline; the workspace tests pass

## Comments

- 2026-10-16: Done. `authRedirect(authState, path, flags)` in `lib/app/routes/auth_redirect.dart` now holds both path sets and the decision; `AppRouter.router` calls it. Flags are passed in (like `visibleHomeTabs`), so tests need no `getIt`. `test/app/auth_redirect_test.dart` covers the four cases plus the income- diagnostics flag rule. Analyzer at 3 issues; `melos run test` passes. 04 adds its Username rule here.
