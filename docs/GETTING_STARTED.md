# Getting Started

## Contents

- [Documentation index](INDEX.md)
- [Prerequisites](#prerequisites)
- [First boot](#first-boot)
- [Useful local commands](#useful-local-commands)
- [Baseline credentials](#baseline-credentials)
- [Next steps](#next-steps)

This guide is for someone running the app locally for the first time.

## Prerequisites

Install:

- Ruby `3.4.7`
- Bundler `2.x`
- Node.js `22+`
- npm
- Firefox or Chrome
- SQLite3 libraries and command-line tools

Helpful tooling:

- `rbenv`, `asdf`, `mise`, or similar for Ruby version management
- a local mail viewer if you want to inspect file-delivered mail in non-SMTP setups

## First Boot

From the repo root:

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

If you want automatic asset rebuilds during frontend work, run these in separate terminals:

```bash
npm run watch:css
```

```bash
npm run watch:js
```

## First Pages To Visit

- `http://127.0.0.1:3000/`
- `http://127.0.0.1:3000/properties`
- `http://127.0.0.1:3000/admins/sign_in`
- `http://127.0.0.1:3000/admin/qa`

## Baseline Accounts

After `bin/rails db:seed`:

- Admin: `steven@gotthekeys.uk` / `********`
- Seller examples:
  - `charlotte.hughes@example.com` / `********`
  - `daniel.mercer@example.com` / `********`
  - `matthew.wells@example.com` / `********`
  - `lucy.mcclure@example.com` / `********`

## Common Local Commands

Prepare the database:

```bash
bin/rails db:prepare
```

Reseed the default deterministic dataset:

```bash
bin/rails db:seed
```

Load a specific scenario:

```bash
SEED_SCENARIO=fully_booked_day bin/rails db:seed
```

Run the full test suite:

```bash
bundle exec rspec
```

Run a focused browser suite:

```bash
bundle exec rspec spec/system
```

Check locale health:

```bash
bin/i18n_health
```

## Git Hook Workflow

The repo ships with a tracked pre-push hook.

Install it once:

```bash
bin/install_git_hooks
```

That hook runs `bundle exec rspec` before pushes and stores logs in:

- `tmp/rspec/pre_push/latest.log`

## If You Are Starting From A Training Perspective

Read these next:

- [User manual](USER_MANUAL.md)
- [QA and testing guide](QA_TESTING_GUIDE.md)
- [Training session guide](TRAINING_SESSION_GUIDE.md)
- [Demo data operations](DEMO_DATA_OPERATIONS.md)
