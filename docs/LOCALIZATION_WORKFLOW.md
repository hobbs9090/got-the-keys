# Localization Workflow

English is the source of truth for copy in this repo.

When English strings change, keep the other locales in sync with the generated overlay workflow rather than editing every locale file by hand immediately.

## Files

- Curated locale files stay in `config/locales/`
- Generated fallback overlays live in `config/locales/generated/`
- Locale health logic lives in `lib/ci/locale_health.rb`

## Commands

Sync missing translations from English into generated overlay files:

```bash
bin/i18n_sync_locales
```

Check that all supported locales have coverage for the current English keys and matching interpolation variables:

```bash
bin/i18n_health
```

## Expected Workflow

1. Update the English copy first.
2. Run `bin/i18n_sync_locales`.
3. Review the generated overlay changes in `config/locales/generated/`.
4. Run `bin/i18n_health`.
5. Commit the English copy change together with the generated locale overlay updates.

## Notes

- The generated overlays are intentionally separate from the curated locale files so the repo can absorb English copy changes without constantly reorganizing the hand-maintained translation files.
- When a human translator provides better locale-specific copy later, move that text into the curated locale files and rerun `bin/i18n_sync_locales`. The generated overlay file will shrink automatically once the curated translation exists.
- CI runs `bin/i18n_health`, so missing locale coverage or broken interpolation placeholders will fail the build.
