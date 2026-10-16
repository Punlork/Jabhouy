# 01: Backend: Google provider on the dev API

**Repository:** `jabhouy-api` (written by the app owner as a learning task; sent as a PR for the API owner to review)

**What to build:** The dev Worker accepts a Google ID token as a Sign-in method and answers with the usual Better Auth cookie session. Google sign-in with an email that already belongs to a password User is refused (Account linking off). The privacy page describes Google sign-in and the analytics the app already sends.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [ ] Better Auth has the Google social provider, configured from the `jabhouy-dev` Web client ID and secret
- [ ] The ID and secret are set on the dev Worker, in local dev vars, and named in the example vars file; the generated `Env` type knows them
- [ ] Account linking is explicitly disabled
- [ ] Posting a fake token to the social sign-in endpoint returns an invalid-token error, not an unknown-provider error
- [ ] The username availability endpoint answers for a free and a taken Username
- [ ] The privacy page mentions Google sign-in (name, email, profile photo) and analytics
- [ ] The downloaded Web client JSON is deleted or stored outside both repos

## Comments

- 2026-10-16: Resolved by `jabhouy-api` PR #1 (`b7bb295`, merged as `ae7d0a0`). Verified on `api-dev.jabhouy.com`: fake token to `/auth/sign-in/social` → `401 INVALID_TOKEN`; `/auth/is-username-available` answers `{"available":true}` for a free name. Not yet checked: a taken name returning `false`, and the exact error when Google sign-in hits a password User's email (linking off) — covered by the device walk-through.
