# GotTheKeys

GotTheKeys is a modern Rails 8 property website, appointment-booking app, and QA automation training harness.

It is designed to feel like a credible small business product while also being predictable enough for acceptance testing, browser automation exercises, and trainer-led demos. The app stays server-rendered, uses Foundation Sites as a CSS layer with bundled Turbo/vanilla JavaScript, and remains practical to deploy on an Apache + Passenger shared host.

## What The App Does

- Public marketing and property pages with responsive componentized styling.
- Property catalogue, sale/rent filters, sorting, and richer listing cards.
- Public viewing-request flow on each property page.
- Full appointment domain with:
  - `pending`
  - `confirmed`
  - `rescheduled`
  - `cancelled`
  - `completed`
  - `no_show`
- Admin workspace with:
  - dashboard
  - agenda/day/week/month appointment views
  - appointment management
  - property and seller views
  - booking rules
  - notification log
  - demo-data controls
  - QA guide
- Deterministic YAML-backed demo scenarios for repeatable QA training.
- Optional AI-assisted larger data generation for catalogue population.

## Current Stack

- Ruby `3.4.7`
- Rails `8.1.3`
- SQLite `2.1.x`
- Puma `7.2.x`
- Active Job for notification delivery
- Foundation Sites `6.9.0` as the CSS framework layer
- `jsbundling-rails` with `esbuild` for all app-authored JavaScript
- `cssbundling-rails` with `sass`
- Turbo Rails
- Devise for `User` and `Admin`
- RSpec, Capybara, Factory Bot, Faker
- optional OpenAI enrichment via `openai-ruby`

## Modernization Status

- Appointment notifications now enqueue `AppointmentNotificationJob` after commit instead of sending synchronously on the request path.
- The frontend runtime now flows through the bundled `app/javascript/application.js`; legacy Sprockets-managed JavaScript and app-authored jQuery/Foundation JS usage have been removed.
- Component and page styles now live under `app/assets/stylesheets/components/` and `app/assets/stylesheets/pages/`, with matching partials in `app/views/`.
- SQLite plus Apache/Passenger shared hosting remain the default deployment posture until measured scale or operational pain justifies a move.

## App Versioning

- The semantic app version lives in the repo-root `VERSION` file.
- Public pages render `vX.Y.Z` from that single source of truth.
- QA and admin surfaces can also show `APP_BUILD_SHA` and `APP_BUILD_NUMBER` when those environment variables are present.
- Capistrano deploys persist optional build metadata into `storage/build_info.json`, so Passenger-hosted environments can keep reporting the exact deployed build after restart.
- `APP_VERSION` is available as a troubleshooting override, but the normal release flow is to bump `VERSION` in source control.
- The app never auto-increments its own version at runtime or during deploy.

## Asset Cache Busting

- Rails asset helpers resolve fingerprinted filenames for precompiled CSS, JavaScript, and images under `/assets`.
- Those digested filenames are the cache-busting mechanism, so a new deploy naturally points browsers at new asset URLs.
- When the app serves static files in the Rails `production` environment, including the current staging host, `/assets/*` responses are marked with `Cache-Control: public, max-age=31536000, immutable`.
- On Apache + Passenger deployments, the web server may serve precompiled files from `public/assets` before Rails sees the request, so the Apache virtual host should also set the same cache header for `/assets/`.
- See `docs/NIRVANA_DEPLOYMENT.md` for the matching Apache configuration snippet.

## Key Areas In The Repo

- `app/models/`
  Public catalogue models plus the booking domain:
  `Appointment`, `AppointmentEvent`, `AvailabilityWindow`, `BookingConfiguration`, `NotificationLog`, and `DemoScenarioRun`.
- `app/controllers/admin/`
  The password-protected admin workspace.
- `app/jobs/`
  Active Job boundaries for background work such as appointment notifications.
- `app/javascript/`
  The bundled frontend runtime, including Turbo plus app-authored controllers/modules.
