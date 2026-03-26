# Codex Expansion Plan

This plan is for expanding GotTheKeys into a more believable small property application without losing its value as a deterministic QA and training harness.

It is written for Codex to use as an execution brief. The goal is not to build a national property portal. The goal is to make the app feel like a credible boutique sales and lettings platform with strong training affordances.

## Product North Star

GotTheKeys should feel like:

- a modern independent estate and lettings business
- a credible place to browse homes, request viewings, and manage listings
- a believable admin workspace for coordinating leads, viewings, offers, and rental applications
- a deterministic training target with stable selectors, reproducible seed data, and scenario-driven demonstrations

## Guardrails

- Keep the app server-rendered and Rails-first unless there is a clear, measured reason to change that.
- Keep the current shared-host deployment posture unless scale or reliability pain makes a stronger infrastructure move necessary.
- Prefer small vertical slices over broad rewrites.
- Every major product feature should also have an explicit QA/training angle.
- Training-only power tools should stay admin-scoped or QA-scoped, not leak into the public experience.
- Avoid fake enterprise complexity. This should feel like a strong small business product, not a clone of Rightmove or Zoopla.

## Current Baseline

The app already has:

- public property catalogue and property detail pages
- seller authentication and listing CRUD
- public appointment requests and appointment status pages
- admin dashboard, appointment management, booking rules, and notification logs
- deterministic YAML-backed demo scenarios
- an admin demo-data workflow for reset, import, export, and preview

That means the next phase should focus less on basic plumbing and more on believable workflow depth.

## Primary Expansion Themes

### 1. Real Property Operations

Make listings, enquiries, and back-office workflows feel like a genuine sales and lettings product.

### 2. Seller And Landlord Self-Service

Give signed-in users better tools to manage listings, see progress, and understand what needs attention.

### 3. Lead-To-Deal Lifecycle

Extend the app beyond viewing requests into enquiries, offers, applications, and progression.

### 4. QA Harness Superpowers

Preserve deterministic data, stable UI contracts, and trainer-friendly controls as first-class product requirements.

## Recommended Roadmap

Treat the roadmap as sequential by default. Codex can split individual phases into smaller branches, but it should avoid starting later phases before the earlier domain seams are stable.

## Phase 1: Listing Credibility And Seller Workspace

### Product Goals

- Make every listing feel more complete and more realistic.
- Give sellers a more credible place to manage and improve their listings.

### Product Work

- Add a richer listing lifecycle:
  `draft`, `review_pending`, `published`, `under_offer`, `let_agreed`, `sold`, `let`, `withdrawn`
- Add structured property facts:
  tenure, council tax band, furnishing, available from, parking, outdoor space, EPC rating, floor area, deposit, pets allowed, service charge, lease length
- Add listing completeness and publishing rules:
  minimum photo count, floor plan presence, key facts, description quality, contact readiness
- Add seller-facing listing status and checklist surfaces
- Add photo ordering, primary image selection, and brochure-style asset management
- Add admin moderation controls for publishing and withdrawing listings

### QA And Training Work

- Add scenario coverage for `draft`, `review_pending`, `withdrawn`, `under_offer`, and `let_agreed`
- Add stable selectors for listing editor controls, completeness cards, and publish actions
- Add seeded edge cases:
  incomplete listing, no floor plan, no photos, unpublished listing, withdrawn listing

### Exit Criteria

- A signed-in seller can manage a believable listing lifecycle.
- Public listings expose richer key facts without losing the app's clarity.
- Demo scenarios can reliably show complete and incomplete listing states.

## Phase 2: Lead Capture And Enquiry Management

### Product Goals

- Make the site feel like it can handle real demand, not just booking clicks.
- Introduce a clear lead-management story for admins and sellers.

### Product Work

- Add a separate property enquiry flow alongside viewing requests
- Add lead records with statuses such as:
  `new`, `contacted`, `qualified`, `unqualified`, `archived`
- Add an admin lead inbox with assignment, notes, source tracking, and filtering
- Add seller visibility for new enquiries and recent lead activity
- Add acknowledgement emails and internal notifications for new leads
- Add enquiry source types such as:
  brochure request, general enquiry, valuation request, letting enquiry

### QA And Training Work

- Add seeded duplicate leads, invalid emails, empty-phone leads, and spam-like submissions
- Add stable selectors for inbox rows, filters, assignment controls, and status transitions
- Add system coverage for lead capture, triage, and follow-up

### Exit Criteria

- A visitor can enquire about a property without booking a viewing.
- Admins can manage a believable enquiry pipeline.
- Trainers can demonstrate both clean and messy lead scenarios.

## Phase 3: Viewing Operations And Customer Self-Service

### Product Goals

- Make appointments feel more like a real operational system.
- Give customers limited self-service without turning the app into a portal-heavy product.

### Product Work

- Add self-serve reschedule and cancellation through signed links or access tokens
- Add reminder emails and calendar-friendly event attachments
- Add per-property blackout dates and special availability windows
- Add open-house or grouped viewing support
- Add admin calendar improvements:
  filters by property, status, assigned admin, and date range
- Add visit outcomes beyond status changes:
  attended, feedback requested, feedback received

