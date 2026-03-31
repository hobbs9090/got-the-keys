# Admin 2FA Plan

This document is for Codex to use as an execution brief for adding optional two-factor authentication to admin logins.

The target experience is:

- admins can enroll in TOTP-based 2FA using a QR code scanned by Google Authenticator or any compatible app
- admin 2FA can be globally enabled in optional mode
- admin 2FA can later be globally turned off from the QA area without deleting enrolled admins' secrets
- the rollout is reversible and operationally safe

## Recommended Shape

Use `devise-two-factor` for admin TOTP, keep the global switch in the existing persisted settings model `BookingConfiguration`, and surface that switch on the QA page.

Per-admin enrollment should live on a dedicated admin security page, not directly inside QA.

One important caveat: a QA toggle that disables 2FA for every admin is a real security bypass. Build it as requested, but audit every toggle and require an explicit confirmation step.

## Product Rules

- Global admin 2FA modes should be `disabled` and `optional`.
- In `disabled` mode, all admins sign in with email and password only.
- In `optional` mode, unenrolled admins still sign in with email and password only.
- In `optional` mode, enrolled admins must provide a valid OTP or backup code.
- Turning the global mode to `disabled` must not erase admin enrollment state.
- Turning the global mode back to `optional` must restore OTP enforcement for already enrolled admins.

## Implementation Plan

### 1. Add the dependency and security baseline

- Add `devise-two-factor`.
- Configure Rails Active Record encryption keys.
- Add the Warden and Devise configuration required by the gem.
- Filter `:otp_attempt` from logs.
- Ensure password reset does not auto-sign-in a user with 2FA enabled.

### 2. Extend the database

Add admin fields for:

- `otp_secret`
- `consumed_timestep`
- `otp_required_for_login`
- backup codes storage

Add a persisted global admin 2FA mode to `booking_configurations`, for example:

- `admin_two_factor_mode` with values `disabled` and `optional`

Default the new global mode to `disabled` so the feature can ship safely before rollout.

### 3. Update the admin auth model

- Replace `:database_authenticatable` with `:two_factor_authenticatable` in `Admin`.
- Add backup-code support.
- Add helper methods that clearly express whether 2FA is globally active and whether a specific admin is enrolled.

### 4. Update login handling

- Permit `:otp_attempt` in Devise sign-in params.
- Add an OTP field to the shared Devise session form.
- Keep authentication error messaging generic so password failures and OTP failures are not distinguishable.
- Make sure the login flow respects the global `admin_two_factor_mode`.

### 5. Build a dedicated admin security page

Create an admin-scoped security page where an admin can:

- see current 2FA status
- begin enrollment
- scan a QR code
- confirm setup using a first OTP
- view and save backup codes
- regenerate backup codes
- disable their own 2FA

Use the standard `otpauth://` provisioning URI and render it as a QR code for Google Authenticator compatibility.

### 6. Add the QA toggle

Extend the existing QA page with an "Admin 2FA mode" panel that edits `BookingConfiguration.current`.

The panel should:

- show the current global mode
- explain the operational effect of each mode
- warn that `disabled` bypasses OTP for all admins
- require an explicit confirmation before switching to `disabled`
- show who last changed the mode and when, if that metadata is stored

### 7. Preserve reversibility

Turning the global mode off must bypass OTP checks without deleting:

- `otp_secret`
- `otp_required_for_login`
- backup codes

This keeps the emergency off-switch operational while allowing a clean return to `optional` mode later.

### 8. Audit sensitive events

Audit at least the following:

- global admin 2FA mode changes
- admin enrollment completed
- admin 2FA disabled
- backup codes regenerated

Use the existing audit log infrastructure so operations are visible in the admin workspace.

### 9. Test coverage

Add request and system coverage for:

- admin login when global mode is `disabled`
- admin login when global mode is `optional` and admin is not enrolled
- admin login when global mode is `optional` and admin is enrolled
- backup-code login
- admin enrollment flow
- admin self-disable flow
- QA toggle behavior
- rollback from `optional` to `disabled` and back again

## Rollout Plan

1. Ship the code with `admin_two_factor_mode` defaulting to `disabled`.
2. Verify enrollment, OTP login, backup codes, and QA toggle behavior on staging.
3. Enable `optional` mode from QA when the flow is proven.
4. Use the QA toggle as the operational fallback if issues are found after rollout.

## Acceptance Criteria

- An admin can enroll by scanning a QR code in Google Authenticator.
- Enrolled admins must enter OTP when the global mode is `optional`.
- Unenrolled admins can still log in when the global mode is `optional`.
- Switching QA mode to `disabled` immediately removes OTP prompts for all admins without wiping enrollment state.
- Switching back to `optional` re-enables OTP for already enrolled admins.
- Backup codes work once each.
- Global mode changes and 2FA lifecycle changes are audited.
