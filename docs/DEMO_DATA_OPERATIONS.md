# Demo Data Operations

## Contents

- [Documentation index](INDEX.md)
- [What the baseline dataset is](#what-the-baseline-dataset-is)
- [Bundled demo dataset](#bundled-demo-dataset)
- [Seed the default baseline](#seed-the-default-baseline)
- [Seed the baseline explicitly](#seed-the-baseline-explicitly)
- [Verify the active scenario](#verify-the-active-scenario)
- [Reset and cleanup notes](#reset-and-cleanup-notes)

This guide explains how the baseline demo dataset is managed before, during, and after training sessions.

## What The Baseline Dataset Is

The baseline dataset is a deterministic YAML seed stored under:

- `db/demo_scenarios/`

It exists so the app can be reset into a known state repeatedly.

## Bundled Demo Dataset

The repo currently ships with:

- `baseline`

## Seed The Default Baseline

```bash
bin/rails db:seed
```

## Seed The Baseline Explicitly

```bash
SEED_SCENARIO=baseline bin/rails db:seed
```

## Verify The Active Scenario

Runtime confirmation points:

- `/admin/demo-data`
- `/admin/qa`

The active scenario indicator is also part of the selector contract:

- `data-testid="active-demo-scenario"`

## Use The Admin Demo-Data Tools

The admin demo-data area is the main trainer surface for:

- previewing the baseline dataset
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

## Validate A Demo Dataset

Preview a YAML payload from the command line:

```bash
bin/rails runner 'payload = YAML.safe_load(File.read("db/demo_scenarios/my_training_pack.yml"), permitted_classes: [Date, Time], aliases: false); p DemoData::ScenarioValidator.new.preview(payload)'
```

Use the admin preview flow when you want a trainer-friendly UI check before applying the dataset.

## Editing Guidance For The Baseline Dataset

Recommended conventions:

- keep the dataset stable and broadly useful for training
- use stable, descriptive keys
- prefer relative times where supported so the baseline does not go stale
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