### QA And Training Work

- Add seeded scenarios for conflict attempts, expired links, token misuse, no-show flows, and full-day demand
- Add stable selectors for slot lists, reschedule flows, reminders, and calendar filters
- Add deterministic time-relative scenarios for reminder and reschedule training

### Exit Criteria

- The viewing workflow feels credible from both customer and admin perspectives.
- Trainers can reset and replay full viewing operations scenarios.

## Phase 4: Offers And Rental Applications

### Product Goals

- Extend the product beyond viewings into actual transaction progression.
- Make sale and rental journeys distinct where they should be.

### Product Work

- Add sales offers with amount, notes, status, buyer chain detail, and decision history
- Add rental applications with applicant details, move-in date, affordability notes, guarantor flag, and outcome status
- Add property progression surfaces for:
  offer received, under offer, let agreed, completed, withdrawn
- Add admin boards or filtered indexes for active offers and rental applications
- Add seller-side visibility into offer and application progress

### QA And Training Work

- Add seeded scenarios for:
  rejected offer, withdrawn offer, duplicate applicant, missing guarantor, failed affordability, accepted offer
- Add stable selectors for pipeline boards, state transitions, and decision history
- Add request and system coverage around state-machine transitions

### Exit Criteria

- The app can convincingly represent both a sale pipeline and a rental application pipeline.
- Public listing status and admin progression views stay consistent.

## Phase 5: Documents, Trust, And Operational Realism

### Product Goals

- Add the small details that make the product feel real and usable.
- Improve trust signals without bloating the experience.

### Product Work

- Add document support for brochures, compliance docs, and landlord or vendor attachments
- Add richer office, branch, and agent profile content
- Add activity timelines on listings and lead records
- Add saved searches and optional alerts for buyers and tenants
- Add audit logging for important admin-side actions
- Add stronger public trust cues:
  recently updated, available now, response times, managed by

### QA And Training Work

- Add scenarios for missing documents, stale listings, delayed follow-up, and permission boundaries
- Add accessibility checks and copy parity checks for the most important public and admin flows
- Add downloadable-asset assertions and access-control coverage

### Exit Criteria

- The app feels detailed and credible even in secondary workflows.
- Trainers can demonstrate document, permission, and trust-related edge cases.

## Phase 6: QA Harness Enhancements

### Product Goals

- Strengthen the app's primary role as a training target without making it feel fake.
- Make scenario switching, diagnostics, and curriculum support faster for trainers.

### QA And Training Work

- Expand the admin demo-data workspace into a true scenario operations console
- Add richer scenario metadata:
  intended journey, complexity, risk type, locale coverage, expected counts
- Add one-click reset paths for the most common training packs
- Add a selector contract registry for critical surfaces
- Add a QA diagnostics page that shows:
  active scenario, build metadata, mail delivery mode, job adapter, and seeded personas
- Add curated scenario families:
  happy path, edge cases, high volume, multilingual, accessibility, flaky operator workflow
- Add trainer notes and expected assertions for each bundled scenario

### Exit Criteria

- A trainer can reset, explain, and demonstrate the app quickly.
- The QA-specific value of the app is stronger after each product expansion phase, not weaker.

## Phase 7: Optional Infrastructure And Scale Decisions

Only start this phase when the app's product surface has clearly outgrown the current posture.

### Candidate Decisions

- move from SQLite to PostgreSQL
- adopt a durable background-job backend
- add dedicated image processing and storage strategy
- introduce more robust search if catalogue size and filtering needs justify it

### Important Rule

Do not treat infrastructure modernization as a prerequisite for normal feature growth. Reach for it only when there is real operational pressure.

## Codex Execution Rules

When Codex implements this plan, follow these rules:

- Work in short-lived branches from trunk.
- Prefer one vertical slice per branch.
- Each slice should include:
  data model changes, UI changes, specs, demo scenario updates, and docs updates where relevant
- Do not merge a new workflow unless there is a seeded path to demonstrate it.
- Add stable `data-testid` selectors for new critical UI paths.
- Prefer request specs for server-rendered flows and system specs for multi-step user journeys.
- Update `docs/SURFACE_INVENTORY.md` when routes or major surfaces change.
- Update `docs/BOOKING_ARCHITECTURE.md` when booking-related ownership changes.
- Keep public training hints out of the public UI unless they are framed as legitimate product content.

## Suggested First Six Epics

Implement these first, in order:

1. Listing lifecycle and publish workflow
2. Structured property facts and listing completeness
3. Seller dashboard and listing health surface
4. Property enquiries and lead inbox
5. Customer self-serve reschedule and cancellation
6. Offers and rental applications

## Definition Of Done For Each Epic

An epic is done when all of these are true:

- the workflow is believable from a normal user perspective
- the admin or seller experience is coherent
- the feature has deterministic seeded coverage
- stable selectors exist for the main automation path
- request or system specs cover the core flow
- docs are updated where the surface or architecture changed

## Immediate Next Step

Start with Phase 1 and treat `listing lifecycle plus seller dashboard credibility` as the first major delivery wave. That is the highest-leverage path because it improves the public product, the signed-in seller experience, and the quality of QA training scenarios at the same time.
