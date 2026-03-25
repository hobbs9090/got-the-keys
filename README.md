# GotTheKeys

GotTheKeys is a small Rails property-listing application that has been modernized onto Rails 8.1, Ruby 3.4, and Foundation Sites 6.9. It is useful in three ways:

1. As a demo Rails application with authentication, listing pages, search, and simple CRUD.
2. As a development sandbox for trying changes to a Rails 8 app with a classic server-rendered UI.
3. As a harness for acceptance and browser automation work, because it has predictable public pages, user flows, and a lightweight SQLite setup.

## What The App Includes

- Public marketing pages such as Home, For Sale, For Rent, Search, How It Works, Contact Us, Legal, and Blog.
- User registration and login via Devise.
- Admin login via Devise.
- Property CRUD plus related photos, floor plans, and viewing times.
- English and Chinese locale support.
- Server-rendered Rails views with Foundation Sites styling and npm-based JS/CSS bundling.

## Current Stack

- Ruby `3.4.7`
- Rails `8.1.3`
- SQLite `2.1.x`
- Puma `7.2.x`
- Foundation Sites `6.9.0`
- `jsbundling-rails` with `esbuild`
- `cssbundling-rails` with `sass`
- RSpec, Capybara, Factory Bot, Faker
- Cucumber and Database Cleaner plumbing for acceptance-style testing

## Repository Layout

- [`app/`](/Users/steven/Source/GitHub/rails_got_the_keys/app): controllers, models, views, assets, and frontend entrypoints.
- [`app/javascript/`](/Users/steven/Source/GitHub/rails_got_the_keys/app/javascript): bundled JavaScript source.
- [`app/assets/stylesheets/`](/Users/steven/Source/GitHub/rails_got_the_keys/app/assets/stylesheets): Sass stylesheets.
- [`config/routes.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/config/routes.rb): main route map for the site.
- [`spec/`](/Users/steven/Source/GitHub/rails_got_the_keys/spec): RSpec model, controller, request, routing, and feature specs.
- [`features/`](/Users/steven/Source/GitHub/rails_got_the_keys/features): Cucumber support is wired up here, though no active `.feature` scenarios are committed yet.
- [`lib/tasks/populate.rake`](/Users/steven/Source/GitHub/rails_got_the_keys/lib/tasks/populate.rake): synthetic data generator for demo or load-style test data.
- [`.github/workflows/ci.yml`](/Users/steven/Source/GitHub/rails_got_the_keys/.github/workflows/ci.yml): CI pipeline.

## Prerequisites

Install the following locally:

- Ruby `3.4.7`
- Bundler `2.x`
- Node.js `22+`
- npm
- SQLite3 development libraries/tools

The project already includes [`.ruby-version`](/Users/steven/Source/GitHub/rails_got_the_keys/.ruby-version), so Ruby version managers such as `rbenv`, `asdf`, or `mise` work well.

## Fresh Setup

From the project root:

```bash
bundle config set path 'vendor/bundle'
bundle install
npm install
bin/rails db:prepare
npm run build
```

That does the following:

- installs Ruby gems into `vendor/bundle`
- installs JavaScript dependencies from `package-lock.json`
- creates or migrates the SQLite database
- builds `application.css` and `application.js` into `app/assets/builds`

## Running The App

For a simple local run:

```bash
npm run build
bin/rails server
```

Open:

- `http://127.0.0.1:3000`

### Recommended Development Workflow

Because this repo uses Rails plus separate JS/CSS bundling, the nicest day-to-day setup is three terminals:

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
bin/rails server
```

This repo does not currently define a `bin/dev` launcher, so running the watchers separately is the intended workflow.

## Frontend Build Notes

Frontend assets are generated from:

- [`app/javascript/application.js`](/Users/steven/Source/GitHub/rails_got_the_keys/app/javascript/application.js)
- [`app/assets/stylesheets/application.scss`](/Users/steven/Source/GitHub/rails_got_the_keys/app/assets/stylesheets/application.scss)

Build outputs land in:

- [`app/assets/builds/`](/Users/steven/Source/GitHub/rails_got_the_keys/app/assets/builds)

Those generated files are git-ignored except for [`.keep`](/Users/steven/Source/GitHub/rails_got_the_keys/app/assets/builds/.keep).

If the UI looks unstyled or JavaScript interactions stop working, the first recovery step should be:

```bash
npm run build
```

## Database And Demo Data

### Baseline Database

For normal setup, use:

```bash
bin/rails db:prepare
```

That is the safest command for both development and test databases.

### Generating Synthetic Demo Data

This repo includes a populate task that creates random users and properties:

```bash
bin/rails db:populate
```

Use that when you want:

- a fuller catalog for UI testing
- more realistic pagination/search behavior
- a larger acceptance-test dataset

The populate task is intentionally synthetic. It is better for exercising flows and volume than for deterministic login credentials.

### Seed Data

A legacy [`db/seeds.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/db/seeds.rb) file also exists in the repo. Treat it as historical/demo data rather than the primary setup path. For repeatable local setup, this README recommends `db:prepare` and `db:populate`.

