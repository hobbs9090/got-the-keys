# GotTheKeys

GotTheKeys is a demo Rails property-listing app modernized onto Rails 8.1 and Foundation Sites 6.9.

## Prerequisites

- Ruby 3.4.7
- Bundler 2.x
- Node.js 22+
- SQLite3

## Local setup

```bash
rbenv install 3.4.7 # optional
rbenv local 3.4.7
bundle config set path 'vendor/bundle'
bundle install
npm install
bundle exec rails db:prepare
npm run build
```

## Run the app

```bash
npm run build
bundle exec rails s
```

Open http://localhost:3000

## Tests

```bash
npm run build
bundle exec rspec
bundle exec cucumber
```

## CI

GitHub Actions installs both Ruby and Node dependencies, builds the frontend assets, prepares the database, and runs the RSpec and Cucumber suites on pushes and pull requests.

## Current stack

- Rails 8.1.x
- Ruby 3.4.7
- Foundation Sites 6.9
- npm-managed frontend bundling with `esbuild` and `sass`

## Notes

- The app now uses `jsbundling-rails` and `cssbundling-rails` conventions, with build artifacts emitted into `app/assets/builds`.
- Legacy Foundation 4 assets and patterns have been replaced by current Foundation components such as modern Orbit, Reveal, Tabs, Accordion, and responsive top-bar navigation.
- Before production deployment, set `APP_HOST`, `RAILS_SERVE_STATIC_FILES`, and any SSL/mailer environment variables expected by your platform.
