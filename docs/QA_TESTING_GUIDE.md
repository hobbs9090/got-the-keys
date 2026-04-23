# QA And Testing Guide

## Contents

- [Documentation index](INDEX.md)
- [Why the app works well for QA](#why-the-app-works-well-for-qa)
- [Core testing surfaces](#core-testing-surfaces)
- [Stable selectors](#stable-selectors)
- [Deterministic scenarios](#deterministic-scenarios)
- [Recommended journeys](#recommended-journeys)
- [Playwright guidance](#playwright-guidance)
- [Lighthouse guidance](#lighthouse-guidance)
- [k6 guidance](#k6-guidance)

GotTheKeys is intentionally built as a good target for QA practice.

## Why The App Works Well For QA

- deterministic scenario packs live under `db/demo_scenarios/`
- key public and admin actions expose stable `data-testid` selectors
- booking, lead, and progression state changes remain visible in the UI
- trainer-facing reset flows let you get back to a known state quickly
- the app is mostly server-rendered, which keeps flows legible and lowers client-side ambiguity

## Core Testing Surfaces

Public:

- `/`
- `/properties`
- `/for_sale`
- `/for_rent`
- `/searches`
- `/properties/:id`
- `/properties/:property_id/appointments/new`
- enquiry, offer, and rental-application routes

Admin:

- `/admins/sign_in`
- `/admin`
- `/admin/appointments`
- `/admin/properties`
- `/admin/demo-data` — seed resets, export/import, performance data, recent activity log
- `/admin/qa` — runtime diagnostics, seeded credentials, selector contract registry

## Stable Selectors

The selector contract lives in:

- `config/selector_contracts.yml`

Key selectors include:

- `data-testid="property-card"`
- `data-testid="book-viewing-cta"`
- `data-testid="appointment-form"`
- `data-testid="saved-search-panel"`
- `data-testid="property-documents-panel"`
- `data-testid="admin-appointment-row"`
- `data-testid="admin-property-activity-timeline"`
- `data-testid="lead-activity-timeline"`
- `data-testid="active-demo-scenario"`

The in-app QA guide at `/admin/qa` is the best runtime confirmation of the selector registry and scenario state.

## Deterministic Demo Data

The baseline dataset is a YAML-backed seed used for:

- baseline happy-path practice
- repeatable public-flow assertions
- repeatable admin-flow assertions
- reset-friendly training runs

Bundled in the repo:

- `baseline`

Read [Demo data operations](DEMO_DATA_OPERATIONS.md) for seeding, preview, reset, and export workflows.

## Recommended Test Journeys

Public journeys:

1. Browse from homepage to catalogue to property detail.
2. Submit a viewing request from a property with available slots.
3. Verify the appointment confirmation page and status timeline.
4. Submit an enquiry that uses only one contact method.
5. Submit an offer on a sale listing.
6. Submit a rental application on a rental listing.

Admin journeys:

1. Sign in as admin and open the bookings desk.
2. Confirm a pending appointment.
3. Attempt a conflicting reschedule in a dense scenario.
4. Inspect notification logs after a booking change.
5. Preview and restore the baseline dataset from demo-data tools.

## Playwright Training Material

Why this app is useful for Playwright:

- public flows have stable entry points and predictable data
- admin flows exercise authentication, state transitions, and filters
- selectors are curated rather than accidental
- baseline reseeding reduces flakiness from drifting test data

Suggested Playwright exercises:

- homepage to catalogue navigation
- property-card scan and drill-down
- public appointment booking happy path
- admin login and appointment confirmation
- self-service appointment reschedule
- demo-data reset confirmation gate

Practical cautions:

- always reseed or restore a known scenario before recording baseline expectations
- prefer selector-contract keys over brittle CSS-path selectors
- be explicit about time-sensitive assertions in booking flows
- avoid assuming all properties have public slots or all listings expose the same CTA mix

## Lighthouse Training Material

Why this app is useful for Lighthouse:

- public pages are server-rendered and easy to isolate
- there is a mix of homepage, catalogue, and detail-page behavior
- seeded content makes comparative audits easier

Recommended pages to audit:

- `/`
- `/properties`
- `/for_sale`
- `/for_rent`
- a representative property detail page

Suggested focus areas:

- performance
- accessibility
- best practices
- SEO on public pages

Practical cautions:

- audit the same seeded scenario when comparing runs
- do not compare a sparse edge-case property to a media-heavy listing without noting the difference
- remember that local hardware, browser state, and image weight can skew results

## k6 Training Material

Why this app is useful for k6:

- public browse routes are realistic read-heavy targets
- the app includes both safe read paths and more delicate write flows
- seeded data lets trainers reset between exercises

Good read-heavy scenarios:

- homepage traffic
- catalogue listing traffic
- property detail traffic
- search/filter requests

Write scenarios to treat carefully:

- enquiries
- appointment submissions
- offers
- rental applications

Practical cautions:

- avoid unrealistic load shapes for a training app
- reset or reseed between destructive write-heavy runs
- do not treat the app like an infinite write sink without cleanup
- prefer moderate, believable traffic profiles over artificial spikes with no learning value

## Where Specs Fit

- `spec/requests/` covers server-rendered contracts, auth, redirects, and HTML structure
- `spec/system/` covers end-to-end browser journeys
- `spec/models/`, `spec/services/`, `spec/jobs/`, and `spec/helpers/` cover unit-level behavior

Preferred approach for new work:

- request specs for server-rendered surface behavior
- system specs for browser-level interaction
- unit specs for domain and service rules

## Read Next

- [Training session guide](TRAINING_SESSION_GUIDE.md)
- [Demo data operations](DEMO_DATA_OPERATIONS.md)
- [Repository map](REPOSITORY_MAP.md)
