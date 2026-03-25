# QA Training Guide

GotTheKeys is intentionally set up as a practical training target for browser automation and acceptance testing.

## Why This App Works Well For QA Practice

- deterministic demo scenarios live in version-controlled YAML
- success and validation messages are stable and human-readable
- critical UI actions expose stable selectors
- appointment status transitions are visible in the UI
- admin tools let trainers reset and switch scenarios quickly

## Core Entry Points

- Public site: `/`
- Property catalogue: `/properties`
- Search: `/searches`
- Admin login: `/admins/sign_in`
- Admin workspace: `/admin`
- Demo data controls: `/admin/demo-data`
- QA guide: `/admin/qa`

## Baseline Credentials

After `bin/rails db:seed`:

Admins:

- `steven@gotthekeys.com` / `secret`
- `stevenhobbs@meeane.co.uk` / `secret`

Sellers:

- `seller01@acme.com` / `secret`
- `seller02@acme.com` / `secret`
- `seller03@acme.com` / `secret`
- `seller04@acme.com` / `secret`

## Bundled Scenario Packs

### `baseline`

Use when you want the normal happy-path environment.

Contains:

- multiple public listings
- both sale and rental stock
- bookings in `pending`, `confirmed`, `rescheduled`, `cancelled`, `completed`, and `no_show`
- known credentials for admins and sellers

### `fully_booked_day`

Use when you want to test:

- fully booked availability
- conflict handling
- admin agenda and calendar density
- public booking empty/full-slot messaging

### `qa_edge_cases`

Use when you want:

- a booking without a phone number
- long notes and internal notes
- a rescheduled booking
- a property with no public availability

### `high_volume_search`

Use when you want:

- pagination
- sorting
- broader filter combinations
- more list cards for scanning and scraping exercises

## Recommended Training Journeys

### 1. Public Booking Happy Path

1. Load `baseline`.
2. Open `/properties`.
3. Open a property with a visible slot.
4. Submit a viewing request.
5. Assert:
   - success notice
   - appointment reference
   - status timeline is visible

### 2. Admin Confirmation Flow

1. Sign in as an admin.
2. Open `/admin/appointments`.
3. Find a `pending` booking.
4. Confirm it.
5. Assert:
   - status badge changes
   - audit trail shows the transition
   - notification log records an update

### 3. Reschedule Conflict Check

1. Load `fully_booked_day`.
2. Open a fully booked property in the admin appointment book.
3. Attempt to move another booking into an occupied slot.
4. Assert:
   - validation error is shown
   - original booking remains unchanged

### 4. Empty State Coverage

1. Load `qa_edge_cases`.
2. Open the property designed for no public availability.
3. Assert:
   - booking panel shows the empty state
   - no slot links are present

### 5. Demo Data Reset Loop

1. Load `baseline`.
2. Switch to `high_volume_search`.
3. Verify property counts change.
4. Restore `baseline`.
5. Assert the diagnostics panel updates after each reset.

## Stable Selectors

Key selectors currently exposed:

- `data-testid="site-header"`
- `data-testid="site-nav"`
- `data-testid="property-card"`
- `data-testid="book-viewing-link-<id>"`
- `data-testid="book-viewing-cta"`
- `data-testid="slot-option-<timestamp>"`
- `data-testid="appointment-form"`
- `data-testid="appointment-timeline"`
- `data-testid="admin-sidebar"`
- `data-testid="admin-appointment-row"`
- `data-testid="active-demo-scenario"`

## Helpful Assertions

### Public Flow

- property cards render with price, bedrooms, and CTA
- the booking form requires name and email
- the appointment show page exposes the reference and timeline

### Admin Flow

- quick actions change the status badge
- appointment history appears in the timeline
- customer history is visible on the appointment detail screen
- notification logs capture `sent`, `skipped`, or `failed`

### Demo Data Flow

- diagnostics show current counts
- bundled scenarios preview correctly before apply
- imported YAML must pass validation before it can be applied
- export produces YAML with the current dataset

## Resetting During Training

From the UI:

- sign in as admin
- open `/admin/demo-data`
- choose `Restore baseline` or apply another scenario

From the command line:

```bash
bin/rails db:seed
SEED_SCENARIO=qa_edge_cases bin/rails db:seed
```

## Notes For AI Browser Automation

- Prefer semantic labels and `data-testid` selectors over brittle CSS selectors.
- The scenario data is deterministic enough that you can encode expectations for:
  - record counts
  - status labels
  - demo credentials
  - visible empty states
- The admin diagnostics and notification log pages are useful checkpoints for an agent that needs to verify side effects after a workflow.
