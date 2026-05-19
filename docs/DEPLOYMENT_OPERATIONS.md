# Deployment Operations

## Contents

- [Documentation index](INDEX.md)
- [Primary deployment story](#primary-deployment-story)
- [Linux posture](#linux-posture)
- [Capistrano release flow](#capistrano-release-flow)
- [GitHub Actions deploy configuration](#github-actions-deploy-configuration)
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
  - host `********`
  - deploy root `********`
  - `APP_HOST=********`
  - `PUBLIC_INDEXING_ENABLED=false` by default
  - automatically runs `db:reset` after publish so the staging database is cleared and reseeded on every deploy
- `production`
  - same overall host path
  - `APP_HOST=********` by default
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

For local/manual staging deploys, provide the deployment coordinates through environment variables:

```bash
DEPLOY_USER=******** \
DEPLOY_HOST=******** \
DEPLOY_TO=******** \
DEPLOY_REPO_URL=******** \
DEPLOY_MIRROR_URL=******** \
APP_HOST=******** \
PUBLIC_INDEXING_ENABLED=false \
bin/deploy_staging
```

## Recommended Production Deploy

```bash
DEPLOY_USER=******** \
DEPLOY_HOST=******** \
DEPLOY_TO=******** \
DEPLOY_REPO_URL=******** \
DEPLOY_MIRROR_URL=******** \
APP_HOST=******** \
PUBLIC_INDEXING_ENABLED=true \
bin/deploy_production
```

Manual production deploys are still available through the `Deploy Production` workflow dispatch when you need to promote a specific ref or override the default host or deploy path.

## GitHub Actions Deploy Configuration

Deployment coordinates are intentionally not stored in the public repository. GitHub Actions reads them from repository secrets, while the non-sensitive environment URL display uses repository variables.

Required repository secrets for both deploy workflows:

- `DEPLOY_USER`
- `DEPLOY_REPO_URL`
- `DEPLOY_HOST_KEY` when SSH host keys are pinned instead of refreshed with `ssh-keyscan`
- `ACCEPTANCE_REPO_DISPATCH_TOKEN`
- `SENTRY_DSN` for Sentry monitoring in staging and production

Required staging repository secrets:

- `STAGING_DEPLOY_HOST`
- `STAGING_DEPLOY_TO`
- `STAGING_DEPLOY_MIRROR_URL`
- `STAGING_APP_HOST`

Required production repository secrets:

- `PRODUCTION_DEPLOY_HOST`
- `PRODUCTION_DEPLOY_TO`
- `PRODUCTION_DEPLOY_MIRROR_URL`
- `PRODUCTION_APP_HOST`
- `DEVISE_SECRET_KEY`
- `SECRET_KEY_BASE`

Required repository variables:

- `STAGING_APP_HOST`
- `PRODUCTION_APP_HOST`
- `SENTRY_ENVIRONMENT` when the Sentry environment name should differ from the deploy target or Rails environment
- `SENTRY_RELEASE` when the generated `got-the-keys@<version>+<build-sha>` release name should be overridden
- `SENTRY_TRACES_SAMPLE_RATE` when the default `0.05` trace sampling rate should be overridden

The staging and production workflows use the secret-backed `APP_HOST` value for the actual deploy and health checks. The same hostname is also stored as a repository variable only so GitHub can render the environment URL without exposing the rest of the deploy coordinates.

Production database settings are optional when the target host uses local Postgres socket defaults. If discrete or URL-based production database settings are needed, set either:

- `DATABASE_URL`

or all of:

- `DATABASE_NAME`
- `DATABASE_HOST`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `DATABASE_PORT` when not using the default port

SMTP settings are optional. When `SMTP_ADDRESS` is present, staging and production use SMTP; otherwise the app falls back to the admin mail preview.

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
