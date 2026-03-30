# Synology Container Deployment

This document describes the recommended production shape for running GotTheKeys directly on a small Synology host when you already have a Linux VM acting as the public web edge:

- one Rails app container
- one PostgreSQL container
- Apache and Let's Encrypt on the Linux VM in front
- a single app instance

This is the recommended production path for this repo in your environment. The Linux VM keeps ownership of public `80/443`, TLS, reverse proxying, and existing sites, while the Rails app and PostgreSQL run directly on the Synology host in containers.

## Recommended Topology

```text
Internet
  -> Apache + Let's Encrypt on Linux VM
  -> Synology LAN IP:3000
  -> Rails app container (Puma)
  -> PostgreSQL container (private to the compose project)
```

Important constraints:

- keep PostgreSQL off the public internet
- keep the app as a single instance for now
- keep Active Job on `async` unless you also introduce a durable job backend

## Why This Shape

- Synology Container Manager is lighter than adding another dedicated VM for this app
- PostgreSQL is a better long-term production database than SQLite for this setup
- your existing Apache + Let's Encrypt edge already solves ingress and TLS cleanly
- the app already supports env-driven production config and Puma

## Files Added For This Deployment Path

- `Dockerfile`
- `.dockerignore`
- `compose.synology.yml`
- `.env.production.example`
- `config/puma.rb`
- `bin/container_start`

## Prepare The Host

Assume a bind-mount root like:

- `/volume1/docker/gotthekeys`

Create these directories on the host that will run the containers:

```bash
mkdir -p /volume1/docker/gotthekeys/postgres
mkdir -p /volume1/docker/gotthekeys/storage
mkdir -p /volume1/docker/gotthekeys/tmp-mails
```

If your Synology uses a different volume name, adjust `SYNOLOGY_APP_ROOT` accordingly.

## Prepare Environment Variables

Copy:

```bash
cp .env.production.example .env.production
```

Then set at least:

- `APP_HOST`
- `SECRET_KEY_BASE`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`

Generate a secret with:

```bash
ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
```

The `DATABASE_URL` should point at the internal `db` service, for example:

```text
postgres://gotthekeys:replace_this_password@db:5432/gotthekeys_production
```

## Build Strategy

For a small NAS, prefer building the image off the NAS and then using that image in production.

The included compose file uses `build:` so it remains self-contained, but for a low-power NAS you may want to:

1. build the image on a development machine or CI runner
2. push it to a registry
3. replace `build:` in `compose.synology.yml` with `image: your-registry/gotthekeys:tag`

If you want the simplest first deployment and the NAS has enough headroom, you can still let Container Manager build it directly from the repo.

## Deploy With Docker Compose

From the repo root:

```bash
docker compose --env-file .env.production -f compose.synology.yml up -d --build
```

The app startup script runs:

```bash
bundle exec rails db:prepare
bundle exec puma -C config/puma.rb
```

That means migrations are applied automatically when the app container starts.

## Deploy With Synology Container Manager

Use a Project in Container Manager and point it at `compose.synology.yml`.

Important notes:

- make sure the project has the `.env.production` values available
- confirm the host bind paths under `SYNOLOGY_APP_ROOT` already exist
- expose port `3000` only to the internal network or, better, only to the Linux VM via Synology firewall rules

## Apache Reverse Proxy

Keep Apache on the Linux VM as the single public edge.

Recommended Apache virtual host shape:

```apache
<VirtualHost *:443>
  ServerName homes.example.com

  SSLEngine on
  SSLCertificateFile /path/to/fullchain.pem
  SSLCertificateKeyFile /path/to/privkey.pem

  ProxyPreserveHost On
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Ssl "on"
  ProxyPass / http://synology-lan-ip:3000/
  ProxyPassReverse / http://synology-lan-ip:3000/
</VirtualHost>
```

Replace `synology-lan-ip` with the NAS address reachable from the Linux VM.

Because the app port is now reachable across the LAN, protect it with the Synology firewall. The safest shape is:

- allow `3000` from the Linux VM IP
- deny public access to `3000`

Recommended app env values behind Apache reverse proxy:

- `FORCE_SSL=true`
- `ASSUME_SSL=true`

The app already supports both in `production`.

Recommended Apache modules:

- `proxy`
- `proxy_http`
- `headers`
- `ssl`

## Persistence

Persist these paths:

- PostgreSQL data:
  - `${SYNOLOGY_APP_ROOT}/postgres`
- Rails app storage:
  - `${SYNOLOGY_APP_ROOT}/storage`
- fallback file mail delivery:
  - `${SYNOLOGY_APP_ROOT}/tmp-mails`

The storage mount keeps runtime state such as release build metadata and any future file-backed app data.

## Backups

Minimum backup plan:

1. nightly PostgreSQL dump
2. Synology snapshot or backup of the `postgres` directory
3. Synology snapshot or backup of the `storage` directory

Example dump command:

```bash
docker compose --env-file .env.production -f compose.synology.yml exec -T db \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > backup-$(date +%F).sql
```

Also test restores before trusting the backup routine.

## Updating The App

For a self-built project:

```bash
docker compose --env-file .env.production -f compose.synology.yml up -d --build
```

For a registry-backed image:

```bash
docker compose --env-file .env.production -f compose.synology.yml pull
docker compose --env-file .env.production -f compose.synology.yml up -d
```

Because this is a single-instance deployment, expect a brief restart window during updates.

## Operational Notes

- keep only one app replica unless you also introduce a durable job system
- do not expose port `5432` publicly
- do not expose port `3000` publicly beyond the trusted LAN or VM source IP
- if SMTP is not configured, the app writes mail output into `tmp/mails`
- if you later outgrow this setup, the next likely upgrade is:
  - registry-built images
  - durable job backend
  - stronger backup/restore automation
  - moving the app to a dedicated ingress/load-balancing tier if needed

## First Follow-Up Improvements

After the initial Synology rollout, the next repo improvements I would consider are:

1. health endpoint for container healthchecks
2. registry-first compose variant
3. production PostgreSQL CI smoke coverage
4. optional backup helper script
