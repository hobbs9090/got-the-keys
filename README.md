# GotTheKeys

GotTheKeys is a Rails 8 property website that doubles as a deterministic QA training harness.

It is designed to feel like a credible boutique estate-and-lettings product while remaining predictable enough for browser automation, seeded demos, trainer-led workshops, and repeatable test runs.

![GotTheKeys homepage](docs/readme/homepage.png)

The default screenshot above shows the public homepage: marketing hero, featured listings, stable navigation, and the tone of the "small property business" surface that trainees interact with first.

## Why This Repo Exists

- A believable house sales and rentals site with catalogue, property pages, enquiries, bookings, offers, rental applications, seller tools, and an admin workspace.
- A QA practice target with deterministic scenario packs, stable selectors, seeded credentials, visible timelines, and reset-friendly demo data.

## Quick Start

Prerequisites:

- Ruby `3.4.7`
- Bundler `2.x`
- Node.js `22+`
- npm
- Firefox or Chrome
- SQLite3 tools and headers

Boot locally:

```bash
bundle config set path vendor/bundle
bundle install
npm install
bin/rails db:prepare
bin/rails db:seed
bin/install_git_hooks
npm run build
bin/rails server
```

Open:

- Public site: `http://127.0.0.1:3000`
- Admin sign-in: `http://127.0.0.1:3000/admins/sign_in`
- QA guide in-app: `http://127.0.0.1:3000/admin/qa`

Baseline credentials after seeding:

- Admin: `steven@gotthekeys.com` / `secret`
- Seller examples:
  - `charlotte.hughes@example.com` / `secret`
  - `daniel.mercer@example.com` / `secret`

## Screenshot Refresh

Refresh the default homepage screenshot:

```bash
bin/update_readme_homepage_screenshot
```

Capture the catalogue screenshot:

```bash
README_SCREENSHOT_URL=http://127.0.0.1:3000/properties \
README_SCREENSHOT_PATH=docs/readme/catalogue.png \
bin/update_readme_homepage_screenshot
```

## Documentation Map

- [Product overview](docs/PRODUCT_OVERVIEW.md)
- [Getting started](docs/GETTING_STARTED.md)
- [User manual](docs/USER_MANUAL.md)
- [QA and testing guide](docs/QA_TESTING_GUIDE.md)
- [Training session guide](docs/TRAINING_SESSION_GUIDE.md)
- [Demo data operations](docs/DEMO_DATA_OPERATIONS.md)
- [Architecture overview](docs/ARCHITECTURE_OVERVIEW.md)
- [Repository map](docs/REPOSITORY_MAP.md)
- [Deployment operations](docs/DEPLOYMENT_OPERATIONS.md)
- [Environment notes](docs/ENVIRONMENT_NOTES.md)

## Operational Notes

- The tracked pre-push hook runs `bundle exec rspec` before push.
- The app is intentionally server-rendered and shared-host friendly: Apache + Passenger is the primary deployment posture.
- Staging and production deploys flow through Capistrano plus the `bin/deploy_staging` and `bin/deploy_production` helpers.
- Demo scenarios live under `db/demo_scenarios/` and are meant to be swapped repeatedly during QA practice and workshops.

## Related Deep Dives

- [Background job policy](docs/BACKGROUND_JOB_POLICY.md)
- [Booking domain architecture](docs/BOOKING_ARCHITECTURE.md)
- [Surface inventory](docs/SURFACE_INVENTORY.md)
