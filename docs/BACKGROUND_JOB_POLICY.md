# Background Job Policy

This document records the explicit background-job posture for the current app and the next extension phase.

## Current Decision

- Keep Active Job on `:async` in development.
- Keep Active Job on `:test` in test.
- Keep Active Job on `:async` on the current staging host, which runs the Rails `production` environment.
- Do not introduce Redis, Sidekiq, Solid Queue, or another durable backend yet.
- Keep all new background entry points behind Active Job so a durable backend can be adopted later without changing callers.

## Why This Is The Right Current Tradeoff

- The shared-host deployment does not currently run or supervise an always-on worker process.
- Current background volume is small and centered on appointment notifications.
- `:async` improves request latency without forcing an infrastructure jump before there is operational evidence that it is needed.
- Staying simple matches the broader posture of keeping SQLite and shared hosting until real pain justifies a move.

## What Is Safe On `:async`

- Low-volume work that is fast, bounded, and idempotent.
- Work that is acceptable to lose occasionally and retry manually.
- Work with a visible operator trail or easy manual recovery path.
- Non-destructive maintenance tasks such as cache warmers or cleanup jobs.
- Appointment notification delivery at the app's current scale and importance.

## What Is Not Safe On `:async`

- Must-run business workflows where silent loss would be unacceptable.
- Long-running jobs that may outlive the web process.
- Expensive or rate-limited third-party API calls.
- Destructive or bulk data mutations.
- Jobs that need retries, ordering guarantees, dead-letter handling, or operator dashboards.

## Likely Next Job Candidates

- `AppointmentNotificationJob`
  Keep this on Active Job and allow it on `:async` for the current shared-host phase.
- Demo scenario import, restore, and export work
  Keep this synchronous and operator-driven for now. If it becomes backgrounded, move it only after choosing a durable backend.
- AI-assisted property image generation or catalogue enrichment
  Do not put this on `:async`. It involves cost, external APIs, and longer-running work, so it should wait for a durable backend.
- Reporting exports, scheduled digests, or admin summary emails
  Treat these as durable-backend candidates if they move off the request path.
- Low-risk cache warming or housekeeping
  Allowed on `:async` only if the work is idempotent, optional, and easy to rerun.

## Trigger To Revisit A Durable Backend

Revisit the backend choice when one or more of these start happening in practice:

- lost jobs become visible operational pain
- more than one background workflow becomes important to the product
- job runtimes start stretching beyond a quick web-process task
- background work begins touching paid APIs or costly generation flows
- admins need retries, monitoring, or an auditable queue state
- the hosting setup is ready for a supervised worker process

## When That Trigger Is Reached

- Choose one durable backend before adding more background work.
- Define the host/process plan at the same time as the backend choice.
- Document retry policy, monitoring, and which job classes move first.

## Current Rule Of Thumb

If a job would materially hurt the business or operator workflow when silently lost, it does not belong on the current `:async` setup.
