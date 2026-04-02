# GotTheKeys

GotTheKeys is a Rails 8 property platform that also serves as a deterministic QA training harness.

That dual purpose is intentional. The public site, seller tools, and admin workspace are written to feel coherent as a real property business product, but the data model, seeded scenarios, selectors, and admin diagnostics are shaped so trainers and test writers can reuse the app repeatedly. It is specifically designed to support training in Playwright for automated acceptance testing, as well as CI pipelines, performance testing, and accessibility auditing using tools such as Google Lighthouse and similar platforms.

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
npm run build
bin/rails server
```

Open:

- Public site: `https://gotthekeys.uk:3000`
- Admin sign-in: `http://gotthekeys.uk/admins/sign_in`
- QA guide in-app: `http://gotthekeys.uk/admin/qa`

Baseline credentials after seeding:

- Admin: `steven@gotthekeys.uk` / `secret`
- Seller examples:
  - `charlotte.hughes@example.com` / `secret`
  - `daniel.mercer@example.com` / `secret`

## Documentation Map

- [Documentation index](docs/INDEX.md)
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
