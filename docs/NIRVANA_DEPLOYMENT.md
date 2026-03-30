# Nirvana Deployment Guide

This app is intended to deploy cleanly to a conventional Apache + Passenger shared host without Redis, Sidekiq, Docker, or any always-on worker.

The current notification path uses Active Job with the Rails `:async` adapter on this host. That improves request latency for appointment emails without requiring extra infrastructure, but it is not a durable worker system.

The explicit policy for what is and is not safe to run on that adapter lives in `docs/BACKGROUND_JOB_POLICY.md`.

## Current Target

This repo is now configured to use the Nirvana host for both deploy stages:

- host: `192.168.2.204`
- Capistrano stage: `staging`
- Capistrano stage: `production`

Stage defaults:

- `staging`
  - Rails environment: `staging`
  - database: PostgreSQL
  - current default deploy root: `/var/www/gotthekeys-staging`
  - current default URL: `https://stevenhobbs.co.uk`
- `production`
  - Rails environment: `production`
  - database: PostgreSQL
  - deploy root: provide `DEPLOY_TO`
  - public host: defaults to `gotthekeys.uk`

That keeps staging isolated from production while still using the same Nirvana host and Capistrano workflow shape.

That means the Apache virtual host should point at the Capistrano `current/public` path, not the deploy root itself:

- `DocumentRoot /var/www/gotthekeys-staging/current/public`
- `PassengerAppRoot /var/www/gotthekeys-staging/current`
- `PassengerRuby /home/steven/.rbenv/versions/3.4.7/bin/ruby`

If the existing virtual host still points at `/var/www/stevenhobbs.co.uk` or uses the deploy root directly as its document root, update that before the first Rails deploy.

For the current Nirvana host, the working server-side mirror is:

- `/home/steven/git/rails_got_the_keys.git`

## Assumptions

- Apache is already available on the host.
- Passenger is installed and enabled for Apache.
- Ruby `3.4.x` is available on the server.
- Bundler is available.
- the deploy user can SSH to `192.168.2.204` and write to `/var/www/gotthekeys-staging`
- the server can fetch `git@github.com:hobbs9090/rails_got_the_keys.git`, or you will deploy from a reachable mirror
- The host can run PostgreSQL for staging and production.
- You can either build frontend assets on the server or upload prebuilt assets during deployment.

The local development bundle includes `ed25519` and `bcrypt_pbkdf` so Capistrano can authenticate cleanly with `ssh-ed25519` keys.

## Required Environment Variables

Set these in the host environment or Passenger app config:

- `SECRET_KEY_BASE`
- `RAILS_SERVE_STATIC_FILES=1`

Production host defaults:

- `APP_HOST=gotthekeys.uk`
  override this only if production needs to answer on a different hostname

Production-only database settings:

- `DATABASE_URL`
  or the explicit `DATABASE_NAME`, `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD` variables

Optional but recommended:

- `FORCE_SSL=true`
- `ASSUME_SSL=true`
- `RAILS_LOG_LEVEL=info`
- `ACTIVE_JOB_QUEUE_ADAPTER=async` if you want to set the shared-host default explicitly
- `BOOKINGS_FROM_EMAIL=sales@gotthekeys.com`
- `APP_BUILD_SHA`
- `APP_BUILD_NUMBER`
- `APP_VERSION` for a temporary semantic-version override only

SMTP, if available:

- `SMTP_ADDRESS`
- `SMTP_PORT`
- `SMTP_DOMAIN`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_AUTHENTICATION`
- `SMTP_STARTTLS_AUTO`

If `SMTP_ADDRESS` is not set, the Rails `production` environment falls back to file delivery in `tmp/mails`, and the app will still log notifications in the admin UI.

Changing `ACTIVE_JOB_QUEUE_ADAPTER` alone does not create a durable job system. If you ever switch away from `:async`, do it as part of a deliberate backend and worker-process rollout, not as a one-line environment tweak on the existing shared host.

## One-Time Server Preparation

1. Create the app root and shared writable paths:

```bash
mkdir -p /var/www/gotthekeys-staging/shared/{log,tmp/pids,tmp/cache,tmp/sockets,storage}
```

2. Make sure the deploy user owns that tree or can write to it.
3. Make sure the server can clone the repo over SSH from GitHub.

If the host cannot read GitHub directly, create a bare mirror on the host and deploy from that instead:

```bash
mkdir -p ~/git
git clone --bare git@github.com:hobbs9090/rails_got_the_keys.git ~/git/rails_got_the_keys.git
```

4. Install Ruby gems:

```bash
bundle config set deployment 'true'
bundle config set without 'development test'
bundle install
```

5. Install Node dependencies and build frontend assets:

```bash
npm install
npm run build
RAILS_ENV=production bundle exec rails assets:precompile
```

6. Prepare the database:

```bash
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

