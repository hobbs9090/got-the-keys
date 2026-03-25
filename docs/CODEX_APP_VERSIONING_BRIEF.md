# Codex Brief: App Versioning In Footer And Releases

## Context

You are working in the `rails_got_the_keys` repository.

Current relevant files:

- [`app/views/layouts/_footer.html.erb`](/Users/steven/Source/GitHub/rails_got_the_keys/app/views/layouts/_footer.html.erb)
- [`app/helpers/application_helper.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/app/helpers/application_helper.rb)
- [`config/application.rb`](/Users/steven/Source/GitHub/rails_got_the_keys/config/application.rb)
- [`docs/NIRVANA_DEPLOYMENT.md`](/Users/steven/Source/GitHub/rails_got_the_keys/docs/NIRVANA_DEPLOYMENT.md)
- [`README.md`](/Users/steven/Source/GitHub/rails_got_the_keys/README.md)
- [`.github/workflows/deploy-staging.yml`](/Users/steven/Source/GitHub/rails_got_the_keys/.github/workflows/deploy-staging.yml)

The site currently has no app version displayed in the footer.

## Goal

Implement versioning in a way that is clean, maintainable, and suitable for both:

- manual deploys from a development machine
- future or current GitHub-triggered deploys

The footer should show a simple human-friendly version.
Admin or QA-facing surfaces may show richer build metadata.

## Best-Practice Decisions

Use these decisions unless the codebase already has a stronger convention:

1. The app version must come from a single source of truth.
2. Do not hard-code the version directly in the footer partial.
3. Do not auto-increment the version inside the running app.
4. Do not mutate the repo on the production server during deploy.
5. Keep public display simple: semantic version only.
6. Keep technical build metadata available for admin/QA diagnostics.
7. Increment the semantic version in source control as part of the release process, not at runtime.

## Recommended Implementation

### 1. Add A Root `VERSION` File

Add a plain-text file at the repo root:

- [`VERSION`](/Users/steven/Source/GitHub/rails_got_the_keys/VERSION)

It should contain only the semantic version, for example:

```text
1.0.0
```

Use semantic versioning:

- `MAJOR.MINOR.PATCH`

### 2. Load Version Data Into Rails

Expose version information centrally through app config or a small service object.

Preferred shape:

- base version from the `VERSION` file
- optional build metadata from environment variables

Recommended environment variables:

- `APP_VERSION`
  Optional override for the semantic version, mainly for troubleshooting
- `APP_BUILD_SHA`
  Short git SHA or release identifier
- `APP_BUILD_NUMBER`
  CI or deploy run number

Recommended configuration targets:

- `config.x.got_the_keys.version`
- `config.x.got_the_keys.build_sha`
- `config.x.got_the_keys.build_number`

The `VERSION` file should remain the primary source for the semantic version. `APP_VERSION` should be an override, not the default source.

### 3. Add Helper Methods

Add helper methods that keep formatting logic out of the views.

Suggested helper API:

- `public_app_version`
  Returns a string like `v1.3.0`
- `full_app_version`
  Returns a string like `v1.3.0+abc1234` or `v1.3.0+abc1234.42`

Formatting rules:

- public footer: semantic version only
- admin or QA surfaces: semantic version plus build metadata when present
- omit empty metadata cleanly

### 4. Update The Footer

Update [`app/views/layouts/_footer.html.erb`](/Users/steven/Source/GitHub/rails_got_the_keys/app/views/layouts/_footer.html.erb) so the footer includes the public version in a tasteful, unobtrusive way.

Desired output:

- public footer displays something like `v1.3.0`

Keep it visually quiet and responsive.
Do not overwhelm the existing footer copy.

### 5. Expose Build Metadata In Admin Or QA Views

If the app already has a QA guide page, admin dashboard, diagnostics panel, or similar admin surface, add the richer version there.

Desired output:

- `v1.3.0+abc1234`
- or `v1.3.0+abc1234.42`

This helps QA report exactly what build they tested without cluttering the public UI.

If there is no appropriate admin surface yet, add the helper and document it, but keep the public footer implementation first.

## Automatic Increment Strategy

This is the key point:

- do not auto-increment the version from Rails itself
- do not auto-increment on server boot
- do not auto-increment during a manual deploy on the server

Instead, implement automatic incrementing as part of Git-based release automation.

### Recommended Release Process

1. `VERSION` stores the semantic release version.
2. A GitHub workflow or release script bumps that file when you intentionally create a release.
3. The workflow commits the new `VERSION` value and creates a Git tag.
4. Deploy workflows pass build metadata such as `APP_BUILD_SHA` and `APP_BUILD_NUMBER`.
5. The app displays the semantic version publicly and the richer build string in admin/QA contexts.

### Recommended Automation Options

Pick one of these approaches:

#### Option A: Manual Semver, Automatic Build Metadata

This is the simplest and safest starting point.

- manually update the `VERSION` file when cutting a release
- deploy workflow sets:
  - `APP_BUILD_SHA`
  - `APP_BUILD_NUMBER`

This gives:

- stable public version
- automatic per-deploy traceability

#### Option B: GitHub Release Workflow Auto-Bumps Patch Version

Add a GitHub Actions workflow that:

- reads the current `VERSION`
- increments the patch version
- commits the updated `VERSION`
- creates a Git tag

Use this only for a clearly defined release branch or protected branch workflow.

#### Option C: Tag-Driven Releases

Use Git tags as the release trigger:

- create tag `v1.3.0`
- deploy that tag
- app reads `VERSION` for `1.3.0`
- workflow passes SHA/build metadata

This is often the cleanest long-term approach.

## Requirements For Manual Deploys

Manual deploys from a development machine must still work.

That means:

- the app should not depend on GitHub Actions to determine its semantic version
- the `VERSION` file must be enough to render the public footer
- build metadata should be optional

Example manual deploy environment:

```bash
APP_BUILD_SHA=$(git rev-parse --short HEAD) \
DEPLOY_USER=steven \
bundle exec cap production deploy
```

If `APP_BUILD_SHA` is missing, the app should still work and show the semantic version from `VERSION`.

## Requirements For GitHub Deploys

The repo already has GitHub workflow infrastructure.

Codex should make the versioning strategy compatible with future GitHub deployment automation by supporting environment variables such as:

- `APP_BUILD_SHA=${{ github.sha }}`
- `APP_BUILD_NUMBER=${{ github.run_number }}`

If a release workflow is added later, it should update `VERSION` in source control rather than asking Rails to invent a version dynamically.

## UI Guidance

- Keep the public footer subtle.
- Use existing footer typography and spacing conventions.
- Avoid adding noisy labels like `Build:` to the public footer.
- If you add admin/QA version text, it can be slightly more explicit.

## Testing And Documentation

Add or update:

- helper specs for version formatting
- view or request/system coverage that confirms the footer renders the public version
- documentation in [`README.md`](/Users/steven/Source/GitHub/rails_got_the_keys/README.md) explaining:
  - where the version lives
  - how to bump it
  - how build metadata works
- deployment docs in [`docs/NIRVANA_DEPLOYMENT.md`](/Users/steven/Source/GitHub/rails_got_the_keys/docs/NIRVANA_DEPLOYMENT.md) showing optional version metadata environment variables

## Definition Of Done

The work is done when:

- the repo contains a root `VERSION` file
- Rails loads version information from a single central source
- the public footer shows `vX.Y.Z`
- admin or QA-facing surfaces can show richer build metadata
- manual deploys still work without GitHub-specific state
- future GitHub deploys can pass SHA/build number cleanly
- no runtime auto-increment logic exists inside the Rails app
- docs explain the release/versioning process

## Explicit Non-Goals

Do not:

- generate versions based on current date/time
- increment the version every time Passenger restarts
- write back to `VERSION` from production code
- shell out to Git on every request
- hard-code the version directly in the footer partial
