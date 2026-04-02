# README And Documentation Overhaul Brief

## Goal

Create a complete documentation refresh for GotTheKeys so a new user, trainer, or contributor can understand the app quickly and use it confidently.

This work should do more than polish the existing README. It should redefine the documentation set so the project reads like a complete training package for:

- using the site as a believable house sales and rentals product
- using the app as a QA training target
- running browser automation with Playwright
- checking quality with Lighthouse
- running performance testing with k6
- managing demo data, resets, and training sessions

The output should be strong enough that someone could recreate the README and supporting docs from this brief alone.

## Why This Matters

The current README is useful, but it is carrying too much responsibility at once:

- product overview
- local setup
- architecture summary
- QA positioning
- repo map
- deployment references

That makes it harder to use as:

- a quick project entry point
- a trainer handout
- a user manual
- a testing playbook

The documentation should feel intentional and navigable rather than like one large catch-all page.

## Core Direction

Treat this as a documentation architecture pass, not just a copy-edit pass.

The docs should present GotTheKeys as two things at the same time:

- a believable small estate-and-lettings website
- a deterministic QA training tool

Neither of those truths should undermine the other.

## Required Outcomes

### 1. Rebuild The README

Rewrite `README.md` so it becomes a clean front door rather than a full manual.

The new README should:

- explain what GotTheKeys is in one clear opening section
- make the dual purpose explicit:
  - credible property website
  - QA training harness
- show the most important homepage screenshot near the top
- keep setup instructions practical and current
- point readers into the right docs for deeper tasks
- avoid becoming the only place where important operational knowledge lives

The README should be concise enough to scan, but complete enough to onboard someone new.

### 2. Use Standard Screenshot Formatting

Replace the ad hoc homepage screenshot update wording with a more standard, tidy section.

The screenshot in the `README.md` should:

- use standard fenced bash blocks
- explain the default homepage

Keep this section short and clean.

### 3. Split Documentation Into Logical Multi-Page Docs

Break documentation into proper pages with focused responsibilities.

At minimum, introduce or rewrite docs covering:

- product overview (with the homepage screenshot)
- getting started / local setup
- site user manual
- QA and testing guide
- training-session operations
- demo-data management and reset workflows
- architecture overview
- file structure and repo map
- deployment and release operations
- deployment and environment notes

Do not duplicate large blocks of text between pages unless there is a clear reason.

Prefer:

- a short README
- focused docs under `docs/`
- cross-links between pages

### 4. Add A Real User Manual For The Site

Create documentation that explains how to use the actual site as if it were a real house sale and rental website.

This should cover user-facing workflows such as:

- browsing the homepage and catalogue
- filtering sale and rental listings
- opening a property detail page
- booking a viewing
- sending an enquiry
- making an offer
- submitting a rental application
- using appointment self-service links
- signing in as a seller and managing listings if applicable
- using the admin workspace at a high level if relevant

The tone should treat the product respectfully as a believable boutique property website.

At the same time, the manual should remain honest about the app's real purpose:

- it exists to support repeatable QA and training workflows
- some capabilities are intentionally shaped to support demos, seeded scenarios, and testing

### 5. Add A Dedicated Testing Guide

Create a dedicated section or page on how to use the app for testing.

This should include:

- what makes the app suitable for QA practice
- how deterministic demo scenarios work
- where the stable selectors live
- recommended test journeys
- how to approach Playwright tests and browser automation against the app
- where request specs and system specs fit
- how seeded states help with coverage

This guide should expand the existing QA material rather than just restating it.

### 6. Document Management, Reset, And Trainer Workflows

Add clear documentation for how to manage the app during a training session.

This should include:

- how to seed the app
- how to switch scenarios
- how to restore baseline data
- how to verify what scenario is active
- how to use admin demo-data tools
- how to prepare the app before a session
- how to reset between attendees or exercises
- what common trainer checks should be done before starting

This documentation should make session operations smooth for someone running workshops repeatedly.

### 7. Include Playwright, Lighthouse, And k6 Training Material

Expand the docs so the app can be used as a stronger training package for:

- Playwright
- Lighthouse
- k6

This does not mean promising official framework integrations that do not exist. It means documenting how to use the app effectively with those tools.

At minimum, include:

- why the app is a good target for each tool
- suggested exercises
- suggested routes and journeys to measure
- useful seeded scenarios for each type of exercise
- practical cautions so trainees do not accidentally measure the wrong thing

Examples:

- Playwright:
  - public browsing and booking flows
  - admin login and booking management flows
  - selector strategy
  - stable seeded-data assumptions
