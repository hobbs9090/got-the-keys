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
bin/dev
```

`bin/dev` starts the Rails server and **`npm run watch:css`** together via [Foreman](https://github.com/ddollar/foreman) and `Procfile.dev`, so edits to SCSS under `app/assets/stylesheets/` are compiled into the layout-specific bundles under `app/assets/builds/` as you work. Stop both processes with one **Ctrl+C**.

If you only run `bin/rails server`, stylesheets will not update until you compile CSS separately (see below).

### Frontend assets (CSS and JavaScript)

Styles and scripts are bundled with **cssbundling-rails** and **jsbundling-rails**:

- **Sources:** `app/assets/stylesheets/public_bundle.scss` and `app/assets/stylesheets/admin_bundle.scss` build the public/admin CSS bundles; `app/javascript/public_bundle.js` and `app/javascript/admin_bundle.js` build the matching JavaScript bundles in `app/assets/builds/`.
- **Performance intent:** the split exists so normal customers do not download admin CSS and JavaScript they will never use. Rare admin-only or diagnostics-heavy surfaces should keep moving toward page-specific assets instead of being folded back into the public bundle.
- **Built files** live under `app/assets/builds/` and are **gitignored**; they are produced by Sass and esbuild, not checked in.
- **During development**, prefer **`bin/dev`** so `watch:css` keeps the CSS bundle up to date.
- **One-off compile** (for example before `bin/rails server` without Foreman): `bin/rails css:build`, `npm run build:css`, or full `npm run build` (CSS and JS).

To also auto-rebuild JavaScript while developing, add a `js` line to `Procfile.dev` (for example `js: npm run watch:js`) and restart `bin/dev`.

Open:

- Public site: [https://gotthekeys.uk](https://gotthekeys.uk)
- Admin sign-in: [http://gotthekeys.uk/admins/sign_in](http://gotthekeys.uk/admins/sign_in)
- QA guide in-app: [http://gotthekeys.uk/admin/qa](http://gotthekeys.uk/admin/qa)

## SEO Indexing Defaults

Public indexing is controlled by the `PUBLIC_INDEXING_ENABLED` environment variable, with per-environment defaults in the Rails config:

- `development`: off
- `test`: off
- `staging`: off
- `production`: on

When `PUBLIC_INDEXING_ENABLED` is set, it overrides the environment default for public pages.
Admin pages remain `noindex, nofollow` in every environment.

For backwards compatibility, the older `ALLOW_INDEXING` variable is still honored if `PUBLIC_INDEXING_ENABLED` is not set, but new deploys should prefer `PUBLIC_INDEXING_ENABLED`.

## Testing

Run the full RSpec suite with:

```bash
bundle exec rspec
```

Baseline credentials after seeding:

- Admins:
  - `********` / `********`
  - `********` / `********`
  - `********` / `********`
- Seller examples:
  - English: `********` / `********` (`en`)
  - German: `********` / `********` (`de`)
  - French: `********` / `********` (`fr`)
  - Italian: `********` / `********` (`it`)
  - Chinese: `********` / `********` (`zh`)
- Buyer examples:
  - `********` / `********`
  - `********` / `********`
  - `********` / `********`

## Performance Seed Data

The admin demo-data area now supports bulk performance seeding from `Admin -> Demo Data` at `/admin/demo-data`.

Use the `Append performance test data` panel when you want to add a large number of generated sellers and properties without resetting the current baseline dataset first.

Parameters:

- `Users to add`: creates this many additional seller accounts. This accepts any positive whole number.
- `Properties to add`: creates this many additional properties and distributes them across the generated sellers.
- `Generated user password`: the password applied to every generated seller created by that run.
- `AI enrichment mode`: `Off` is fastest and local-only; `Auto` uses OpenAI only when an API key is present; `On` requires `OPENAI_API_KEY`.
- `AI batch size`: how many property blueprints are sent per AI enrichment batch when AI mode is enabled.
- `AI model`: the OpenAI model used for AI-enriched runs.

Operational notes:

- This action appends data. It does not reset the database first.
- Re-running the performance seeder is supported. Generated seller emails stay unique across repeated runs.
- AI batch size and model are disabled in the admin form while AI mode is `Off`.
- For the fastest large dataset generation, keep AI mode set to `Off`.

There is also a CLI entry point for the same underlying generator:

```bash
SEED_USERS=500 SEED_PROPERTIES=10000 SEED_AI_MODE=off bundle exec rake db:populate
```

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

## Booking Settings

Booking rules are managed in the admin workspace under `Admin -> Booking rules`.

- `Booking duration` supports `30`, `45`, or `60` minutes.
- `Booking window length (days)` controls how many days ahead customers can book.
- Lead time, buffer time, office hours, and open weekdays are also configurable from the same screen.

These settings drive the public property booking flow, the self-service reschedule flow, and the availability service that generates bookable appointment slots.
