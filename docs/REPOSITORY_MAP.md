# Repository Map

## Contents

- [Documentation index](INDEX.md)
- [Top-level layout](#top-level-layout)
- [`app/`](#app)
- [`config/`](#config)
- [`db/`](#db)
- [`spec/`](#spec)
- [`bin/`](#bin)
- [Other useful directories](#other-useful-directories)

This guide explains where the important parts of the codebase live and why they exist.

## Top-Level Layout

### `app/`

The main Rails application.

- `app/models/`
  Domain records for properties, appointments, enquiries, offers, rental applications, saved searches, documents, and supporting audit records.
- `app/controllers/`
  Public and signed-in server-rendered endpoints.
- `app/controllers/admin/`
  The protected admin workspace.
- `app/views/`
  Public, seller, Devise, and admin templates.
- `app/services/`
  Domain and orchestration code that should not sit directly in models or controllers.
- `app/services/demo_data/`
  Scenario catalog, loader, validator, exporter, and generation helpers.
- `app/services/qa/`
  Selector registry and diagnostics support.
- `app/javascript/`
  Bundled frontend modules.
- `app/assets/stylesheets/`
  SCSS for components and page layouts.
- `app/jobs/`
  Active Job entry points.
- `app/mailers/`
  Mailer classes and related templates.

## `config/`

Rails configuration plus project-specific runtime metadata.

- `config/deploy/`
  Capistrano stage files.
- `config/locales/`
  English and translated copy files.
- `config/selector_contracts.yml`
  Stable selector registry used in QA guidance.

## `db/`

- `db/migrate/`
  Schema evolution.
- `db/demo_scenarios/`
  Deterministic seeded scenario packs.
- `db/seeds.rb`
  Seed entry point.

## `docs/`

Focused project documentation.

- onboarding
- user manual
- QA/training guides
- deployment and environment notes
- architecture references

## `lib/`

- `lib/capistrano/tasks/`
  Deploy-related tasks.
- `lib/ci/`
  CI helpers and reporting code.
- `lib/tasks/`
  Custom Rake tasks.

## `script/`

One-off project helpers, including catalogue and property-image support scripts.

## `bin/`

Repo-managed operational entry points such as:

- `bin/deploy_staging`
- `bin/deploy_production`
- `bin/install_git_hooks`
- `bin/pre_push_rspec`
- `bin/update_readme_homepage_screenshot`
- `bin/i18n_health`
- `bin/i18n_sync_locales`

## `spec/`

Test coverage by layer.

- `spec/requests/`
  Request/HTML contract coverage.
- `spec/system/`
  Browser journeys.
- `spec/models/`, `spec/services/`, `spec/jobs/`, `spec/helpers/`
  Unit and integration-level behavior.
- `spec/factories/`
  Factory Bot data setup.

## Deployment Files

- `Dockerfile`
  Container build path.
- `compose.synology.yml`
  Synology/container deployment option.
- `config/deploy.rb`
  Shared Capistrano deploy behavior.
- `config/deploy/staging.rb`
- `config/deploy/production.rb`

## Read Next

- [Architecture overview](ARCHITECTURE_OVERVIEW.md)
- [Deployment operations](DEPLOYMENT_OPERATIONS.md)