- Lighthouse:
  - which public pages are best to audit
  - what scores or categories trainees should focus on
  - what dynamic behavior or third-party dependencies may affect results
- k6:
  - realistic read-heavy scenarios such as homepage, catalogue, and property detail traffic
  - cautious write scenarios such as enquiries or booking submissions
  - environment reset expectations between runs
- avoiding unrealistic load profiles for a training app

### 8. Document File Structure Clearly

Add or improve documentation that explains how the repository is laid out.

This should help a new contributor quickly understand where to look for:

- models
- controllers
- admin code
- views
- JavaScript
- stylesheets
- jobs
- services
- demo-data scenario files
- specs
- deployment config
- custom tasks and scripts

The file-structure documentation should explain the purpose of the main directories, not just list them.

### 9. Document Deployment And Release Workflows

Add clear documentation for how the app is deployed and operated in hosted environments.

This should include the current real deployment posture and related tooling, including:

- Apache + Passenger deployment notes
- Nirvana deployment guidance if that is still the primary hosted path
- the alternative Synology/container deployment path if it is still supported
- Capistrano-related files and how they fit into releases
- environment variables and build metadata expectations where relevant
- asset build/precompile expectations
- any important caveats around SQLite vs PostgreSQL environments

The goal is not to create a giant operations manual, but to make sure the documentation set contains a clear, trustworthy deployment story.

## Suggested Documentation Structure

This is a recommended target structure. Codex can refine the names, but the responsibilities should remain similar.

- `README.md`
  - concise front door
  - screenshots
  - quick setup
  - key links into deeper docs
- `docs/GETTING_STARTED.md`
  - prerequisites
  - install
  - first boot
  - seed/reset basics
- `docs/USER_MANUAL.md`
  - how to use the site like a real estate sales and rentals website
  - key public and signed-in journeys
- `docs/QA_TESTING_GUIDE.md`
  - why the app is good for QA practice
  - selectors
  - scenario-driven testing
  - request/system test orientation
- `docs/TRAINING_SESSION_GUIDE.md`
  - how to run a workshop or internal training session
  - prep, reset, and facilitation notes
- `docs/DEMO_DATA_OPERATIONS.md`
  - seeding
  - scenario switching
  - import/export
  - baseline restore
- `docs/FILE_STRUCTURE.md`
  - repo map
  - where major responsibilities live
- `docs/DEPLOYMENT_AND_RELEASES.md`
  - deployment posture
  - Capistrano flow
  - environment/build concerns
- `docs/PLAYWRIGHT_LIGHTHOUSE_K6_GUIDE.md`
  - practical training exercises and usage guidance
- `docs/ARCHITECTURE_OVERVIEW.md`
  - concise architecture map
  - app areas and boundaries

If some current docs already cover part of this well, they can be updated and reused instead of creating duplicates.

## Existing Material To Reuse Carefully

Review the current docs and fold useful material into the new structure:

- `README.md`
- `docs/QA_TRAINING.md`
- `docs/BOOKING_ARCHITECTURE.md`
- `docs/SURFACE_INVENTORY.md`
- `docs/BACKGROUND_JOB_POLICY.md`
- `docs/completed/MODERNIZATION_AUDIT.md`
- `config/deploy.rb`
- `config/deploy/`
- `lib/capistrano/`

Keep what is useful, but reorganize it into cleaner reader-oriented pages. And keep the actualy deployment details generic enough to be useful for other repos. For

## Documentation Principles

### Audience Coverage

The refreshed docs should help:

- first-time repo visitors
- developers contributing to the app
- trainers running workshops
- QA learners using the app for browser automation practice
- people using the app as a realistic target for performance and quality tooling

### Tone

The tone should be:

- practical
- calm
- professional
- trainer-friendly
- honest about the app's intended use

Avoid over-selling the app as a production-scale property portal.

### Accuracy

Only document workflows that actually exist in the current app unless explicitly marking a section as future work.

If a capability is partial or admin-only, say so clearly.

### Structure

Prefer:

- short sections
- descriptive headings
- task-oriented organization
- cross-links between pages
- examples where helpful

Avoid:

- giant walls of prose
- repeated setup instructions in multiple places
- mixing user manual content with deployment content

## README Expectations

The new `README.md` should likely include:

- project name and short positioning statement
- 1 short summary paragraph
- screenshots
- key capabilities
- current stack
- quick start
- where to go next in the docs
- brief note on QA/training purpose

Possible sections:

- `## What GotTheKeys Is`
- `## Why It Exists`
- `## Highlights`
- `## Screenshots`
- `## Updating Screenshots`
- `## Quick Start`
- `## Documentation`
- `## Stack`
- `## Training And Testing`
- `## Deployment`

