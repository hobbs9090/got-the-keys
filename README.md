# GotTheKeys

GotTheKeys is a demo Rails web app for property listings (sale and rental).

## Prerequisites

- Ruby 3.4.7
- Bundler 2.x
- SQLite3

## Local setup

```bash
# from project root
rbenv install 3.4.7 # optional
rbenv local 3.4.7
bundle config set path 'vendor/bundle'
bundle install
bundle exec rails db:prepare
```

## Run app

```bash
bundle exec rails s
```

Open http://localhost:3000

## Tests

```bash
bundle exec rspec
bundle exec cucumber
```

## CI

This repository includes GitHub Actions workflow in `.github/workflows/ci.yml` to run tests automatically on push and pull requests.

## Upgrade notes

- Current target runtime is Rails 7.1 on Ruby 3.4.7.
- The app still contains some legacy UI/code patterns from the original Rails 4 era, but the boot/test setup is now aligned with the modern runtime.
- Add `rubocop`, `bundle-audit`, and security hardening before using the app in production.
