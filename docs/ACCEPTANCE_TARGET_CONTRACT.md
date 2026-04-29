# Acceptance Target Contract

This document defines the current external acceptance-testing contract for `rails_got_the_keys`.

It is intended for the companion repository `rails_got_the_keys_acceptance`, which tests the Rails app from the outside in `local` and `staging` modes.

## Stable Routes

Public routes used by the acceptance harness:

- `/`
- `/properties`
- `/for_sale`
- `/for_rent`

Admin routes used by the acceptance harness:

- `/admins/sign_in`
- `/admin/bookings`
- `/admin/qa`

## Deterministic Demo Data

The default seed path is:

- `bundle exec rails db:prepare db:seed`

`db/seeds.rb` loads the `baseline` demo scenario by default.

The baseline scenario currently defines:

- primary admin credential: `******** / ********`
- secondary admin credential: `******** / ********`
- additional admin credential: `******** / ********`
- active scenario name: `Baseline`

## Deterministic Property Identity

Property show pages currently use numeric IDs, not slugs.

Because of that, the acceptance harness should not assume that a path like `/properties/4068` is stable across environments.

Instead, use the baseline property identity:

- address line 1: `18 Cedar Road`
- scenario key: `sevenoaks_family_home`

Recommended resolution strategy:

1. Load `/properties`
2. Find the property link whose text is `18 Cedar Road`
3. Follow that link to the property detail page

This keeps the external harness deterministic even if seeded IDs differ between `local` and `staging`.

## Selector Contract

The canonical selector registry lives in:

- `config/selector_contracts.yml`

Current contract entries include:

- `data-testid="property-card"`
- `data-testid="book-viewing-cta"`
- `data-testid="appointment-form"`
- `data-testid="saved-search-panel"`
- `data-testid="property-documents-panel"`
- `data-testid="admin-appointment-row"`
- `data-testid="admin-property-activity-timeline"`
- `data-testid="lead-activity-timeline"`
- `data-testid="active-demo-scenario"`

Additional stable selectors already present in the app and suitable for acceptance assertions:

- `data-testid="site-header"`
- `data-testid="property-showcase"`
- `data-testid="qa-version-box"`
- `data-testid="qa-app-version"`
- `data-testid="qa-git-sha"`
- `data-testid="qa-build-number"`
- `data-testid="qa-deployed-at"`
- `data-testid="qa-environment"`

## QA Diagnostics Expectations

The QA surface lives at:

- `/admin/qa`

It currently exposes:

- build version
- git SHA
- build number
- deployed-at value
- runtime environment
- mail delivery mode
- job adapter
- seeded personas
- selector contract registry

The external harness may safely assert:

- the QA page renders
- `qa-version-box` is visible
- version and build metadata fields are present
- selector contract strings such as `property-card` appear

## Environment Notes

`local`:

- expected to be seeded from the `baseline` scenario
- safe for browser smoke tests, Lighthouse, and modest read-only `k6` runs

`staging`:

- should be deterministic enough for post-deploy acceptance verification
- should preserve the baseline property identity and admin access contract
- should avoid destructive or write-heavy performance tests in routine CI