Codex does not need to use those exact headings, but the README should feel similarly structured.

## User Manual Expectations

The user manual should read like an operator guide for the website itself.

It should explain:

- the main public journeys
- the difference between sale and rental flows
- how viewing requests behave
- how self-service appointment management works
- what sellers can do
- what admins can do

It should be usable as:

- a walkthrough handout
- a trainer reference
- a “pretend this is a real agency site” guide for exercises

## Testing Guide Expectations

The testing guide should explain how this app supports testing in practice.

Include topics such as:

- deterministic data and why it matters
- stable selectors and where to find them
- common happy-path and edge-case journeys
- public vs admin test surfaces
- when to use request specs vs system specs vs external browser automation
- using scenario packs to control complexity

## Playwright / Lighthouse / k6 Expectations

The tooling guide should include realistic exercises and boundaries.

### Playwright

Cover:

- suggested end-to-end journeys
- login handling
- selectors and resilient assertions
- training-friendly scenarios
- keeping tests stable with scenario resets

### Lighthouse

Cover:

- best pages to audit
- repeatable setup before measuring
- what is likely to influence scores
- how to use it as a learning tool rather than a vanity-score exercise

### k6

Cover:

- which routes are safe and useful for load tests
- which write flows should be used cautiously
- seeded data reset advice after write-heavy tests
- how to keep performance training realistic for this Rails app

## Demo And Reset Operations Expectations

The operational docs should make it easy to:

- run `bin/rails db:prepare`
- seed the default scenario
- seed a named scenario
- switch via admin demo-data tools
- restore baseline
- validate scenario state before class
- recover from a messy training run

Include both UI-driven and command-line-driven paths where they exist.

## File Structure Expectations

The file-structure documentation should explain the repo in a way that is useful for both contributors and trainers.

Cover areas such as:

- `app/models`
- `app/controllers`
- `app/controllers/admin`
- `app/views`
- `app/javascript`
- `app/assets/stylesheets`
- `app/services`
- `app/jobs`
- `db/demo_scenarios`
- `spec/requests`
- `spec/system`
- `config/deploy.rb`
- `config/deploy/`
- `lib/capistrano`
- `lib/tasks`
- `script/`

The emphasis should be on purpose and navigation, not just inventory.

## Deployment Expectations

The deployment docs should explain the real supported deployment story in plain language.

Include:

- what the recommended deployment path is today
- how Capistrano fits into deployment and release management
- where Capistrano configuration lives
- how build metadata and versioning are surfaced
- what to do about asset builds and precompilation
- which environments use SQLite and which use PostgreSQL if that distinction still applies
- where Apache + Passenger specifics are documented
- whether the Synology/container route is current, fallback, or legacy

If the current deployment docs are split across multiple files, the new docs should make the entry points clearer.

## Nice-To-Have Additions

Codex should also consider including:

- a short “Which doc should I read?” map
- a sample training agenda for a 60 to 90 minute session
- recommended exercise progression:
  - public browsing
  - booking flow
  - admin flow
  - Playwright exercise
  - Lighthouse audit
  - k6 exercise
- a troubleshooting section for common setup or reset problems
- a short glossary for app-specific concepts like scenario packs, baseline, seller workspace, and self-service appointment links
- a short release checklist for docs, assets, seeds, and deployment sanity checks

These are optional, but desirable if they improve completeness without bloating the docs.

## Constraints

- Keep the app's real implementation and current workflows authoritative.
- Do not invent APIs, features, or integrations that do not exist.
- Do not turn the README into a giant duplicated version of the docs.
- Preserve useful existing deployment and architecture information, but move it into better places where needed.
- Keep the documentation maintainable by future contributors.
- Keep deployment and Capistrano documentation accurate to the current repo and supported hosting story.

## Acceptance Criteria

- `README.md` is rewritten as a clear front door document
- screenshot update instructions use a clean standard format
- documentation is split across logical multi-page docs
- there is a credible user manual for using the site like a real property website
- there is a dedicated testing guide
- there is clear documentation for seeding, resetting, and managing training sessions
- there is practical training guidance for Playwright, Lighthouse, and k6
- there is clear documentation for file structure and repo navigation
- there is clear documentation for deployment and release workflows, including Capistrano
- docs stay truthful to the app's actual purpose as a QA training tool
- cross-links between README and docs are clear and useful

## Suggested Codex Prompt

Use the following prompt when implementing this later:

