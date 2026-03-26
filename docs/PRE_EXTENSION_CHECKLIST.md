# Pre-Extension Checklist

Use this checklist before starting a major feature expansion.

The goal is not to “perfect” the app first. The goal is to remove the few things most likely to slow down or destabilize a larger next phase.

## Exit Criteria

Treat the app as ready for major extension when all of these are true:

- the test suite has one clear primary style for request and browser behaviour
- obvious legacy or orphaned surfaces have been removed
- common domain objects have reusable factories
- the biggest controller/query growth points have clean seams
- the background-job posture is an explicit choice, not an accident
- the highest-value user journeys have system coverage

## Recommended Order

1. test architecture cleanup
2. legacy surface cleanup
3. factory and test data improvements
4. query/service extraction
5. background-job decision
6. high-value system coverage

## 1. Test Architecture Cleanup

### Tasks

- [x] Decide the primary test shape:
  request specs for server responses and auth/redirect behaviour
  system specs for browser journeys and JavaScript behaviour
  model/service/job/helper specs for unit-level logic
- [x] Migrate remaining controller specs under `spec/controllers/` into request specs.
- [x] Replace broad feature smoke specs under `spec/features/` with focused system specs.
- [x] Remove or rewrite commented-out test files such as `spec/features/visit_pages_zh_spec.rb`.
- [x] Remove skipped placeholder files such as `spec/models/user_spec_old.rb`.
- [x] Add a short README note documenting the preferred spec types for new work.

### Repo Hotspots

- `spec/controllers/`
- `spec/features/`
- `spec/requests/`
- `README.md`

### Done When

- no active controller specs remain for normal app behaviour
- no commented-out spec files remain in the suite
- new contributors can tell where a new test should live without guessing

## 2. Legacy Surface Cleanup

### Tasks

- [x] Run a route/controller/view inventory and mark every public surface as:
  active product surface
  training/demo surface
  orphaned legacy surface
- [x] Remove clearly orphaned code paths, starting with the `aardvarks` surface if it is no longer intentionally part of the app.
- [x] Remove helpers, views, translations, and specs that only support deleted surfaces.
- [x] Confirm every remaining route has a clear purpose in README or QA docs.

### Repo Hotspots

- `config/routes.rb`
- `app/controllers/aardvarks_controller.rb`
- `app/views/aardvarks/`
- `app/helpers/aardvarks_helper.rb`

### Done When

- every top-level route is either intentional product scope or intentional training scope
- no obviously dead scaffold/demo leftovers remain

## 3. Factory And Test Data Improvements

### Tasks

- [x] Add Factory Bot factories for:
  `Property`
  `Appointment`
  `BookingConfiguration`
  `AvailabilityWindow`
  `NotificationLog`
- [x] Add traits for common booking states such as:
  `pending`
  `confirmed`
  `rescheduled`
  `cancelled`
- [x] Add helpers for common date/time setup so tests stop duplicating slot logic.
- [x] Replace repeated hand-built setup in request/service specs with shared factories.

### Repo Hotspots

- `spec/factories/`
- `spec/support/`
- `spec/models/appointment_spec.rb`
- `spec/requests/admin/appointments_spec.rb`
- `spec/services/appointment_notifier_spec.rb`

### Done When

- most booking-related specs can be written without manual record assembly
- common test setup is shorter and more consistent

## 4. Query And Service Extraction

### Tasks

- [x] Extract appointment filtering/calendar query logic from `Admin::AppointmentsController`.
- [x] Extract property catalogue filtering/sorting logic from `PropertiesController`.
- [x] Decide whether each extracted object is a query object, form object, or presenter.
- [x] Add focused specs for the extracted objects before adding more filters/views.

### Repo Hotspots

- `app/controllers/admin/appointments_controller.rb`
- `app/controllers/properties_controller.rb`
- `app/concerns/property_scoped.rb`

### Done When

- controllers mostly orchestrate instead of building queries inline
- adding a new filter or view mode does not require editing large controller actions

## 5. Background-Job Posture Decision

### Tasks

- [x] Decide that the next extension phase stays on `:async` jobs for the current shared-host deployment.
- [x] Document the limitation clearly and keep mission-critical flows off that adapter.
- [x] Record that a durable backend choice is deferred until real operational pain justifies it.
- [x] List likely future job candidates so they follow one policy from the start.

### Repo Hotspots

- `app/jobs/`
- `config/environments/`
- `docs/BACKGROUND_JOB_POLICY.md`
- `docs/NIRVANA_DEPLOYMENT.md`
- `docs/MODERNIZATION_AUDIT.md`

### Done When

- the team has an explicit answer to “what kind of background work is safe to add next?”
- future job work does not depend on unstated infrastructure assumptions

## 6. High-Value System Coverage

### Tasks

- [ ] Add a system spec for:
  public browse -> property detail -> appointment request
- [ ] Add a system spec for:
  admin sign-in -> bookings desk -> confirm or reschedule appointment
- [ ] Add a system spec for:
  language switch persistence across pages
- [ ] Add a system spec for:
  demo scenario restore from the admin area
- [ ] Add one JavaScript smoke path that proves the shared modal/carousel runtime works end to end.

### Repo Hotspots

- `spec/system/` or the chosen browser-spec directory
- `app/javascript/`
- `app/views/shared/_modal.html.erb`
- `app/views/welcome/_hero_carousel.html.erb`

### Done When

- the most important product journeys are protected above the request-spec level
- frontend runtime regressions are more likely to fail in CI before release

## Optional But Worth Considering

- [ ] Add a small “architecture map” doc for the booking domain.
- [ ] Add a deprecation rule for new top-level controller actions without matching request or system coverage.
- [ ] Add simple performance baselines for slowest specs if the suite starts growing quickly.

## Suggested First Pass

If you want the fastest path to a stronger base, start here:

1. migrate remaining controller specs to request specs
2. delete or confirm orphaned legacy surfaces
3. add booking-domain factories

That gives the biggest payoff before major feature extension.