If you do want the historical sample data, load it with:

```bash
bin/rails db:seed
```

That file creates:

- two admin accounts
- multiple seller accounts
- a large fixed property dataset

The current sample credentials in [`db/seeds.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/db/seeds.rb) use password `secret`. Because this is legacy demo data, it is best suited to local manual exploration rather than deterministic automated tests.

### Creating Deterministic Local Accounts

For acceptance automation, it is usually better to create only the records you need.

Example user:

```bash
bin/rails runner "User.create!(first_name: 'Test', last_name: 'Seller', mobile_number: '07123 456789', email: 'seller@example.com', password: 'secret123', password_confirmation: 'secret123', terms_of_service: true, language: 'en')"
```

Example admin:

```bash
bin/rails runner "Admin.create!(email: 'admin@example.com', password: 'secret123', language: 'en')"
```

Those commands are a better fit for repeatable setup because they create known credentials and only the minimum data your scenario needs.

## Useful Routes For Manual And Automated Testing

Common flows you will likely hit in development or acceptance tests:

- `/` home page
- `/properties` property listing index
- `/for_sale` for-sale listing page
- `/for_rent` for-rent listing page
- `/searches` search page
- `/users/register` user registration
- `/users/sign_in` user sign in
- `/admins/sign_in` admin sign in
- `/contact_us` contact page
- `/how_it_works` feature overview page

You can inspect the full route set with:

```bash
bin/rails routes
```

## Test Suite

### RSpec

Run the main Ruby test suite with:

```bash
npm run build
bundle exec rspec
```

The RSpec suite currently includes:

- model specs
- controller specs
- request specs
- routing specs
- feature specs using Capybara

Feature-style specs already exist under [`spec/features/`](/Users/steven/Source/GitHub/rails_got_the_keys/spec/features), including page-visit coverage and high-level UI checks.

### Cucumber

Run Cucumber with:

```bash
npm run build
bundle exec cucumber
```

Important note:

- Cucumber support is configured in [`features/support/env.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/features/support/env.rb).
- At the moment, the repository has support wiring but no committed `.feature` scenarios, so the command currently completes with `0 scenarios`.

### Test Database Behavior

Current test configuration uses:

