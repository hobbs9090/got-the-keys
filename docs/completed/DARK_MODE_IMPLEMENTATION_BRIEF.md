# Dark Mode Implementation Brief

## Goal

Add a polished dark mode to the GotTheKeys Rails app for both the public site and the admin UI.

The implementation should preserve the current visual identity rather than redesigning the app. Dark mode should feel intentional, maintain the existing blue/orange brand direction, and avoid generic purple-heavy or overly flat dark styling.

## Current State

- Core theme tokens already live in `app/assets/stylesheets/theme.scss`.
- Styles are bundled through `app/assets/stylesheets/application.scss`.
- Many components already consume CSS custom properties such as `--color-ink`, `--color-muted`, `--color-bg`, `--color-surface`, and `--color-line`.
- There is currently no dark mode support.
- There is currently no `prefers-color-scheme` handling.
- There is currently no manual theme toggle or saved theme preference.

This means the app is partway prepared for dark mode, but it still needs:

- a dark token set
- a root theme hook such as `data-theme`
- a small JavaScript preference layer
- a style audit for hard-coded light-only values

## Desired Behavior

Implement all of the following:

- System theme by default
- Manual override with `Light`, `Dark`, and `System`
- Persistence of the manual choice in `localStorage`
- Theme applied at the document/root level using a stable attribute such as `data-theme`

Behavior rules:

- If no manual preference exists, follow the OS theme
- If a manual preference exists, it wins over the system preference
- The selected theme must persist across page reloads

## Scope

Dark mode should apply cleanly to:

- public site chrome
- admin shell
- cards and panels
- forms and inputs
- buttons and badges
- tables
- modals
- property catalogue
- property show page
- shared navigation/header/footer elements

If charts or data visualizations are affected, update them as part of the same pass.

## Constraints

- Use CSS variables/tokens as the main implementation mechanism
- Avoid duplicating large blocks of CSS where token substitution will work
- Preserve the current layout, spacing, and visual language
- Keep contrast accessible
- Avoid unreadable muted-on-muted combinations
- Avoid washed-out surfaces and low-contrast borders
- Do not revert unrelated work already present in the repository

## Recommended Implementation Plan

1. Add a dark token layer in `app/assets/stylesheets/theme.scss`
2. Apply dark tokens via `[data-theme="dark"]`
3. Add `prefers-color-scheme` support for the system default case
4. Add a small theme initialization and preference script in `app/javascript/`
5. Add a compact theme control in shared UI chrome
6. Audit components/pages for hard-coded light-only colors, shadows, gradients, and borders
7. Add or update tests for the new UI hook and preference behavior

## Likely Files To Update

- `app/assets/stylesheets/theme.scss`
- `app/assets/stylesheets/application.scss`
- `app/assets/stylesheets/components/_site_chrome.scss`
- `app/assets/stylesheets/components/_admin_shell.scss`
- `app/assets/stylesheets/components/_modal.scss`
- `app/assets/stylesheets/components/_statistics.scss`
- `app/assets/stylesheets/components/_property_trust.scss`
- `app/assets/stylesheets/pages/_welcome.scss`
- `app/javascript/application.js`
- `app/views/layouts/_header.html.erb`
- `app/views/layouts/_admin_navigation.html.erb`
- `app/views/layouts/application.html.erb`
- `app/views/layouts/admin.html.erb`

Additional files may need updates if hard-coded light styles appear elsewhere.

## Implementation Notes

### Theme Hook

Use a document-level attribute such as:

- `data-theme="light"`
- `data-theme="dark"`
- no forced value when following system theme, or a separate saved preference value such as `system`

Keep the approach simple and predictable.

### Preference Storage

Use `localStorage` to store the user preference.

Suggested values:

- `light`
- `dark`
- `system`

Apply the theme as early as possible to reduce visible theme flash on page load.

### Styling Strategy

Prefer token changes over component rewrites.

Examples of likely token categories to extend:

- page background
- panel/surface backgrounds
- text colors
- subdued text colors
- borders and dividers
- focus rings
- shadows
- primary/secondary button treatments
- hover states

Audit for places that still use literal values like:

- white backgrounds
- dark ink text with no token
- semi-transparent light overlays
- light-only gradients
- shadows tuned only for pale backgrounds

### Public/Admin UI

The public pages and the admin area should both inherit the theme consistently.

Do not style only the public site and leave the admin UI in light mode.

### Toggle UX

The toggle can be compact, but it should be visible and understandable.

Preferred choices:

- `Light`
- `Dark`
- `System`

It does not need to be visually elaborate, but it should feel like part of the app, not a debug control.

## Acceptance Criteria

- The app follows the OS theme by default
- Users can switch between `Light`, `Dark`, and `System`
- The selected theme persists across reloads
- Main public and admin pages remain readable and visually coherent
- No obvious low-contrast text, missing borders, or invisible controls
- Branding still feels like GotTheKeys rather than a generic dark theme
- Relevant tests pass

## Verification

At minimum:

- run targeted specs for any changed request/helper/system/UI behavior
- manually verify the public homepage, property catalogue, property show page, and admin shell
- confirm theme persistence after reload
- confirm system mode respects the browser/OS color scheme

## Suggested Codex Prompt

Use the following prompt when implementing this later:

```text
Implement dark mode for the GotTheKeys Rails app.

Context:
- The app already uses CSS custom properties in app/assets/stylesheets/theme.scss
- Styles are bundled through app/assets/stylesheets/application.scss
- There is currently no dark mode support, no theme toggle, and no prefers-color-scheme handling
- The worktree may already contain unrelated changes, so do not revert or overwrite edits you did not make

Goal:
Add a polished dark mode for both the public site and admin UI.

Requirements:
- Use CSS variables/tokens as the primary mechanism instead of duplicating large blocks of CSS
- Preserve the existing visual identity and layout rather than redesigning the app
- Add support for:
  - system theme by default
  - manual override with Light / Dark / System
  - persistence of the user’s choice in localStorage
- Hook the theme at the document/root level using a stable attribute such as data-theme
- Add the smallest reasonable JS needed for initialization and toggle behavior
- Ensure the theme applies cleanly to:
  - site chrome
  - admin shell
  - cards/panels
  - forms and inputs
  - buttons and badges
  - tables/modals
  - property catalogue and property show pages
- Audit and replace hard-coded light-only colors, borders, gradients, and shadows where needed
- Keep contrast accessible and avoid washed out dark surfaces
- Do not add a generic purple-dark theme; keep the current blue/orange brand feeling
- If charts or data visualizations are affected, update them too

Suggested implementation approach:
1. Add dark and light token sets in theme.scss
2. Apply dark tokens via [data-theme="dark"], with system fallback from prefers-color-scheme
3. Add a small theme controller in app JavaScript
4. Add a compact theme switcher somewhere sensible in the shared header/admin chrome
5. Fix any component/page styles that still assume light backgrounds
6. Add test coverage for the theme preference behavior and any relevant rendered UI hooks

Acceptance criteria:
- The app defaults to following the OS theme when no manual preference is set
- Users can switch between Light, Dark, and System
- The selected theme persists across reloads
- No unreadable text, invisible borders, or broken controls in the main public and admin pages
- Existing layout and branding still feel intentional
- Relevant tests pass

Verification:
- Run targeted specs for any changed request/system/helper/JS behavior
- If you add a toggle, verify it manually in the browser if possible
- Summarize exactly what changed, any residual rough edges, and which files were updated
```
