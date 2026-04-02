# Training Session Guide

## Contents

- [Documentation index](INDEX.md)
- [Session goals](#session-goals)
- [Before the session](#before-the-session)
- [Recommended session shape](#recommended-session-shape)
- [Reset guidance during training](#reset-guidance-during-training)
- [Trainer checks between exercises](#trainer-checks-between-exercises)
- [Common failure modes](#common-failure-modes)

This guide is for someone running GotTheKeys as a workshop or internal training environment.

## Session Goals

Common workshop goals include:

- teaching public-flow Playwright automation
- teaching admin-flow automation and state checks
- practicing accessibility and Lighthouse audits
- demonstrating deterministic resets and seeded data discipline
- comparing happy paths against edge cases

## Before The Session

Trainer checklist:

1. Confirm the app boots and key public pages render.
2. Sign in as admin and verify `/admin/demo-data` loads.
3. Confirm which scenario should be active before attendees start.
4. Check the selector registry at `/admin/qa`.
5. Verify baseline credentials still work.
6. Decide whether attendees will write against local, staging, or a shared workshop environment.
7. If using email-related flows, confirm whether SMTP or file delivery is active.

Recommended pre-session command flow:

```bash
bin/rails db:prepare
SEED_SCENARIO=baseline bin/rails db:seed
npm run build
bundle exec rspec spec/requests spec/system
```

## Recommended Session Shape

### Phase 1: Product Orientation

- homepage
- catalogue
- property detail
- booking flow

### Phase 2: Deterministic Testing

- explain the active seeded scenario
- show selectors and the admin QA panel
- run a known happy path

### Phase 3: Failure And Edge States

- switch to `fully_booked_day` or `qa_edge_cases`
- explore conflict or empty-slot behavior
- compare assertions against the baseline run

### Phase 4: Reset Discipline

- restore `baseline`
- confirm counts and scenario key changed back
- repeat one short exercise after reset

## Reset Between Attendees Or Exercises

Use the admin demo-data console or the CLI workflow described in [Demo data operations](DEMO_DATA_OPERATIONS.md).

Best practice:

- restore `baseline` between attendee groups
- switch to a non-baseline pack only for a deliberate exercise
- announce the active scenario before asking learners to run assertions

## Common Trainer Checks During A Session

- Does the active scenario key match the exercise?
- Are attendees measuring the same route and seeded state?
- Are they using stable selectors rather than accidental styling hooks?
- Are write flows being reset between runs?
- Are they mixing public and admin credentials correctly?

## Good Exercise Pairings

- `baseline` + public booking happy path
- `fully_booked_day` + slot-conflict handling
- `qa_edge_cases` + empty state and validation checks
- `high_volume_search` + list scanning, pagination, and read-only load exercises
- `lead_management` + enquiry triage and admin history views

## Workshop Risks To Avoid

- letting attendees work against drifting data without reset points
- comparing Lighthouse or k6 runs across different scenario states
- using destructive write flows repeatedly without reseeding
- assuming all properties expose every CTA in every scenario

## End Of Session

Recommended close-out:

1. Restore `baseline`.
2. Confirm the active scenario in `/admin/demo-data`.
3. Save or export any deliberately curated scenario changes.
4. Review failures or flaky assertions while the seeded state is still fresh.

## Read Next

- [Demo data operations](DEMO_DATA_OPERATIONS.md)
- [QA and testing guide](QA_TESTING_GUIDE.md)
