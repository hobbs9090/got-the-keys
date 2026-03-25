# Nirvana Deployment Guide

This app is intended to deploy cleanly to a conventional Apache + Passenger shared host without Redis, Sidekiq, Docker, or any always-on worker.

## Assumptions

- Apache is already available on the host.
- Passenger is installed and enabled for Apache.
- Ruby `3.4.x` is available on the server.
- Bundler is available.
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

1. Upload or clone the repo to the app root.
2. Install Ruby gems:

```bash
bundle config set deployment 'true'
bundle config set without 'development test'
bundle install
```

3. Install Node dependencies and build frontend assets:

```bash
npm install
npm run build
RAILS_ENV=production bundle exec rails assets:precompile
```

4. Prepare the database:

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
  ServerName example.com
  DocumentRoot /home/youruser/apps/rails_got_the_keys/public

  <Directory /home/youruser/apps/rails_got_the_keys/public>
    Require all granted
    Options -MultiViews
  </Directory>

  PassengerEnabled on
  PassengerAppRoot /home/youruser/apps/rails_got_the_keys
  PassengerRuby /home/youruser/.rubies/ruby-3.4.7/bin/ruby
  PassengerAppEnv production
</VirtualHost>
```

Adapt paths to the actual Nirvana account layout.

## SQLite Notes

If you are staying on SQLite in production:

- make sure the `db/` directory is writable by the app user
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
cp db/production.sqlite3 backups/production-$(date +%F).sqlite3
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
