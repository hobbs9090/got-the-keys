# Nirvana Deployment Guide

This app is intended to deploy cleanly to a conventional Apache + Passenger shared host without Redis, Sidekiq, Docker, or any always-on worker.

## Current Target

This repo is now configured with these production defaults:

- host: `192.168.2.204`
- deploy root: `/var/www/stevenhobbs.co.uk`
- Capistrano stage: `production`

That means the Apache virtual host should point at the Capistrano `current/public` path, not the deploy root itself:

- `DocumentRoot /var/www/stevenhobbs.co.uk/current/public`
- `PassengerAppRoot /var/www/stevenhobbs.co.uk/current`

If the existing virtual host currently uses `/var/www/stevenhobbs.co.uk` directly as its document root, update that before the first Rails deploy.

## Assumptions

- Apache is already available on the host.
- Passenger is installed and enabled for Apache.
- Ruby `3.4.x` is available on the server.
- Bundler is available.
- the deploy user can SSH to `192.168.2.204` and write to `/var/www/stevenhobbs.co.uk`
- the server can fetch `git@github.com:hobbs9090/rails_got_the_keys.git`, or you will deploy from a reachable mirror
- The host can run SQLite or another relational database supported by Active Record.
- You can either build frontend assets on the server or upload prebuilt assets during deployment.

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

SMTP, if available:

- `SMTP_ADDRESS`
- `SMTP_PORT`
- `SMTP_DOMAIN`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_AUTHENTICATION`
- `SMTP_STARTTLS_AUTO`

If `SMTP_ADDRESS` is not set, production mail falls back to file delivery in `tmp/mails`, and the app will still log notifications in the admin UI.

## One-Time Server Preparation

1. Create the app root and shared writable paths:

```bash
mkdir -p /var/www/stevenhobbs.co.uk/shared/{log,tmp/pids,tmp/cache,tmp/sockets,storage}
```

2. Make sure the deploy user owns that tree or can write to it.
3. Make sure the server can clone the repo over SSH from GitHub.
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

Example Apache snippet:

```apache
<VirtualHost *:80>
  ServerName stevenhobbs.co.uk
  DocumentRoot /var/www/stevenhobbs.co.uk/current/public

  <Directory /var/www/stevenhobbs.co.uk/current/public>
    Require all granted
    Options -MultiViews
  </Directory>

  PassengerEnabled on
  PassengerAppRoot /var/www/stevenhobbs.co.uk/current
  PassengerRuby /path/to/ruby-3.4.7/bin/ruby
  PassengerAppEnv production
</VirtualHost>
```

Adapt only the Ruby path if needed. The document root and app root should match the Capistrano layout above.

## Capistrano Deploys

The `production` stage defaults to:

- host `192.168.2.204`
- deploy root `/var/www/stevenhobbs.co.uk`
- branch `master`

Run a deploy with:

```bash
cd /Users/steven/Source/GitHub/rails_got_the_keys
DEPLOY_USER=your_ssh_user bundle exec cap production deploy
```

Optional overrides:

```bash
DEPLOY_USER=your_ssh_user \
DEPLOY_HOST=192.168.2.204 \
DEPLOY_TO=/var/www/stevenhobbs.co.uk \
DEPLOY_BRANCH=master \
bundle exec cap production deploy
```

The deploy now:

- reuses shared `storage/`, `log/`, `tmp/`, `vendor/bundle/`, and `node_modules/`
- installs npm dependencies before asset precompile
- restarts Passenger with `tmp/restart.txt`

## SQLite Notes

If you are staying on SQLite in production:

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