- transactional RSpec examples via [`spec/rails_helper.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/spec/rails_helper.rb)
- Database Cleaner transactions for Cucumber
- truncation fallback for JavaScript-enabled Cucumber scenarios

That means the repo is already set up for future higher-level browser scenarios even though the Cucumber feature files themselves have not been written yet.

## Using This App As An Acceptance Test Harness

This app is a good acceptance-test target because it has:

- a simple local SQLite database
- no required external SaaS services to boot basic flows
- public pages with stable routes
- authentication flows
- CRUD-style forms
- search and filtering behavior
- both guest and signed-in paths

### Harness Mode 1: RSpec + Capybara

This is the most mature acceptance path already present in the repo.

Use it when you want:

- Rails-native browser-level specs
- assertions tightly coupled to the app
- fast iteration inside the Ruby test suite

Add new end-to-end style coverage under:

- [`spec/features/`](/Users/steven/Source/GitHub/rails_got_the_keys/spec/features)

### Harness Mode 2: Cucumber / BDD

Use Cucumber if you want business-readable acceptance scenarios.

Suggested workflow:

1. Add `.feature` files under `features/`.
2. Add matching step definitions under `features/step_definitions/`.
3. Keep environment bootstrapping in `features/support/`.

The repo is already prepared for this path; it just needs actual scenarios.

### Harness Mode 3: External Browser Automation

You can also use the app as the system under test for Playwright, Cypress, Selenium, or another external browser runner.

A practical approach is:

```bash
RAILS_ENV=test bin/rails db:prepare
npm run build
RAILS_ENV=test bin/rails server -b 127.0.0.1 -p 3001
```

Then point your browser automation tool at:

- `http://127.0.0.1:3001`

This is useful when you want:

- richer browser tooling
- screenshots/videos/traces
- cross-browser execution
- an acceptance layer separate from the app repo's native Ruby tests

For deterministic browser tests in that mode, create records explicitly in the test environment before starting the server. For example:

```bash
RAILS_ENV=test bin/rails runner "User.create!(first_name: 'Browser', last_name: 'Tester', mobile_number: '07123 456789', email: 'browser@example.com', password: 'secret123', password_confirmation: 'secret123', terms_of_service: true, language: 'en')"
```

### Good Candidate Acceptance Flows

If you want to build an acceptance suite quickly, these are strong starter scenarios:

- guest can browse the public home page and listings
- guest can switch between For Sale and For Rent searches
- guest can open contact/help UI such as tabs and reveal dialogs
- user can register and sign in
- signed-in user can create or edit a property
- admin can sign in and view members/statistics pages
- locale switching works between English and Chinese

### Data Strategy For Acceptance Tests

For deterministic automation, prefer one of these approaches:

- create records in the test database using factories or Rails helpers
- seed data explicitly with `bin/rails runner` scripts for each test run
- use `db:populate` only when the exact records do not matter

In other words:

- use factories for precision
- use `db:populate` for volume

## Development Notes

### Editor Support

Ruby LSP support is configured for this workspace and runs from the app bundle. If VS Code shows stale Ruby LSP state after dependency changes, restart the Ruby LSP or reload the window.

### Routes And Server-Side Rendering

This is primarily a server-rendered Rails app. Most pages are rendered through standard Rails controllers and ERB templates, with Foundation JavaScript enhancing tabs, orbit, reveal, accordion, and dropdown interactions.

### No External App Server Dependency For Local Work

Development and test use SQLite locally, so there is no required Postgres, Redis, or background job service just to boot the app and exercise the main UI paths.

## CI

GitHub Actions on [`main` and `master`](/Users/steven/Source/GitHub/rails_got_the_keys/.github/workflows/ci.yml) does the following:

1. checks out the repo
2. installs Node dependencies
3. installs Ruby gems
4. builds frontend assets
5. prepares the test database
6. runs RSpec
7. runs Cucumber

You can mirror CI locally with:

```bash
bundle install
npm ci
npm run build
bin/rails db:prepare
bundle exec rspec
bundle exec cucumber
```

## Troubleshooting

### The app boots but looks unstyled

Run:

```bash
npm run build
```

### Ruby dependencies fail to install

Confirm your active Ruby matches:

```bash
ruby -v
cat .ruby-version
```

### Acceptance/browser tests behave oddly

Make sure you:

- built frontend assets first
- prepared the correct database for the environment you are using
- are not accidentally pointing an external runner at a stale development server

## Summary

Use this repo when you want a compact Rails 8 application that is easy to boot, straightforward to inspect, and practical for UI, regression, and acceptance-test automation work.
