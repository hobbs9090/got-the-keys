# QA Training Guide

GotTheKeys is intentionally set up as a practical training target for browser automation and acceptance testing.

## Why This App Works Well For QA Practice

- deterministic demo scenarios live in version-controlled YAML
- success and validation messages are stable and human-readable
- critical UI actions expose stable selectors
- appointment status transitions are visible in the UI
- admin tools let trainers reset and switch scenarios quickly

## Core Entry Points

- Public site: `/`
- Property catalogue: `/properties`
- Search: `/searches`
- Admin login: `/admins/sign_in`
- Admin workspace: `/admin`
- Demo data controls: `/admin/demo-data`
- QA guide: `/admin/qa`

## Baseline Credentials

After `bin/rails db:seed`:

Admins:

- `steven@gotthekeys.com` / `secret`

Sellers:

- `charlotte.hughes@example.com` / `secret`
- `daniel.mercer@example.com` / `secret`
- `matthew.wells@example.com` / `secret`
- `lucy.mcclure@example.com` / `secret`

## Bundled Scenario Packs

Each bundled scenario now carries trainer metadata in the admin demo-data console:

- family
- intended journey
- complexity
- risk type
- locale coverage
- trainer notes
- expected assertions

### `baseline`

Use when you want the normal happy-path environment.

Contains:

- multiple public listings
- both sale and rental stock
- bookings in `pending`, `confirmed`, `rescheduled`, `cancelled`, `completed`, and `no_show`
- known credentials for admins and sellers

### `fully_booked_day`

Use when you want to test:

- fully booked availability
- conflict handling
- admin agenda and calendar density
- public booking empty/full-slot messaging

### `qa_edge_cases`

Use when you want:

- a booking without a phone number
- long notes and internal notes
- a rescheduled booking
- a property with no public availability

### `high_volume_search`

Use when you want:

- pagination
- sorting
- broader filter combinations
- more list cards for scanning and scraping exercises

## Building QA Seed Data

If you want a new deterministic QA pack, the easiest path is:

1. Start from `baseline` or the closest bundled scenario.
2. Use the UI, Rails console, or helper scripts to shape the data into the state you want.
3. Export that state to YAML.
4. Edit the exported YAML into a reusable scenario pack.
5. Validate it.
6. Reseed from it and confirm the counts and statuses you expect.

### Exporting The Current Dataset

From the admin UI:

- sign in as admin
- open `/admin/demo-data`
- use the export action

From the command line:

```bash
bin/rails runner 'puts DemoData::ScenarioLoader.new.export' > db/demo_scenarios/my_training_pack.yml
```

The scenario catalog automatically discovers any `*.yml` file in `db/demo_scenarios/`.

### Editing A Scenario Pack

After export, update at least these top-level fields:

- `key`
- `name`
- `description`

Recommended conventions for QA-friendly scenario files:

- keep non-admin demo accounts on `@example.com`
- keep exported passwords as `secret` unless you have a training reason to change them
- prefer relative times like `today+7d 09:00` over hard-coded dates so the pack does not go stale
- keep property `key` values short, stable, and unique because availability windows and appointments reference them
- keep the dataset focused on the workflow you want to test rather than making every pack large

### Validating Before You Commit

You can preview and validate a scenario from the admin UI before applying it:

- open `/admin/demo-data`
- use the YAML preview/import controls

Or validate it from the command line:

```bash
bin/rails runner 'payload = YAML.safe_load(File.read("db/demo_scenarios/my_training_pack.yml"), permitted_classes: [Date, Time], aliases: false); p DemoData::ScenarioValidator.new.preview(payload)'
```

That prints a normalized summary with counts and appointment statuses. If the YAML is invalid, the validator raises a descriptive error.

### Applying Your Scenario Pack

Once the YAML is in `db/demo_scenarios/` and the `key` is set:

```bash
SEED_SCENARIO=my_training_pack bin/rails db:seed
```

Then verify:

- the active scenario marker in `/admin/demo-data`
- property and appointment counts
- the status mix you intended to create
- any specific empty states, conflicts, or booking windows the pack is meant to cover

## Recommended Training Journeys

### 1. Public Booking Happy Path

1. Load `baseline`.
2. Open `/properties`.
3. Open a property with a visible slot.
4. Submit a viewing request.
5. Assert:
   - success notice
   - appointment reference
   - status timeline is visible

