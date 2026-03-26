# Nirvana Deployment Guide

This app is intended to deploy cleanly to a conventional Apache + Passenger shared host without Redis, Sidekiq, Docker, or any always-on worker.

## Current Target

This repo is now configured with these deployment defaults:

- host: `192.168.2.204`
- deploy root: `/var/www/stevenhobbs.co.uk`
- Capistrano stage: `staging`
- live URL: `https://stevenhobbs.co.uk`

This is a staging host, but it intentionally boots the app in the Rails `production` environment with `RAILS_ENV=production` and `PassengerAppEnv production`. That keeps staging behaviour aligned with a later live production deploy.

That means the Apache virtual host should point at the Capistrano `current/public` path, not the deploy root itself:

- `DocumentRoot /var/www/stevenhobbs.co.uk/current/public`
- `PassengerAppRoot /var/www/stevenhobbs.co.uk/current`
- `PassengerRuby /home/steven/.rbenv/versions/3.4.7/bin/ruby`

If the existing virtual host currently uses `/var/www/stevenhobbs.co.uk` directly as its document root, update that before the first Rails deploy.

For the current Nirvana host, the working server-side mirror is:

- `/home/steven/git/rails_got_the_keys.git`

## Assumptions

- Apache is already available on the host.
- Passenger is installed and enabled for Apache.
- Ruby `3.4.x` is available on the server.
- Bundler is available.
- the deploy user can SSH to `192.168.2.204` and write to `/var/www/stevenhobbs.co.uk`
- the server can fetch `git@github.com:hobbs9090/rails_got_the_keys.git`, or you will deploy from a reachable mirror
- The host can run SQLite or another relational database supported by Active Record.
- You can either build frontend assets on the server or upload prebuilt assets during deployment.

The local development bundle includes `ed25519` and `bcrypt_pbkdf` so Capistrano can authenticate cleanly with `ssh-ed25519` keys.

## Required Environment Variables

Set these in the host environment or Passenger app config:

- `RAILS_ENV=production`
- `SECRET_KEY_BASE`
- `APP_HOST`
- `RAILS_SERVE_STATIC_FILES=1`

Optional but recommended:

- `FORCE_SSL=true`
- `ASSUME_SSL=true`
- `RAILS_LOG_LEVEL=info`
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

## One-Time Server Preparation

1. Create the app root and shared writable paths:

```bash
mkdir -p /var/www/stevenhobbs.co.uk/shared/{log,tmp/pids,tmp/cache,tmp/sockets,storage}
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

Example Apache snippet:

```apache
<VirtualHost *:80>
  ServerName stevenhobbs.co.uk
  ServerAlias www.stevenhobbs.co.uk
  RewriteEngine On
  RewriteRule ^ https://stevenhobbs.co.uk%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
  ServerName stevenhobbs.co.uk
  ServerAlias www.stevenhobbs.co.uk
  DocumentRoot /var/www/stevenhobbs.co.uk/current/public

  <Directory /var/www/stevenhobbs.co.uk>
    Require all granted
    Options -MultiViews +FollowSymLinks
  </Directory>

  PassengerEnabled on
  PassengerAppRoot /var/www/stevenhobbs.co.uk/current
  PassengerRuby /home/steven/.rbenv/versions/3.4.7/bin/ruby
  PassengerAppEnv production
  PassengerFriendlyErrorPages off

  SetEnv APP_HOST stevenhobbs.co.uk
  SetEnv RAILS_ENV production
  SetEnv RAILS_SERVE_STATIC_FILES 1
  SetEnv SECRET_KEY_BASE your_generated_secret_here

  <LocationMatch "^/assets/">
    Header always set Cache-Control "public, max-age=31536000, immutable"
  </LocationMatch>

  Header always set Strict-Transport-Security "max-age=31536000"
  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/stevenhobbs.co.uk/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/stevenhobbs.co.uk/privkey.pem
  Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```

Adapt only the Ruby path, hostnames, and certificate paths if needed. The document root and app root should match the Capistrano layout above. The `/assets/` cache header matters even though Rails can also serve static files, because Apache may serve precompiled assets directly before Passenger is involved.

## Capistrano Deploys

The `staging` stage defaults to:

- host `192.168.2.204`
- deploy root `/var/www/stevenhobbs.co.uk`
- branch `master`

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
DEPLOY_TO=/var/www/stevenhobbs.co.uk \
DEPLOY_REPO_URL=/home/steven/git/rails_got_the_keys.git \
DEPLOY_BRANCH=master \
bundle exec cap staging deploy
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

### How Capistrano Lays Out The Staging App

Under the deploy root `/var/www/stevenhobbs.co.uk`, Capistrano manages the standard release structure:

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
- manual staging deploys are also available through `workflow_dispatch`

The staging deploy job is pinned to the self-hosted runner labels:

- `self-hosted`
- `Linux`
- `X64`
- `nirvana`

The deploy workflow:

1. checks out the exact tested commit
2. uses the shared Ruby at `/home/steven/.rbenv/versions/3.4.7/bin`
3. pushes that exact commit into the server-local bare mirror
4. exports `APP_BUILD_SHA` and `APP_BUILD_NUMBER` into the deploy command
5. deploys the mirrored ref with `bin/deploy_staging`

The self-hosted runner uses a dedicated localhost-only SSH key to reach `steven@127.0.0.1` for mirror updates and Capistrano SSH sessions. That key should remain restricted to local source addresses only.

## SQLite Notes

If you are staying on SQLite for the Rails `production` environment:

- the production database now lives at `storage/production.sqlite3` by default
- make sure the `storage/` directory is writable by the app user
- make sure `tmp/` is writable for caching, restarts, and mail fallback
- back up the `.sqlite3` file before major changes

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

If you use SQLite:

```bash
mkdir -p backups
cp storage/production.sqlite3 backups/production-$(date +%F).sqlite3
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
