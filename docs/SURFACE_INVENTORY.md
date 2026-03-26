# Surface Inventory

This document records the intended top-level app-owned routes after the legacy surface cleanup on March 26, 2026.

Framework-owned endpoints such as Active Storage, Action Mailbox, and Turbo native helpers are intentionally excluded here. This inventory is for the app routes we own and evolve directly.

## Active Product Surfaces

### Public property discovery and booking

- `/`
  Homepage and product positioning.
- `/for_sale`
  Sale catalogue with scoped filters.
- `/for_rent`
  Rental catalogue with scoped filters.
- `/searches`
  Combined search surface across listing scopes.
- `/properties/*`
  Seller listing CRUD plus public property detail pages, listing-readiness workspace, and marketing asset management for photos and floor plans.
- `/properties/:property_id/appointments/new`
  Public appointment request entry point.
- `/appointments/:public_reference`
  Public appointment confirmation/status page.
- `/location/:id`
  Property location detail.

### Authentication and account entry

- `/users/register`
  Public seller registration.
- `/users/sign_in`
  Seller sign-in.
- `/users/password/*`
  Password recovery.
- `/users/unlock/*`
  Unlock flow.
- `/admins/sign_in`
  Admin sign-in.
- `/admins/sign_out`
  Admin sign-out.

### Public content and trust pages

- `/legal`
  Public legal and terms summary.
- `/cookie_policy`
  Cookie and consent policy.
- `/how_it_works`
  Public marketing explainer for the seller journey.
- `/about_us`
  Company/about page.
- `/contact_us`
  Contact and support page.
- `/blog`
  Marketing/editorial content page.
- `/language/new`
  Locale switch endpoint for server-rendered navigation.

### Admin operations

- `/admin`
  Admin dashboard landing page.
- `/admin/bookings`
  Core bookings desk.
- `/admin/booking_configuration`
  Booking rules and lead-time configuration.
- `/admin/properties`
  Admin property review, listing-readiness moderation, and lifecycle transitions.
- `/admin/users`
  Admin seller directory.
- `/admin/notification_logs`
  Notification audit trail.

## Training And Demo Surfaces

- `/admin/demo-data`
  Scenario catalogue plus import/export/restore flows used for deterministic QA resets.
- `/admin/qa`
  QA guide, release metadata, selectors, and known credentials.
- `/coffee`
  Explicit training/demo page retained as a harmless static experiment surface.

## Legacy Compatibility Or Support Surfaces Still Intentionally Retained

- `/baits`
  Legacy compatibility redirect to `/blog`.
- `/members`
  Older admin-only seller directory retained for deep-link/reporting use.
- `/statistics`
  Older admin-only reporting page retained while the newer `/admin` workspace expands.
- `/users/:id`
  Older admin-only seller profile surface linked from `/members`.

## Removed As Orphaned Legacy Surfaces

These surfaces were removed because they had no current route purpose, no meaningful product flow, or no live references in the app:

- `aardvarks`
  Old scaffold-style controller, views, helper, and locale keys with no route and no model.
- `make_an_offer`
  Unrouted stub controller/helper with no view or product flow.
- `account_billing`
  Unlinked placeholder page with only a heading and no live business behaviour.

## Notes For Future Changes

- If you add a new top-level route, document its purpose here or in a more specific QA/product doc.
- If a legacy support surface gains real product importance, move it out of the “legacy compatibility or support” section and give it direct request or system coverage.
