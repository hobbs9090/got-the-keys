# Booking Domain Architecture

This is a compact map of the booking domain so future feature work has one place to answer three questions quickly:

- where booking state lives
- which classes own the booking rules
- which seams should change when we extend the flow

## At A Glance

```text
Public visitor
  -> AppointmentsController#new/#create
  -> Appointment (pending)
  -> after_commit hooks
  -> AppointmentEvent + AppointmentNotificationJob
  -> AppointmentNotifier
  -> AppointmentMailer + NotificationLog

Admin
  -> Admin::AppointmentIndexQuery
  -> Admin::AppointmentsController#index/show/edit/update/transition
  -> Appointment updates
  -> after_commit hooks
  -> AppointmentEvent + AppointmentNotificationJob
```

## Core Records

- `Property`
  Owns the listing being booked and the property-specific `availability_windows` and `appointments`.
- `Appointment`
  The canonical booking record. Holds customer details, requested and scheduled time, duration, status, public reference, and access token.
- `AppointmentEvent`
  The human-readable audit timeline for booking creation, status changes, reschedules, and note changes.
- `NotificationLog`
  The delivery audit trail for outbound booking emails.
- `BookingConfiguration`
  Global booking rules. This is the singleton source for slot duration, lead time, buffer time, office hours, and open weekdays.
- `AvailabilityWindow`
  Property-specific open windows and blackout periods that override or narrow the default office-hours model.

## Main Request Flows

### Public Booking Flow

1. `AppointmentsController#new` builds a pending appointment shell and loads suggested slots from `Property#next_available_slots`.
2. `AppointmentsController#create` creates the record as `pending` and keeps `scheduled_at` aligned with `requested_time`.
3. `Appointment` validations call `AppointmentAvailability` to confirm the slot is bookable.
4. After commit, `Appointment` records a `created` timeline event and enqueues `AppointmentNotificationJob`.
5. The customer can view the confirmation page through the secure `public_reference` plus `access_token` pair.

Relevant files:

- `app/controllers/appointments_controller.rb`
- `app/models/appointment.rb`
- `app/models/property.rb`
- `app/services/appointment_availability.rb`

### Admin Booking Flow

1. `Admin::AppointmentsController#index` uses `Admin::AppointmentIndexQuery` to build the agenda/day/week/month desk.
2. `show` exposes the timeline and customer history.
3. `edit` and `update` change schedule, notes, or status while attributing the change to the current admin.
4. `transition` is the quick status-change path from the bookings desk.
5. After commit, `Appointment` writes the matching timeline event and enqueues a notification when status or schedule changes.

Relevant files:

- `app/controllers/admin/appointments_controller.rb`
- `app/services/admin/appointment_index_query.rb`
- `app/models/appointment.rb`
- `app/models/appointment_event.rb`

## Where Booking Rules Live

- `BookingConfiguration.current`
  Global defaults for slot duration, lead time, office hours, open weekdays, and buffer minutes.
- `AppointmentAvailability`
  The main scheduling policy object. It decides which future slots are offered and whether a proposed slot is valid.
- `AvailabilityWindow`
  Per-property overrides for special openings and blackouts.
- `Appointment.blocking`
  Only `confirmed` and `rescheduled` appointments block other bookings.

This split is intentional:

- change global booking hours or slot sizing in `BookingConfiguration`
- change overlap, lead-time, or blackout logic in `AppointmentAvailability`
- change one property's availability in `AvailabilityWindow`

## Notifications And Audit Trail

- `AppointmentNotificationJob`
  Active Job boundary used after create and after notification-worthy updates.
- `AppointmentNotifier`
  Delivery service that decides whether to send mail now and always writes a `NotificationLog` row.
- `AppointmentMailer`
  Builds the customer-facing email content and subject.
- `AppointmentEvent`
  Stores the timeline shown to admins and on the secure customer confirmation page.

The current design keeps side effects after commit so booking writes succeed or fail before emails and timeline entries run.

## Invariants To Preserve

- Publicly created appointments start as `pending`.
- `requested_time` and `scheduled_at` should stay synchronized unless a deliberate future change separates them.
- Slot validation only matters for active bookings: `pending`, `confirmed`, and `rescheduled`.
- Only blocking bookings should prevent another slot from being offered.
- Admin-originated changes should keep `admin` attribution so the timeline remains useful.
- New side effects should cross the Active Job boundary instead of being added inline to controllers.

## Extension Guide

- Adding new availability rules:
  Start in `AppointmentAvailability`, then add request/service/model coverage around the new rule.
- Adding new admin filters or calendar views:
  Extend `Admin::AppointmentIndexQuery` before touching controller branching.
- Adding new booking communications:
  Extend `AppointmentNotificationJob`, `AppointmentNotifier`, and `AppointmentMailer` together so delivery and logging stay aligned.
- Adding new timeline events:
  Keep them close to `Appointment` state changes or extract a dedicated domain service if the event logic starts branching heavily.

## First Places To Read

- `app/models/appointment.rb`
- `app/services/appointment_availability.rb`
- `app/controllers/appointments_controller.rb`
- `app/controllers/admin/appointments_controller.rb`
- `app/services/admin/appointment_index_query.rb`
- `app/services/appointment_notifier.rb`
