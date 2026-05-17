# Server Maintenance Checklist

## Purpose

Use this checklist for routine staging and production maintenance on the hosted GotTheKeys environments.

It is intentionally practical rather than exhaustive. The goal is to catch the common deployment, server, SSL, database, and acceptance-test issues before they become outages.

## Every Deploy

### Staging

1. Confirm the latest `Deploy Staging` workflow completed successfully.
2. Confirm the matching `staging_acceptance` run completed successfully in `got-the-keys-acceptance`.
3. Open the homepage, catalogue, one property page, and `/admin/qa` on `https://staging.gotthekeys.uk`.
4. Confirm the build/version details shown in QA match the deployed commit.
5. Confirm staging still has `PUBLIC_INDEXING_ENABLED=false`.

### Production

1. Confirm the latest `Deploy Production` workflow completed successfully.
2. Confirm the matching `production_acceptance` run completed successfully in `got-the-keys-acceptance`.
3. Open the homepage, catalogue, one property page, and a footer page such as `/legal`.
4. Confirm the site is serving the expected hostname and TLS certificate.
5. Confirm the production footer or QA/build metadata reflects the deployed commit.

## Weekly

1. Check free disk space on the app host.
2. Check Apache and Passenger are healthy and not repeatedly restarting.
3. Review recent Rails logs for repeated 5xx responses or asset errors.
4. Review database size, failed connections, and slow-query patterns.
5. Confirm backups completed and can be located.
6. Check certificate expiry dates for staging and production hostnames.
7. Review GitHub Actions failures in both repos and clear any stuck deploy or acceptance issues.

## Monthly

1. Review OS package updates and security patches on the host.
2. Review Ruby, Node, and Bundler versions against repo expectations.
3. Review GitHub Actions warnings for deprecated actions or runtime versions.
4. Review npm and gem dependency updates for security fixes.
5. Confirm log growth, backup retention, and old Capistrano releases are under control.

## Configuration Checks

### Required secrets and vars

Production and staging automation should be checked for:

- shared deploy secrets:
  - `DEPLOY_USER`
  - `DEPLOY_REPO_URL`
  - `DEPLOY_HOST_KEY` when pinned host keys are used
  - `ACCEPTANCE_REPO_DISPATCH_TOKEN`
  - `SENTRY_DSN` for Sentry monitoring in staging and production
- staging deploy secrets:
  - `STAGING_DEPLOY_HOST`
  - `STAGING_DEPLOY_TO`
  - `STAGING_DEPLOY_MIRROR_URL`
  - `STAGING_APP_HOST=staging.gotthekeys.uk`
- production deploy secrets:
  - `PRODUCTION_DEPLOY_HOST`
  - `PRODUCTION_DEPLOY_TO`
  - `PRODUCTION_DEPLOY_MIRROR_URL`
  - `PRODUCTION_APP_HOST`
  - `DEVISE_SECRET_KEY`
- environment URL variables:
  - `STAGING_APP_HOST=staging.gotthekeys.uk`
  - `PRODUCTION_APP_HOST`
- database secrets where the target host does not rely on local defaults
- mailer secrets where SMTP is enabled
- Sentry variables where monitoring is enabled: `SENTRY_ENVIRONMENT`, `SENTRY_TRACES_SAMPLE_RATE`
- `PUBLIC_INDEXING_ENABLED`

The acceptance dispatch token matters because both deploy workflows dispatch acceptance checks after deploy.

### Acceptance coverage expectations

Staging should continue to run:

- staging Playwright checks
- staging Lighthouse profile
- `k6` mixed traffic checks

Production should continue to run:

- production-safe Playwright canary checks
- reduced production Lighthouse profile
- `k6` mixed traffic checks

If production acceptance stops starting at all, check reusable-workflow permissions first.

## Performance Checks

1. Confirm `/assets/*` is being served with long-lived cache headers.
2. Confirm HTML, CSS, and JS responses are compressed in the deployed stack.
3. Review Lighthouse trends for sudden regressions in CLS, LCP, or accessibility.
4. Treat repeated Lighthouse `uses-text-compression` warnings as a server/proxy check, not just an app-code issue.

## Useful Manual Checks

Run these when a release feels suspect:

```bash
df -h
free -h
systemctl status apache2
passenger-status
openssl s_client -connect staging.gotthekeys.uk:443 -servername staging.gotthekeys.uk </dev/null 2>/dev/null | openssl x509 -noout -dates
openssl s_client -connect gotthekeys.uk:443 -servername gotthekeys.uk </dev/null 2>/dev/null | openssl x509 -noout -dates
```

If PostgreSQL is remote or managed separately, use the equivalent provider health checks as well.

## When To Escalate

Escalate quickly if any of the following are true:

- acceptance checks fail on both staging and production after a deployment
- TLS is near expiry or serving the wrong host
- disk is close to full
- the app serves 5xx responses or static assets are missing
- build metadata does not match the intended release
- backups are missing or unverified

## Related Docs

- [Deployment operations](DEPLOYMENT_OPERATIONS.md)
- [Environment notes](ENVIRONMENT_NOTES.md)
- [QA and testing guide](QA_TESTING_GUIDE.md)
