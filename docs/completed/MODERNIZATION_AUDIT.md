# Modernization Audit

This document records the completed modernization pass for the current app and the intentional decisions that remain in place.

## Completed Recommendations

### 1. Notifications Moved Behind Active Job

Implemented outcome:

- `Appointment` now enqueues `AppointmentNotificationJob` after create/update commits instead of delivering notifications synchronously on the request path.
- `AppointmentNotifier` still owns delivery and `NotificationLog` creation, so the admin audit trail remains intact.
- the app uses the Active Job abstraction everywhere for appointment notifications.

Current adapter posture:

- development: `:async`
- test: `:test`
- current shared-host Rails `production` environment: `:async`

Why this is the right current tradeoff:

- it improves request latency without forcing Redis, Sidekiq, or another always-on worker onto the shared host
- it preserves a clean seam for a future durable backend if operations later justify it

Important limitation:

- the current shared-host setup is still not a durable worker architecture
- if the process dies, in-flight async work can be lost
- that is acceptable for the current staging/shared-host posture, but it should not be mistaken for “background jobs fully solved forever”
- the explicit next-phase policy now lives in `docs/BACKGROUND_JOB_POLICY.md`

### 2. Frontend Stack Standardized

Implemented outcome:

- all app-authored JavaScript now runs through `app/javascript/application.js`
- legacy Sprockets-managed JavaScript for charts has been removed
- app-authored jQuery and Foundation JS widget usage have been removed
- homepage carousel, modal behaviour, responsive tables, and statistics charts now use bundled vanilla modules
- direct npm dependencies are now trimmed to the real runtime surface: Turbo plus Foundation CSS

Current frontend stance:

- keep server-rendered Rails + Turbo
- keep Foundation as the CSS framework layer for now
- keep Sprockets only for asset serving/fingerprinting, not for app-authored runtime JavaScript

This intentionally avoids a bigger asset-pipeline migration until there is a stronger reason to take it on.

### 3. CSS/View Layer Broken Into Components

Implemented outcome:

- reusable styles now live under `app/assets/stylesheets/components/`
- page composition styles live under `app/assets/stylesheets/pages/`
- homepage carousel and metric strip are rendered through dedicated partials
- shared modal markup lives in `app/views/shared/_modal.html.erb`
- statistics charts render through a helper-backed component contract instead of inline script tags
- admin shell, site chrome, QA release card, insight accordion, metric cards, and welcome sections now have dedicated SCSS partials
- legacy orphaned stylesheet files from the previous era have been removed

What remains true:

- `theme.scss` still owns shared tokens, base styles, and some broader layout primitives
- this is a deliberate incremental split, not a framework rewrite

### 4. SQLite / Shared Host Kept In Place

Decision:

- keep SQLite plus Apache/Passenger shared hosting for now

Why:

- there is no current evidence of scale pain that justifies compounding risk by changing database, hosting, and app structure at the same time
- the product is still mostly server-rendered CRUD plus notification emails
- the current deployment guide is intentionally optimized for a simple shared-host model

## Triggers For Reconsidering Infrastructure

Revisit SQLite, hosting, or the job backend only if one or more of these start happening in practice:

- recurring SQLite write-lock contention
- notification or other background work becomes operationally critical enough to require durable workers
- materially higher admin concurrency
- reporting queries noticeably slowing request handling
- backup/restore or deploy coordination becoming painful
- the need for stronger rollback or zero-downtime guarantees

## Current Recommended Posture

1. Keep using the Active Job boundary for notifications.
2. Keep all new app-authored frontend behaviour inside `app/javascript/`.
3. Keep growing UI work through component/page SCSS partials plus shared ERB partials.
4. Leave SQLite/shared hosting alone until measured pain says otherwise.
5. Keep the current background-job policy explicit by following `docs/BACKGROUND_JOB_POLICY.md`.

## Bottom Line

The repo did not need a wholesale platform rewrite.

The completed modernization path was:

1. create a job boundary for notifications
2. standardize the frontend runtime path
3. componentize the CSS/view layer
4. leave SQLite/shared hosting alone until real pain appears

For the recommended next cleanup pass before a larger feature wave, see `docs/completed/PRE_EXTENSION_CHECKLIST.md`.
