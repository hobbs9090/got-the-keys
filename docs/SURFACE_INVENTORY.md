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
  Seller listing CRUD plus public property detail pages, listing-readiness workspace, marketing asset management for photos/floor plans/documents, saved-search capture, and public brochure downloads.
- `/properties/:property_id/enquiries/new`
  Public property-enquiry capture path for brochure requests, general questions, valuation enquiries, and letting follow-up.
- `/properties/:property_id/appointments/new`
  Public appointment request entry point.
- `/properties/:property_id/offers/new`
  Public sales-offer capture path for sale listings.
- `/properties/:property_id/rental_applications/new`
  Public rental-application capture path for rental listings.
- `/appointments/:public_reference`
  Public appointment confirmation/status page.
- `/appointments/:public_reference/manage`
  Public self-service viewing management for secure reschedule and cancellation links.
- `/saved_searches`
  Public saved-search capture endpoint for catalogue alerts and filter snapshots.
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
- `/admin/enquiries`
  Admin lead inbox with filters, assignment, spam flags, and qualification workflow.
- `/admin/offers`
  Admin sales-progression board and offer decision workflow.
- `/admin/rental_applications`
  Admin lettings-progression board and rental-application decision workflow.
- `/admin/booking_configuration`
  Booking rules and lead-time configuration.
- `/admin/properties`
  Admin property review, listing-readiness moderation, lifecycle transitions, documents, and property activity timeline.
- `/admin/users`
  Admin seller directory.
- `/admin/notification_logs`
  Notification audit trail.

## Training And Demo Surfaces

- `/admin/demo-data`
  Scenario operations console with quick resets, metadata-rich previews, import/export, and reset diagnostics.
- `/admin/qa`
  QA guide, release metadata, selector contract registry, scenario families, and seeded-persona diagnostics.
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