- `app/assets/stylesheets/components/` and `app/assets/stylesheets/pages/`
  Component and page-level SCSS imported by the bundled `application.scss`.
- `app/services/demo_data/`
  Scenario catalog, validation, loading, export, and AI-assisted data generation.
- `db/demo_scenarios/`
  Version-controlled scenario definitions used by `db:seed` and the admin demo-data UI.
- `docs/NIRVANA_DEPLOYMENT.md`
  Apache + Passenger deployment guide for shared hosting.
- `docs/MODERNIZATION_AUDIT.md`
  Recommended modernization sequence for jobs, frontend stack, CSS/view components, and deployment posture.
- `docs/QA_TRAINING.md`
  QA walkthroughs, selectors, scenarios, and known credentials.

## Local Setup

### Prerequisites

Install locally:

- Ruby `3.4.7`
- Bundler `2.x`
- Node.js `22+`
- npm
- SQLite3 development libraries/tools

The project includes `.ruby-version`, so `rbenv`, `asdf`, `mise`, or similar tools work well.

### First-Time Install

From the repo root:

```bash
bundle config set path 'vendor/bundle'
bundle install
npm install
bin/rails db:prepare
bin/install_git_hooks
npm run build
```

`bin/install_git_hooks` configures this repo to use the tracked `.githooks/pre-push` hook, which runs `bundle exec rspec` and blocks the push if the suite fails. Each pre-push run also saves its console output to `tmp/rspec/pre_push/latest.log` so you can review the full output afterward.

GitHub Actions also enforces that product code changes under `app/` or `lib/` include matching updates under `spec/`. Static assets under `app/assets/` and Rake tasks under `lib/tasks/` are exempt from that check.

To make that rule block merges, mark the `CI` workflow as a required status check in your GitHub branch protection settings for `main`/`master`.

### Run The App

For a simple local boot:

```bash
npm run build
bin/rails server -b 127.0.0.1
```

Then open:

- `http://127.0.0.1:3000`

### Recommended Day-To-Day Workflow

Terminal 1:

```bash
npm run watch:css
```

Terminal 2:

```bash
npm run watch:js
```

Terminal 3:

```bash
bin/rails server -b 127.0.0.1
```

## Demo Data And Seeding

This repo now has two distinct data paths:

### Restoring Or Rebuilding The Development Database

Development uses SQLite, so the main local database lives at:

- `db/development.sqlite3`

If you want to rebuild from scratch and you do not need the current local data, stop the Rails server first and run:

```bash
rm -f db/development.sqlite3 db/development.sqlite3-shm db/development.sqlite3-wal
bin/rails db:prepare
bin/rails db:seed
```

That recreates the database, loads the current schema, and restores the default deterministic `baseline` demo scenario.

If you already made your own SQLite backup, restore it with the server stopped:

```bash
cp /path/to/your/development.sqlite3 db/development.sqlite3
rm -f db/development.sqlite3-shm db/development.sqlite3-wal
bin/rails db:prepare
```

If your backup also includes matching `-shm` and `-wal` files, copy those back at the same time instead of deleting them.

### 1. Deterministic Scenario Seeding

Use `db:seed` for repeatable demo and QA environments:

```bash
bin/rails db:seed
```

By default this loads the `baseline` scenario from `db/demo_scenarios/baseline.yml`.

Important: the scenario loader resets the current demo dataset before loading the selected scenario. That means `db:seed` replaces the current admins, sellers, properties, appointments, and booking configuration for the development database.

You can load a different bundled scenario:

```bash
SEED_SCENARIO=fully_booked_day bin/rails db:seed
SEED_SCENARIO=qa_edge_cases bin/rails db:seed
SEED_SCENARIO=high_volume_search bin/rails db:seed
```

Scenario files are human-editable YAML and are intended to be committed to source control.

### Relative Scenario Dates

Scenario timestamps use relative anchors such as:

- `today+7d 09:00`
- `today-5d 10:00`

That keeps the scenarios deterministic when loaded while stopping them from going stale as the real calendar moves on.

### 1a. Fresh Sevenoaks / Westerham Catalogue

If you want the current hand-curated local catalogue instead of the YAML demo scenarios, run:

```bash
bin/rails runner script/refresh_sevenoaks_westerham_catalogue.rb
```

By default that replaces the property-related records with:

- `50` houses for sale
- `50` houses for rent
- all focused on `Sevenoaks` and `Westerham`
- made-up local-style addresses

Useful overrides:

```bash
SALE_COUNT=60 RENT_COUNT=40 bin/rails runner script/refresh_sevenoaks_westerham_catalogue.rb
```

This script clears property-side records and rebuilds the catalogue, but it keeps the broader app shell in place and updates the active demo data marker to `custom_sevenoaks_westerham_catalogue`.

### 2. AI-Assisted Catalogue Population

Use `db:populate` when you want a broader generated catalogue:

```bash
bin/rails db:populate
```

That path still uses the shared `DemoData::Populator` service and optional OpenAI enrichment.

Important: `db:populate` adds data. It does not clear existing rows first. If you want a genuinely fresh generated catalogue, rebuild the development database first or reseed/reset before running it.

Useful environment variables:

- `SEED_USERS`
- `SEED_PROPERTIES`
- `SEED_PASSWORD`
- `SEED_AI_MODE=auto|on|off`
- `OPENAI_API_KEY`
- `OPENAI_SEED_MODEL`
- `OPENAI_SEED_BATCH_SIZE`

Example:

```bash
OPENAI_API_KEY=your_key_here \
SEED_AI_MODE=on \
OPENAI_SEED_MODEL=gpt-5-mini \
SEED_USERS=30 \
SEED_PROPERTIES=120 \
bin/rails db:populate
```

### Property Images And Placeholder Strategy

For now, prefer lightweight local placeholder artwork over batch AI image generation for every listing.

- If `property.image_file_name` is blank, the app now falls back to the built-in SVG placeholder `property_placeholder_listing.svg`.
- SVG placeholders are the recommended default for development and demos because bulk AI-generated listing images are optional and can become expensive quickly.
- If you do want to generate listing images, preview the prompts first:

```bash
LIMIT=5 bin/rails runner script/preview_property_image_prompts.rb
```

- Generate real property images only when needed:

```bash
OPENAI_API_KEY=your_key_here bin/rails runner script/generate_property_images.rb
```

The image-generation script writes files into `app/assets/images/` and updates each property record’s `image_file_name`.

## Bundled Demo Scenarios

The repo currently ships with:

- `baseline`
  Balanced day-to-day catalogue with mixed statuses and known credentials.
- `fully_booked_day`
  One property is fully booked across the day, useful for conflict and availability testing.
- `qa_edge_cases`
  Includes missing phone data, long notes, a reschedule, and an empty-slot property.
- `high_volume_search`
  A larger catalogue intended to trigger sorting and pagination behavior.

## Known Credentials

When you load the `baseline` scenario:

Admins:

- `steven@gotthekeys.com` / `secret`
- `stevenhobbs@meeane.co.uk` / `secret`

Sellers:

- `seller01@acme.com` / `secret`
- `seller02@acme.com` / `secret`
- `seller03@acme.com` / `secret`
- `seller04@acme.com` / `secret`

## Public Booking Flow

1. Visit a property page.
2. Choose a published slot from the booking panel.
3. Submit the viewing request form.
4. Land on a secure appointment page that shows the status timeline and reference code.
5. Use the admin workspace to confirm, reschedule, cancel, complete, or mark no-show.

## Admin Workspace

Entry points:

- `/admins/sign_in`
- `/admin`

The admin area includes:

- `Dashboard`
- `Appointments`
- `Properties`
- `Sellers`
- `Demo Data`
- `QA Guide`
- `Notifications`
- `Booking Rules`