If you want a different deterministic dataset:

```bash
RAILS_ENV=production SEED_SCENARIO=fully_booked_day bundle exec rails db:seed
```

## Apache + Passenger Shape

Use the app’s `public/` directory as the document root.

The `Header always set` directive below requires Apache's headers module to be enabled.

Example production Apache snippet:

```apache
<VirtualHost *:80>
  ServerName gotthekeys.uk
  ServerAlias www.gotthekeys.uk
  RewriteEngine On
  RewriteRule ^ https://gotthekeys.uk%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
  ServerName gotthekeys.uk
  ServerAlias www.gotthekeys.uk
  DocumentRoot /var/www/gotthekeys-production/current/public

  <Directory /var/www/gotthekeys-production>
    Require all granted
    Options -MultiViews +FollowSymLinks
  </Directory>

  PassengerEnabled on
  PassengerAppRoot /var/www/gotthekeys-production/current
  PassengerRuby /home/steven/.rbenv/versions/3.4.7/bin/ruby
  PassengerAppEnv production
  PassengerFriendlyErrorPages off

  SetEnv APP_HOST gotthekeys.uk
  SetEnv RAILS_ENV production
  SetEnv RAILS_SERVE_STATIC_FILES 1
  SetEnv SECRET_KEY_BASE your_generated_secret_here

  <LocationMatch "^/assets/">
    Header always set Cache-Control "public, max-age=31536000, immutable"
  </LocationMatch>

  Header always set Strict-Transport-Security "max-age=31536000"
  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/gotthekeys.uk/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/gotthekeys.uk/privkey.pem
  Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```

Adapt only the Ruby path, hostnames, and certificate paths if needed. The document root and app root should match the Capistrano layout above. The `/assets/` cache header matters even though Rails can also serve static files, because Apache may serve precompiled assets directly before Passenger is involved.

## Capistrano Deploys

The `staging` stage defaults to:

- host `192.168.2.204`
- deploy root `/var/www/gotthekeys-staging`
- branch `master`

The `production` stage uses the same Nirvana host and defaults `APP_HOST` to `gotthekeys.uk`, but still requires:

- `DEPLOY_TO`
- PostgreSQL connection env such as `DATABASE_URL`

Run a deploy with:

```bash
cd /Users/steven/Source/GitHub/rails_got_the_keys
DEPLOY_USER=your_ssh_user bundle exec cap staging deploy
```

The staging deploy now stamps QA/admin release metadata automatically:

```bash
cd /Users/steven/Source/GitHub/rails_got_the_keys
DEPLOY_USER=your_ssh_user \
bundle exec cap staging deploy
```

The public footer still renders the semantic version from `VERSION`. Admin and QA diagnostics now show the deploy-aware release version, Git SHA, and build number. Capistrano writes that metadata into `shared/storage/build_info.json`, so Passenger can keep reporting the exact deployed build after restart.

Optional overrides:

```bash
DEPLOY_USER=your_ssh_user \
DEPLOY_HOST=192.168.2.204 \
DEPLOY_TO=/var/www/gotthekeys-staging \
DEPLOY_REPO_URL=/home/steven/git/rails_got_the_keys.git \
DEPLOY_BRANCH=master \
bundle exec cap staging deploy
```

Example production deploy:

```bash
cd /Users/steven/Source/GitHub/rails_got_the_keys
APP_HOST=gotthekeys.uk \
DEPLOY_TO=/var/www/gotthekeys-production \
DATABASE_URL=postgres://user:password@localhost:5432/got_the_keys_production \
DEPLOY_USER=your_ssh_user \
bundle exec cap production deploy
```

The deploy now:

- reuses shared `storage/`, `log/`, `tmp/`, `vendor/bundle/`, and `node_modules/`
- installs npm dependencies before asset precompile
- writes deploy build metadata to `shared/storage/build_info.json`
- restarts Passenger with `tmp/restart.txt`

### What `bin/deploy_staging` Does

The repo-managed staging entrypoint is:

```bash
bin/deploy_staging
```

That wrapper does more than call Capistrano directly:

1. resolves the exact Git commit to deploy with `DEPLOY_SHA` defaulting to local `HEAD`
2. creates a synthetic ref name like `deploy/<full_sha>`
3. force-pushes that exact commit into the server-local bare mirror at `/home/steven/git/rails_got_the_keys.git`
4. exports `DEPLOY_BRANCH` to that synthetic ref
5. runs `bundle exec cap staging deploy:check`
6. runs `bundle exec cap staging deploy`

This matters because the staging deploy is commit-addressed, not branch-tip-addressed. If `master` moves after CI passes, the staging deploy can still install the exact SHA that was tested.

### What `bin/deploy_production` Does

The repo-managed production entrypoint is:

```bash
bin/deploy_production
```

It uses the same exact-commit mirror flow as staging, but targets the `production` Capistrano stage, defaults `APP_HOST` to `gotthekeys.uk`, and still requires `DEPLOY_TO` so production cannot accidentally deploy into the staging path.

### How Capistrano Lays Out The Staging App

Under the deploy root `/var/www/gotthekeys-staging`, Capistrano manages the standard release structure:

- `current/`
  Symlink to the live release Apache and Passenger should serve.
- `releases/<timestamp>/`
  Immutable release directories for individual deploys.
- `shared/`
  Persistent writable state and caches that must survive between releases.
- `repo/`
  Capistrano's cached Git checkout on the server side.

Apache should always point at `current/public`, because Capistrano switches releases by atomically moving the `current` symlink.

### What Stays Shared Between Releases

These paths are configured as `linked_dirs` and survive deploys:

- `log`
- `tmp/pids`
- `tmp/cache`
- `tmp/sockets`
- `storage`
- `vendor/bundle`
- `node_modules`

That means a new release gets fresh app code, but keeps:

- the SQLite database and uploaded/runtime files in `storage/`
- bundler-installed gems in `vendor/bundle/`
- npm packages in `node_modules/`
- logs and runtime temp directories under `tmp/` and `log/`

Capistrano symlinks those shared directories into each new release before the app is published.

### What Happens During A Staging Deploy

In practical terms, Capistrano manages staging with this flow:

1. `deploy:check` verifies the remote directory structure and linked paths exist or can be created.
2. `git:update` refreshes the cached server-side repo mirror.
3. `git:create_release` copies the chosen revision into a new timestamped release directory.
4. `deploy:symlink:shared` links the shared writable directories into that release.
5. `bundler:install` installs production gems into the shared bundle path.
6. `deploy:npm_install` installs frontend packages into shared `node_modules/`.
7. `deploy:compile_assets` precompiles the Rails frontend assets for the new release.
8. `deploy:write_build_metadata` writes deploy build info into `shared/storage/build_info.json`.
9. `passenger:restart` touches `tmp/restart.txt` so Passenger boots the new release.
10. `deploy:cleanup` removes older releases beyond the configured retention window.

Capistrano is configured here to keep only the latest `3` releases on disk:

- `set :keep_releases, 3`

That gives you a small rollback window without letting old releases accumulate indefinitely.

### How Staging Rollback Works

Because each deploy is a separate timestamped release, Capistrano can roll staging back by repointing `current` to the previous known-good release.

Typical rollback command:

```bash
DEPLOY_USER=your_ssh_user bundle exec cap staging deploy:rollback
```

That rollback uses the preserved `releases/` history, so it only works while the target release is still within the retained set.

### How Build Metadata Is Managed

Version reporting is split intentionally:

- semantic version: read from the repo `VERSION` file
- build SHA / build number: deploy metadata written during every deploy

During deploy, Capistrano writes build metadata into:

- `shared/storage/build_info.json`

The deploy task always records the deployed Git SHA. The build number defaults to the previous deployed build plus one, and if a higher `APP_BUILD_NUMBER` is provided it wins. That keeps QA/admin release diagnostics moving forward on every deploy without baking environment-specific metadata into Git-tracked source files.

## GitHub Actions Deployment

This repo now supports a split CI/CD flow:

- `.github/workflows/ci.yml` runs tests on GitHub-hosted runners
- `.github/workflows/deploy-staging.yml` deploys to staging only after `CI` succeeds on `master`
- `.github/workflows/deploy-production.yml` supports manual production deploys on the Nirvana runner
- manual staging deploys are also available through `workflow_dispatch`
- manual production deploys default `app_host` to `gotthekeys.uk` and `deploy_to` to `/var/www/gotthekeys-production`