```text
Refresh the README and documentation for GotTheKeys so the project reads like a complete, well-structured training package.

Context:
- Repo: /Users/steven/Source/GitHub/rails_got_the_keys
- Current README is carrying too much product, setup, architecture, and QA material in one file
- The app is both:
  - a believable small property sales/rentals website
  - a deterministic QA training harness
- Existing useful docs include:
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/NIRVANA_DEPLOYMENT.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/SYNOLOGY_CONTAINER_DEPLOYMENT.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/README.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/QA_TRAINING.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/BOOKING_ARCHITECTURE.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/SURFACE_INVENTORY.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/docs/BACKGROUND_JOB_POLICY.md
  - /Users/steven/Source/GitHub/rails_got_the_keys/config/deploy.rb
  - /Users/steven/Source/GitHub/rails_got_the_keys/config/deploy/
  - /Users/steven/Source/GitHub/rails_got_the_keys/lib/capistrano/

Goal:
Create a complete documentation refresh that:
- rebuilds README.md as a concise, clear front door
- splits deep documentation into logical pages under /docs
- includes a proper user manual for using the site like a real property website
- includes a dedicated guide for using the app as a QA/testing target
- includes clear operations docs for seeding, resetting, and managing training sessions
- includes practical training guidance for Playwright, Lighthouse, and k6
- includes clear documentation for file structure, deployment, and Capistrano/release flows

Requirements:
1. Rewrite /Users/steven/Source/GitHub/rails_got_the_keys/README.md
   - Keep it concise and scannable
   - Make the dual purpose of the app explicit
   - Keep screenshots near the top
   - Include a standard `Updating Screenshots` section with fenced bash commands
   - Move deep operational detail into focused docs instead of leaving everything in README

2. Split the documentation into focused pages
   - Introduce or update docs for:
     - getting started
     - user manual
     - QA/testing guide
     - training-session operations
     - demo-data management/reset workflows
     - architecture overview
     - file structure / repo map
     - deployment and release workflows
     - Playwright/Lighthouse/k6 guidance
   - Reuse and reorganize existing material where it helps
   - Avoid large duplicated blocks across pages

3. Add a real user manual
   - Explain how to use the site as if it were a genuine boutique house sales and rentals website
   - Cover browsing, filtering, property details, viewing requests, enquiries, offers, rental applications, appointment self-service, and relevant signed-in/admin flows that actually exist
   - Stay truthful that the app's real purpose is QA training and repeatable demos

4. Add a dedicated testing guide
   - Explain why the app works well for QA practice
   - Cover deterministic scenarios, stable selectors, public/admin journeys, and recommended test exercises
   - Explain where request specs, system specs, and external browser automation fit

5. Add trainer and reset operations docs
   - Cover setup before a session
   - Cover seeding, named scenarios, admin demo-data workflows, restoring baseline, and checking active state
   - Make it easy for someone to run repeated workshops with reliable resets

6. Add Playwright, Lighthouse, and k6 guidance
   - Do not invent integrations that do not exist
   - Explain how to use the app effectively with those tools
   - Include suggested routes, exercises, constraints, and reset guidance
   - Keep Lighthouse guidance focused on repeatable audits
   - Keep k6 guidance realistic for a training app and be careful around write-heavy flows

7. Add file structure and deployment documentation
   - Explain where major responsibilities live in the repo
   - Make the repo map useful to new contributors
   - Document the supported deployment story, including Apache + Passenger, Nirvana, any supported Synology/container route, and Capistrano-based release flow
   - Explain where deployment config lives:
     - /Users/steven/Source/GitHub/rails_got_the_keys/config/deploy.rb
     - /Users/steven/Source/GitHub/rails_got_the_keys/config/deploy/
     - /Users/steven/Source/GitHub/rails_got_the_keys/lib/capistrano/
   - Mention asset build/precompile expectations, version/build metadata, and any environment/database differences that matter

Implementation expectations:
- Keep docs practical, trainer-friendly, and easy to scan
- Use cross-links between README and docs
- Preserve important existing technical truth, but reorganize it into cleaner information architecture
- Do not make README a giant duplicate of the docs
- Make deployment and Capistrano docs trustworthy and aligned with the actual repo
- Verify that documented flows match the actual app behavior

Acceptance criteria:
- README is a strong front door
- screenshot instructions are cleanly formatted
- docs are split into logical pages
- there is a useful user manual
- there is a useful QA/testing guide
- there are clear trainer/reset operations docs
- there is practical Playwright/Lighthouse/k6 guidance
- there is clear file-structure documentation
- there is clear deployment and Capistrano documentation
- documentation remains honest about the app's purpose as a QA training tool
```
