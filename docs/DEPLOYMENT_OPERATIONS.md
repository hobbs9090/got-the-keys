# Deployment Operations

## Contents

- [Documentation index](INDEX.md)
- [Primary deployment story](#primary-deployment-story)
- [Linux posture](#linux-posture)
- [Capistrano release flow](#capistrano-release-flow)
- [Release checks](#release-checks)

This guide explains how the app is deployed and operated in hosted environments.

## Primary Deployment Story

The primary hosted path is:

- Apache + Passenger
- Capistrano-managed releases
- Linux as the current main host shape

This keeps the app aligned with its shared-host-friendly design.

## Linux Posture

Current deploy stages target the Linux host shape described by:

- `config/deploy/staging.rb`
- `config/deploy/production.rb`
- `bin/deploy_staging`
- `bin/deploy_production`

Typical stage defaults:

- `staging`
  - host `192.168.2.204`
  - deploy root `/var/www/gotthekeys-staging`
  - `APP_HOST=stevenhobbs.co.uk`
  - `PUBLIC_INDEXING_ENABLED=false` by default
  - automatically runs `db:reset` after publish so the staging database is cleared and reseeded on every deploy
- `production`
  - same overall host path
  - `APP_HOST=gotthekeys.uk` by default
  - `PUBLIC_INDEXING_ENABLED=true` by default
  - `DEPLOY_TO` must be set

## Capistrano Release Flow

Capistrano handles:

- release directory management
- linked shared directories
- deploy metadata persistence
- Passenger restart

The deploy process also writes build metadata into:

- `shared/storage/build_info.json`

That supports admin and QA runtime version reporting.
In hosted environments, those version surfaces use the deployed build metadata rather than recalculating the Git SHA on each request.

Staging also invokes the existing Capistrano `deploy:reset` task after `deploy:published`.
That means every future staging deploy rebuilds the database and reloads seed data from scratch.
Production does not use this hook.

## Recommended Staging Deploy

```bash
bin/deploy_staging
```

Important:

- staging deploys are intentionally destructive to data
- every deploy clears the staging database and reseeds it
- do not use staging for data you expect to preserve between releases

GitHub Actions also deploys staging automatically after the `CI` workflow succeeds for a push to `main`.
If that staging deploy completes successfully, the production deploy workflow now promotes the same commit automatically.

Common overrides:

```bash
DEPLOY_USER=steven \
DEPLOY_HOST=192.168.2.204 \
DEPLOY_TO=/var/www/gotthekeys-staging \
APP_HOST=stevenhobbs.co.uk \
PUBLIC_INDEXING_ENABLED=false \
bin/deploy_staging
```

## Recommended Production Deploy

```bash
DEPLOY_TO=/var/www/gotthekeys-production \
APP_HOST=gotthekeys.uk \
PUBLIC_INDEXING_ENABLED=true \
bin/deploy_production
```

Manual production deploys are still available through the `Deploy Production` workflow dispatch when you need to promote a specific ref or override the default host or deploy path.

## Apache + Passenger Notes

The virtual host should point at the Capistrano `current/public` directory.

Important expectations:

- `DocumentRoot` should be `.../current/public`
- `PassengerAppRoot` should be `.../current`
- `PassengerRuby` should point at the deployed Ruby version
- `/assets/*` should be served with long-lived immutable cache headers

## Shared Writable Paths

Capistrano links and reuses paths such as:

- `log`
- `tmp/pids`
- `tmp/cache`
- `tmp/sockets`
- `storage`
- `vendor/bundle`
- `node_modules`

## Release Checks

Before a release:

1. Run the relevant spec suite locally.
2. Confirm the intended seed scenario and environment configuration.
3. Confirm asset builds are healthy.
4. Confirm the target host has the expected env vars and writable paths.

After a release:

1. Check the homepage and catalogue.
2. Check admin sign-in.
3. Confirm the build/version info appears in admin or QA diagnostics.
4. Verify the active scenario if the environment depends on seeded training data.
5. Confirm email delivery mode for the stage:
   - with SMTP secrets present, staging and production use SMTP
   - without SMTP, staging and production fall back to the admin mail preview at `/admin/letter_opener`

## Read Next

- [Environment notes](ENVIRONMENT_NOTES.md)
- [Getting started](GETTING_STARTED.md)