The staging deploy job is pinned to the self-hosted runner labels:

- `self-hosted`
- `Linux`
- `X64`
- `nirvana`

The deploy workflows:

1. checks out the exact tested commit
2. uses the shared Ruby at `/home/steven/.rbenv/versions/3.4.7/bin`
3. pushes that exact commit into the server-local bare mirror with `--no-verify` because CI has already validated the revision
4. exports `APP_BUILD_SHA` and `APP_BUILD_NUMBER` into the deploy command
5. deploy the mirrored ref with `bin/deploy_staging` or `bin/deploy_production`

The self-hosted runner uses a dedicated localhost-only SSH key to reach `steven@127.0.0.1` for mirror updates and Capistrano SSH sessions. That key should remain restricted to local source addresses only.

For the GitHub `production` environment, set:

- required workflow inputs
  - `ref`
  - `app_host` defaulting to `gotthekeys.uk`
  - `deploy_to` defaulting to `/var/www/gotthekeys-production`
- required secrets
  - either `DATABASE_URL` or the explicit `DATABASE_NAME`, `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD` values
- optional secrets
  - `SMTP_ADDRESS`
  - `SMTP_PORT`
  - `SMTP_DOMAIN`
  - `SMTP_USERNAME`
  - `SMTP_PASSWORD`
- optional vars
  - `FORCE_SSL`
  - `ASSUME_SSL`
  - `RAILS_LOG_LEVEL`
  - `ACTIVE_JOB_QUEUE_ADAPTER`
  - `SMTP_AUTHENTICATION`
  - `SMTP_STARTTLS_AUTO`

## Database Notes

For the current Nirvana setup:

- `staging` uses PostgreSQL and defaults to a local database named `gotthekeys_staging`
- `production` uses PostgreSQL and should receive its connection settings through deploy-time env plus the Apache/Passenger runtime environment
- `storage/` and `tmp/` still need to be writable for caches, restarts, uploads, and file mail fallback

Typical restart after a deploy:

```bash
mkdir -p tmp
touch tmp/restart.txt
```

## Suggested Deploy Sequence

1. Pull or upload the latest code.
2. Run `bundle install`.
3. Run `npm install` if dependencies changed.
4. Run `npm run build`.
5. Run `RAILS_ENV=production bundle exec rails assets:precompile`.
6. Run `RAILS_ENV=production bundle exec rails db:migrate`.
7. Run `RAILS_ENV=production bundle exec rails db:seed`.
8. Touch `tmp/restart.txt`.

## Backups And Restore

### Database Backup

If you use PostgreSQL:

```bash
mkdir -p backups
pg_dump gotthekeys_staging > backups/staging-$(date +%F).sql
pg_dump gotthekeys_production > backups/production-$(date +%F).sql
```

### Demo Dataset Export

You can export the current demo dataset either:

- through the admin UI at `/admin/demo-data`
- or from the command line:

```bash
RAILS_ENV=production bundle exec rails runner 'puts DemoData::ScenarioLoader.new.export' > backup-demo-scenario.yml
```

### Restore To A Known State

To reset to the built-in baseline:

```bash
RAILS_ENV=production bundle exec rails db:seed
```

To load a different bundled scenario:

```bash
RAILS_ENV=production SEED_SCENARIO=qa_edge_cases bundle exec rails db:seed
```

## Troubleshooting

### Assets are missing or the site looks unstyled

Run:

```bash
npm run build
RAILS_ENV=production bundle exec rails assets:precompile
touch tmp/restart.txt
```

### Appointment emails are not leaving the server

- confirm `SMTP_ADDRESS` and related SMTP settings are present
- if SMTP is unavailable, check `tmp/mails/` and the admin notification log

### The app boots but the admin demo-data tools fail

- run `RAILS_ENV=production bundle exec rails db:migrate`
- confirm `db/demo_scenarios/*.yml` are present on the server

### Passenger is serving an old version

```bash
touch tmp/restart.txt
```

### Passenger fails during boot with a default gem version mismatch

If Passenger reports errors like:

- `You have already activated base64 0.2.0, but your Gemfile requires base64 0.3.0`
- `You have already activated stringio 3.1.2, but your Gemfile requires stringio 3.2.0`

install the matching gems into the Ruby used by Passenger, then restart:

```bash
gem install base64 -v 0.3.0 --no-document
gem install stringio -v 3.2.0 --no-document
touch tmp/restart.txt
```
