# Architecture Overview

## Contents

- [Documentation index](INDEX.md)
- [Core stack](#core-stack)
- [Architectural priorities](#architectural-priorities)
- [Main product domains](#main-product-domains)
- [Booking domain](#booking-domain)
- [Background jobs and async posture](#background-jobs-and-async-posture)
- [Hosting posture](#hosting-posture)

GotTheKeys is a server-rendered Rails application with a deliberately simple operational posture.

## Core Stack

- Ruby `3.4.7`
- Rails `8.1.3`
- Turbo Rails
- Foundation Sites plus app-authored SCSS
- `jsbundling-rails` with `esbuild`
- `cssbundling-rails` with `sass`
- Devise for `User` and `Admin`
- Active Job for background boundaries
- SQLite for local/default simple flows
- PostgreSQL for Linux-backed hosted deployments
- Apache + Passenger as the primary hosted posture

## Architectural Priorities

- Keep the UI mostly server-rendered and easy to inspect.
- Keep the app believable as a property product.
- Keep seeded data, trainer resets, and QA diagnostics first-class.
- Avoid infrastructure sprawl unless the product genuinely needs it.

## Main Product Domains

- Properties and catalogue browsing
- Appointments and availability
- Enquiries
- Offers
- Rental applications
- Property documents and media
- Seller workspace
- Admin workspace
- Demo-data and QA diagnostics

## Booking Domain

The booking domain centers on:

- `Property`
- `Appointment`
- `AppointmentEvent`
- `AvailabilityWindow`
- `BookingConfiguration`
- `NotificationLog`

The booking rules, self-service behavior, and notification flow are summarized here rather than split into a separate deep-dive document.

## Service Layer Shape

The app uses `app/services/` for work that should not be buried in models or controllers.

Important service areas:

- `app/services/admin/` for admin query and desk logic
- `app/services/demo_data/` for scenario catalog, loading, validation, export, and generation helpers
- `app/services/qa/` for diagnostics and selector registry support

## Background Work

Background work currently stays conservative.

- Active Job is used as the boundary.
- The current shared-host posture relies on `:async` where appropriate.
- This is intentionally not treated as a durable worker platform.

The practical rule is simple: background jobs are useful boundaries here, but the current shared-host posture does not treat `:async` as a durable queue backend.

## Frontend Runtime

The frontend runtime is bundled through:

- `app/javascript/public_bundle.js`
- `app/javascript/admin_bundle.js`

This split is intentional: most customers only touch the public site, so they should not pay the cost of admin CSS and JavaScript on first load. Admin-only and diagnostics-heavy surfaces should be isolated from the public bundle where practical.

It boots:

- native validation localization
- property listing helpers
- property search filter label switching and sale/rental price-field gating on public pages
- pagination, modal, theme, and admin utility helpers through layout-specific bundles
- admin demo-data performance seed field toggles through `admin_bundle.js`

The styling layer is split between:

- `app/assets/stylesheets/components/`
- `app/assets/stylesheets/pages/`

## Hosted Posture

The main deployment story is:

- Apache + Passenger
- Capistrano-managed releases
- shared-host-friendly assumptions

## Read Next

- [Repository map](REPOSITORY_MAP.md)
- [Deployment operations](DEPLOYMENT_OPERATIONS.md)
- [Environment notes](ENVIRONMENT_NOTES.md)
