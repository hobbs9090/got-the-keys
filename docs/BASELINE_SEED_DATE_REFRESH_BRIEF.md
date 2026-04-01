# Baseline Seed Date Refresh Brief

## Goal

Update the baseline demo seed data so all dates stay relevant and logically consistent whenever the dataset is refreshed.

The baseline scenario should continue to feel current on any future refresh date without relying on stale hard-coded calendar values.

## Current Problem

The baseline scenario currently mixes:

- relative datetimes such as `today+7d 09:00`
- hard-coded plain dates such as `2026-04-15`

That causes parts of the dataset to age badly over time. Some records move forward with `today`, while others stay fixed in the past or become unrealistic relative to the rest of the seeded activity.

## Relevant Files

- `db/demo_scenarios/baseline.yml`
- `app/services/demo_data/scenario_validator.rb`
- `app/services/demo_data/scenario_activity_generator.rb`
- `app/services/demo_data/scenario_loader.rb`
- `spec/services/demo_data/scenario_loader_spec.rb`
- `spec/services/demo_data/scenario_validator_spec.rb`

## Existing Behavior To Keep In Mind

- Relative datetime parsing already exists for strings such as `today+7d 09:00`
- Plain-date fields such as `available_from` and `move_in_date` are not consistently time-relative yet
- Batch generators already produce relative availability and appointment timing
- Baseline counts and overall scenario shape should remain unchanged unless there is a strong reason to change them

## Desired Outcome

Make the baseline dataset time-relative and internally logical so a refresh at any future date still produces believable data.

This should include coherent timing across:

- properties
- availability windows
- appointments
- enquiries
- offers
- rental applications

## Requirements

### 1. Support Relative Plain Dates

Extend the seed-date parsing so plain-date fields can use relative values as well.

Examples:

- `today+14d`
- `today-3d`

This should work for fields such as:

- `available_from`
- `move_in_date`

Keep existing ISO date parsing working too.

### 2. Remove Stale Fixed Dates From Baseline

Update `db/demo_scenarios/baseline.yml` to remove hard-coded dates where the values should naturally move with time.

At minimum, review and convert:

- fixed `available_from` values
- any other plain dates that should stay relative to the refresh date

### 3. Keep Seeded Activity Chronologically Logical

Ensure the dataset remains believable after refresh:

- upcoming availability stays in the future
- completed and no-show appointments stay in the past
- rescheduled appointments remain coherent
- rental move-in dates remain future-oriented
- listing states still make sense relative to seeded activity

Avoid contradictions such as:

- a completed or stale progression flow paired with impossible future timing
- move-in dates earlier than the related application timing
- availability dates that do not fit the listing state

### 4. Improve Batch-Generated Timing If Needed

Review whether generated enquiries, offers, and rental applications currently land with unrealistic “all created now” timing.

If that makes the baseline scenario feel too artificial:

- add deterministic, relative created/updated timing support
- keep it simple
- avoid introducing unnecessary complexity just for realism
- stick to normal office hours and workdays for dates and times

Only do this if it materially improves the baseline data quality.

### 5. Preserve Baseline Shape

Do not accidentally change:

- property counts
- photo counts
- floor plan counts
- document counts
- appointment/enquiry/offer/rental application counts
- the overall baseline workflow intent

## Suggested Implementation Plan

1. Extend the validator to parse relative plain-date values
2. Convert stale fixed baseline dates to relative values
3. Review generated record timing for realism and adjust only where worthwhile
4. Add or update focused specs
5. Verify the baseline scenario still previews and applies correctly

## Acceptance Criteria

- The baseline scenario contains no stale hard-coded dates for values that should move with time
- Relative plain-date values are supported where needed
- Refreshing the baseline scenario on a future date still produces sensible upcoming and historical records
- The baseline scenario still previews and applies successfully
- The resulting dates remain coherent with listing state and seeded activity
- Relevant specs pass

## Verification

At minimum:

- run focused demo-data specs after the change
- verify the baseline scenario still previews successfully
- verify the baseline scenario still applies successfully
- confirm that upcoming and historical records remain sensible after refresh

