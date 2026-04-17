# Environment Notes

## Contents

- [Documentation index](INDEX.md)
- [Databases](#databases)
- [Key environment variables](#key-environment-variables)
- [Asset and build notes](#asset-and-build-notes)
- [Local mail and diagnostics](#local-mail-and-diagnostics)
- [Hosted environment notes](#hosted-environment-notes)

This page collects the environment-specific details that do not belong in the README.

## Databases

Local and simple-host posture:

- SQLite is the easiest local/default path

Hosted production posture:

- PostgreSQL is the intended hosted database on Linux-backed deployments

The app documentation should not treat SQLite and PostgreSQL as interchangeable in operations. SQLite is the simple local/shared-host posture; PostgreSQL is the stronger hosted production posture.

## Key Environment Variables

Common runtime variables:

- `SECRET_KEY_BASE`
- `APP_HOST`
- `RAILS_SERVE_STATIC_FILES`
- `RAILS_LOG_LEVEL`
- `ACTIVE_JOB_QUEUE_ADAPTER`
- `PUBLIC_INDEXING_ENABLED`
- `APP_VERSION`
- `APP_BUILD_SHA`
- `APP_BUILD_NUMBER`

Database variables:

- `DATABASE_URL`
- or `DATABASE_NAME`, `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`

Mail variables when SMTP is enabled:

- `SMTP_ADDRESS`
- `SMTP_PORT`
- `SMTP_DOMAIN`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_AUTHENTICATION`
- `SMTP_STARTTLS_AUTO`

## SEO Indexing Defaults

Public-page indexing defaults are defined in the Rails environment configs:

- `development`: disabled
- `test`: disabled
- `staging`: disabled
- `production`: enabled

These defaults control both the public-page `<meta name="robots">` tag and the generated `/robots.txt` response.

Deployment override:

- `PUBLIC_INDEXING_ENABLED=true|false`

Compatibility note:

- `ALLOW_INDEXING` is still accepted as a legacy fallback when `PUBLIC_INDEXING_ENABLED` is not present

Important:

- admin pages always stay `noindex, nofollow`
- staging stays non-indexable by default even though it otherwise mirrors production behavior closely

## Build Metadata

The semantic app version lives in:

- `VERSION`

Deploy metadata can also surface:

- build SHA
- build number
- deployed timestamp

This information is written during Capistrano deploys and surfaced in admin/QA diagnostics.

Local development behaves slightly differently:

- on localhost, the footer commit badge and app-version helpers read the current Git SHA at render time when no deploy build number is present
- that means new local commits show up in the footer and `/admin/qa` without restarting the Rails server
- the `+ local` suffix is also based on the current working tree state, so uncommitted changes are reflected live in development

Hosted environments continue to use deploy metadata written at release time rather than recalculating Git state on each request.

## Assets And Static Files

Frontend assets are built through:

```bash
npm run build
```

In hosted environments, make sure:

- assets are precompiled as part of the release flow
- Apache serves `/assets/*` with immutable cache headers
- `RAILS_SERVE_STATIC_FILES=1` is set when Rails should serve static files directly

## Background Jobs

The app uses Active Job and currently keeps a conservative posture around background processing.

Important rule:

- do not treat `:async` as a durable queue backend

Read:

- [Background job policy](BACKGROUND_JOB_POLICY.md)

## Screenshot Tooling

README screenshots are captured with:

- `bin/update_readme_homepage_screenshot`

Useful overrides:

- `README_SCREENSHOT_URL`
- `README_SCREENSHOT_PATH`
- `README_SCREENSHOT_WIDTH`
- `README_SCREENSHOT_HEIGHT`
- `README_SCREENSHOT_BROWSER`

## Read Next

- [Deployment operations](DEPLOYMENT_OPERATIONS.md)
- [Architecture overview](ARCHITECTURE_OVERVIEW.md)
