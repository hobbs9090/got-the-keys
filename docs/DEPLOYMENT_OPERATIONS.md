# Deployment Operations

## Contents

- [Documentation index](INDEX.md)
- [Primary deployment story](#primary-deployment-story)
- [Nirvana posture](#nirvana-posture)
- [Capistrano release flow](#capistrano-release-flow)
- [Container and Synology notes](#container-and-synology-notes)
- [Release checks](#release-checks)

This guide explains how the app is deployed and operated in hosted environments.

## Primary Deployment Story

The primary hosted path is:

- Apache + Passenger
- Capistrano-managed releases
- Nirvana as the current main host shape

This keeps the app aligned with its shared-host-friendly design.

## Nirvana Posture

Current deploy stages target the Nirvana host shape described by:

- `config/deploy/staging.rb`
- `config/deploy/production.rb`
- `bin/deploy_staging`
- `bin/deploy_production`

Typical stage defaults:

- `staging`
  - host `192.168.2.204`
  - deploy root `/var/www/gotthekeys-staging`
  - `APP_HOST=stevenhobbs.co.uk`
- `production`
  - same overall host path
  - `APP_HOST=gotthekeys.uk` by default
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

## Recommended Staging Deploy

```bash
bin/deploy_staging
```

Common overrides:

```bash
DEPLOY_USER=steven \
DEPLOY_HOST=192.168.2.204 \
DEPLOY_TO=/var/www/gotthekeys-staging \
APP_HOST=stevenhobbs.co.uk \
bin/deploy_staging
```

## Recommended Production Deploy

```bash
DEPLOY_TO=/var/www/gotthekeys-production \
APP_HOST=gotthekeys.uk \
bin/deploy_production
```

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

## Alternative Container Path

An alternative deployment path exists via:

- `Dockerfile`
- `compose.synology.yml`
- `bin/container_start`

This path is useful when you want:

- a containerized app service
- a bundled Postgres service
- a Synology or Docker-oriented deployment style

It is still secondary to the Apache + Passenger posture in the current documentation set.

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

## Read Next

- [Environment notes](ENVIRONMENT_NOTES.md)
- [Getting started](GETTING_STARTED.md)