## Suggested Codex Prompt

Use the following prompt when implementing this later:

```text
Update the baseline demo seed data so all dates stay relevant and logically consistent whenever the dataset is refreshed.

Context:
- Repo: /Users/steven/Source/GitHub/rails_got_the_keys
- The baseline scenario lives at /Users/steven/Source/GitHub/rails_got_the_keys/db/demo_scenarios/baseline.yml
- Scenario parsing/normalization lives at /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_validator.rb
- Generated activity batches live at /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_activity_generator.rb
- Scenario loading lives at /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_loader.rb
- Current issue: the baseline scenario mixes relative datetimes like `today+7d 09:00` with hard-coded dates like `2026-04-15`, so some seed data will become stale over time

Goal:
Make the baseline dataset time-relative and internally logical so a refresh at any future date still produces believable data.

Requirements:
- Remove hard-coded calendar dates from the baseline scenario where those dates should naturally move with time
- Preserve the existing baseline counts and overall scenario shape
- Keep the seeded data logically consistent across:
  - properties
  - availability windows
  - appointments
  - enquiries
  - offers
  - rental applications
- Avoid introducing dates that drift into the far past or become nonsensical relative to listing state

Implementation expectations:
1. Add support for relative date-only values where needed
   - The validator already parses relative datetimes like `today+7d 09:00`
   - Extend it to also support relative plain dates for fields such as:
     - `available_from`
     - `move_in_date`
   - A syntax like `today+14d` should work for date-only fields
   - Keep existing ISO date parsing working too

2. Update `/db/demo_scenarios/baseline.yml`
   - Replace fixed `available_from` values with relative ones
   - Review the baseline scenario for any other fixed dates that should become relative
   - Keep explicit future/past relationships intact:
     - upcoming availability stays in the future
     - completed/no-show appointments remain in the past
     - rescheduled appointments remain coherent
     - rental move-in dates remain future-oriented and believable

3. Improve generated batch timing where needed
   - Check whether enquiry, offer, and rental application batches currently default to “created right now”
   - If that makes the dataset feel unrealistic, add generated created/updated timing support so these records look staggered rather than all appearing at the same moment
   - If you do this, keep it deterministic and relative to `Date.current` / “today”
   - Do not make the seed logic overly complex just for realism

4. Keep listing states and date logic aligned
   - `under_offer` or accepted-offer style records should feel recent and credible
   - `let_agreed` rental listings should not have impossible move-in timing
   - `available_from` values should make sense for the property type and state
   - Avoid obviously contradictory combinations like:
     - old completed activity paired with impossible future state transitions
     - move-in dates earlier than the related application timing
     - availability dates long after a listing is already effectively progressed

5. Add or update tests
   - Add spec coverage for relative plain-date parsing
   - Add baseline scenario coverage that proves the scenario remains valid and current when loaded now
   - If you add generated timestamps for more record types, add focused tests for that logic
   - Keep existing count expectations intact unless there is a strong reason to change them

Suggested files to inspect/update:
- /Users/steven/Source/GitHub/rails_got_the_keys/db/demo_scenarios/baseline.yml
- /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_validator.rb
- /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_activity_generator.rb
- /Users/steven/Source/GitHub/rails_got_the_keys/app/services/demo_data/scenario_loader.rb
- /Users/steven/Source/GitHub/rails_got_the_keys/spec/services/demo_data/scenario_loader_spec.rb
- /Users/steven/Source/GitHub/rails_got_the_keys/spec/services/demo_data/scenario_validator_spec.rb

Acceptance criteria:
- The baseline scenario contains no stale hard-coded dates for values that should move with time
- Refreshing the baseline scenario on a future date still produces sensible upcoming and historical records
- Relative date-only values are supported for the relevant fields
- The baseline scenario still previews/applies successfully
- The resulting dates remain coherent with listing state and seeded activity
- Relevant specs pass

Verification:
- Run the focused demo-data specs after changes
- Summarize what was changed, especially:
  - which baseline dates were converted to relative values
  - whether new relative date-only parsing was added
  - whether batch-generated records now receive more realistic timestamps
```