### Demo Data UI

Inside `/admin/demo-data` an admin can:

- inspect bundled scenario previews
- restore baseline
- apply another bundled scenario
- preview and import YAML
- export the current dataset
- see diagnostics and the last reset/import/export record

## Using This App As An Acceptance-Test Harness

GotTheKeys is intentionally useful for browser automation and QA training.

It includes:

- deterministic data via YAML scenarios
- stable success and validation messaging
- visible audit timeline for appointments
- admin diagnostics
- representative happy-path and edge-case states
- stable selectors on core flows

Important selectors include:

- `data-testid="property-card"`
- `data-testid="book-viewing-cta"`
- `data-testid="appointment-form"`
- `data-testid="admin-appointment-row"`
- `data-testid="active-demo-scenario"`

The dedicated QA guide is in [`docs/QA_TRAINING.md`](docs/QA_TRAINING.md).
It now includes:

- bundled scenario purposes
- how to build and validate new QA seed packs
- how to reset local or hosted QA environments back to a known state

## Testing

Run the main suite:

```bash
bundle exec rspec
```

Generate the richer Allure HTML report locally:

```bash
ALLURE_REPORTS=1 ALLURE_CLEAN_RESULTS=1 bundle exec rspec --require allure-rspec --format progress --format AllureRspecFormatter
npx allure generate tmp/allure-results --output tmp/allure-report --report-name "GotTheKeys RSpec"
```

Once GitHub Pages is enabled for GitHub Actions on this repository, pushes to `main` or `master` will publish the latest RSpec report to:

```text
https://hobbs9090.github.io/rails_got_the_keys/
```

GitHub Pages should be set to `Source: GitHub Actions` before the first publish.

Current automated coverage includes:

- property model behaviour
- appointment conflict and audit behaviour
- public booking requests
- admin appointment status transitions
- demo scenario preview/load/export services
- public page smoke checks

## Notifications

Appointment updates enqueue `AppointmentNotificationJob`, which writes to `notification_logs`.

Behaviour by environment:

- development uses `letter_opener`
- test uses the standard test mailer
- development and the Rails `production` environment currently use the Active Job `:async` adapter for notification work
- the Rails `production` environment uses SMTP if `SMTP_ADDRESS` is set
- otherwise the Rails `production` environment falls back to file delivery under `tmp/mails`

This keeps the app responsive and usable on shared hosting even when outbound SMTP is not yet available. It is intentionally not a durable worker setup yet; the queue backend should only be revisited when real operational pain justifies it.

## Deployment

The app is intended to stay compatible with Apache + Passenger on shared hosting.
The current deploy target is a staging host, but it intentionally runs in the Rails `production` environment so it behaves like a later live production deployment.

Read the deployment guide:

- [`docs/NIRVANA_DEPLOYMENT.md`](docs/NIRVANA_DEPLOYMENT.md)

That guide covers:

- required environment variables
- asset build and precompile steps
- Apache/Passenger configuration shape
- how the `staging` Capistrano deploy works end to end
- the `current/`, `releases/`, and `shared/` layout under the deploy root
- which writable paths Capistrano keeps linked across releases
- how exact-commit staging deploys, cleanup, and rollback work
- database migration and seeding
- backup and restore strategy

## Quick Command Summary

```bash
# install deps
bundle install
npm install

# prepare the database
bin/rails db:prepare

# load deterministic demo data
bin/rails db:seed

# rebuild the local development database and restore baseline
rm -f db/development.sqlite3 db/development.sqlite3-shm db/development.sqlite3-wal
bin/rails db:prepare
bin/rails db:seed

# refresh to the current Sevenoaks / Westerham catalogue
bin/rails runner script/refresh_sevenoaks_westerham_catalogue.rb

# run the app
npm run build
bin/rails server

# run tests
bundle exec rspec
```