### 2. Admin Confirmation Flow

1. Sign in as an admin.
2. Open `/admin/appointments`.
3. Find a `pending` booking.
4. Confirm it.
5. Assert:
   - status badge changes
   - audit trail shows the transition
   - notification log records an update

### 3. Reschedule Conflict Check

1. Load `fully_booked_day`.
2. Open a fully booked property in the admin appointment book.
3. Attempt to move another booking into an occupied slot.
4. Assert:
   - validation error is shown
   - original booking remains unchanged

### 4. Empty State Coverage

1. Load `qa_edge_cases`.
2. Open the property designed for no public availability.
3. Assert:
   - booking panel shows the empty state
   - no slot links are present

### 5. Demo Data Reset Loop

1. Load `baseline`.
2. Switch to `high_volume_search`.
3. Verify property counts change.
4. Restore `baseline`.
5. Assert the diagnostics panel updates after each reset.

## Stable Selectors

The selector contract registry is visible in `/admin/qa`.

Key selectors currently exposed:

- `data-testid="site-header"`
- `data-testid="site-nav"`
- `data-testid="property-card"`
- `data-testid="book-viewing-link-<id>"`
- `data-testid="book-viewing-cta"`
- `data-testid="slot-option-<timestamp>"`
- `data-testid="appointment-form"`
- `data-testid="appointment-timeline"`
- `data-testid="admin-sidebar"`
- `data-testid="admin-appointment-row"`
- `data-testid="saved-search-panel"`
- `data-testid="property-documents-panel"`
- `data-testid="admin-property-activity-timeline"`
- `data-testid="lead-activity-timeline"`
- `data-testid="active-demo-scenario"`

## Helpful Assertions

### Public Flow

- property cards render with price, bedrooms, and CTA
- the booking form requires name and email
- the appointment show page exposes the reference and timeline

### Admin Flow

- quick actions change the status badge
- appointment history appears in the timeline
- customer history is visible on the appointment detail screen
- notification logs capture `sent`, `skipped`, or `failed`

### Demo Data Flow

- diagnostics show current counts
- bundled scenarios preview correctly before apply
- imported YAML must pass validation before it can be applied
- export produces YAML with the current dataset

## Resetting QA Environments

Important: a scenario reset replaces the current demo dataset, including:

- admins
- sellers/users
- properties
- availability windows
- appointments and appointment events
- notification logs
- booking configuration

### Fast Reset From The UI

- sign in as admin
- open `/admin/demo-data`
- choose `Restore baseline` or apply another scenario

### Command-Line Reset In Development

```bash
bin/rails db:seed
SEED_SCENARIO=qa_edge_cases bin/rails db:seed
```

Use plain `bin/rails db:seed` when you want the default `baseline` pack back.

### Full Local Database Reset For A Clean QA Loop

If the development database has drifted badly and you want to rebuild everything from scratch:

```bash
rm -f db/development.sqlite3 db/development.sqlite3-shm db/development.sqlite3-wal
bin/rails db:prepare
bin/rails db:seed
```

That recreates the local database and restores the deterministic baseline scenario.

### Resetting A Hosted QA Environment

If you have deployed the scenario YAML to a staging or hosted QA environment, use the same seed command with the correct Rails environment:

```bash
RAILS_ENV=production bundle exec rails db:seed
RAILS_ENV=production SEED_SCENARIO=qa_edge_cases bundle exec rails db:seed
```

For Capistrano-managed environments, keep the deployment guide handy as well:

- `docs/NIRVANA_DEPLOYMENT.md`

### Good QA Reset Habits

- return to `baseline` before starting a new training session unless the exercise depends on another pack
- reseed before recording demos or browser automation runs that need deterministic counts
- export useful trainer-built states back into `db/demo_scenarios/` so they can be replayed later
- verify `/admin/demo-data` after a reset so you know the intended scenario actually loaded

## Notes For AI Browser Automation

- Prefer semantic labels and `data-testid` selectors over brittle CSS selectors.
- The scenario data is deterministic enough that you can encode expectations for:
  - record counts
  - status labels
  - demo credentials
  - visible empty states
- The admin diagnostics and notification log pages are useful checkpoints for an agent that needs to verify side effects after a workflow.
