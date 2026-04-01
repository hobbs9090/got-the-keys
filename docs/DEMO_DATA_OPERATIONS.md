# Demo Data Operations

This guide explains how seeded scenarios are managed before, during, and after training sessions.

## What Scenario Packs Are

Scenario packs are deterministic YAML datasets stored under:

- `db/demo_scenarios/`

They exist so the app can be reset into known states repeatedly.

## Bundled Scenarios

The repo currently includes packs such as:

- `baseline`
- `fully_booked_day`
- `qa_edge_cases`
- `high_volume_search`
- `lead_management`
- `deal_progression`
- `listing_lifecycle`
- `documents_and_trust`
- `viewing_operations`

## Seed The Default Baseline

```bash
bin/rails db:seed
```

## Seed A Specific Scenario

```bash
SEED_SCENARIO=fully_booked_day bin/rails db:seed
```

## Verify The Active Scenario

Runtime confirmation points:

- `/admin/demo-data`
- `/admin/qa`

The active scenario indicator is also part of the selector contract:

- `data-testid="active-demo-scenario"`

## Use The Admin Demo-Data Tools

The admin demo-data area is the main trainer surface for:

- previewing a scenario
- restoring the baseline dataset
- checking trainer notes
- reviewing expected assertions
- confirming the typed reset gate

Important behavior:

- resets are intentionally gated to avoid accidental destructive changes
- the dataset swap is meant to replace the current seeded records, not merge casually with them

## Restore Baseline Between Exercises

Preferred reset workflow:

1. Sign in as admin.
2. Open `/admin/demo-data`.
3. Preview `baseline` if needed.
4. Complete the typed confirmation gate.
5. Restore the scenario.
6. Confirm the active scenario indicator changed.

## Export The Current Dataset

From the command line:

```bash
bin/rails runner 'puts DemoData::ScenarioLoader.new.export' > db/demo_scenarios/my_training_pack.yml
```

Use this when you have shaped a useful workshop state and want to turn it into a reusable pack.

## Validate A Scenario Pack

Preview a YAML payload from the command line:

```bash
bin/rails runner 'payload = YAML.safe_load(File.read("db/demo_scenarios/my_training_pack.yml"), permitted_classes: [Date, Time], aliases: false); p DemoData::ScenarioValidator.new.preview(payload)'
```

Use the admin preview flow when you want a trainer-friendly UI check before applying the dataset.

## Editing Guidance For New Packs

Recommended conventions:

- keep the dataset tightly focused on one teaching goal
- use stable, descriptive keys
- prefer relative times where supported so packs do not go stale
- keep credentials simple unless the exercise needs variation

Helpful top-level fields to review after export:

- `key`
- `name`
- `description`

## Reset Expectations For Load And Write Exercises

Be careful with:

- enquiries
- appointments
- offers
- rental applications

If a workshop or tool run generates many writes:

- reseed before the next cohort
- or restore the scenario before comparing results

## Read Next

- [Training session guide](TRAINING_SESSION_GUIDE.md)
- [QA and testing guide](QA_TESTING_GUIDE.md)
