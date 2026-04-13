# EQOLAyijeAnchor Profiles Page Active-Only Design

Date: 2026-04-14
Repo: `/home/qiyu/Documents/wow_addons/AddOns/EQOLAyijeAnchor`
Status: Proposed

## Problem

The current `Profiles` page separates two concepts:

- `selected profile`
- `active profile`

That adds a dedicated `Switch active profile` button and makes the page harder to understand. The user expectation is simpler:

- the dropdown should represent the live active profile
- changing the dropdown should switch the addon immediately
- profile creation and duplication should not silently switch the live layout

## Goals

- Replace the current selected-profile model with a single live `Active profile` model
- Remove the `Switch active profile` button
- Make the dropdown switch the active profile immediately
- Keep `Create profile` and `Duplicate profile` from changing the active profile automatically
- Make all remaining buttons operate on the current active profile
- Keep the change scoped to the `Profiles` page UI and tests

## Non-Goals

- No DB schema changes
- No anchor runtime changes
- No import/export payload format changes
- No slash-command changes
- No support for managing inactive profiles from the `Profiles` page

## Chosen Design

The `Profiles` page uses one profile concept only: the active profile.

The dropdown is renamed to `Active profile`. Selecting a different value immediately calls the existing active-profile switch path and reapplies the addon state, subject to the current combat-safe deferred behavior already implemented elsewhere.

All remaining profile actions act on the current active profile.

This intentionally narrows the page behavior. If the user wants to export, rename, delete, or replace another profile, they first make it active in the dropdown.

## UI Behavior

The page should expose these controls:

- `Active profile` dropdown
- `Create profile`
- `Rename profile`
- `Duplicate profile`
- `Delete profile`
- `Export profile`
- `Import into active profile`

Removed control:

- `Switch active profile`

### Dropdown

Changing the dropdown immediately switches the addon to the chosen profile.

### Create Profile

`Create profile` clones the current active profile into a new profile name.

It does **not** switch the active profile after creation. The newly created profile becomes available in the dropdown for later manual selection.

### Rename Profile

`Rename profile` renames the current active profile.

Because the active profile itself is being renamed, the dropdown updates immediately to the new name.

### Duplicate Profile

`Duplicate profile` copies the current active profile into a new profile name.

It does **not** switch the active profile after duplication.

### Delete Profile

`Delete profile` deletes the current active profile.

Existing safety rules remain:

- the last remaining profile cannot be deleted
- if deletion succeeds, the addon switches to the existing deterministic fallback profile and updates the dropdown

### Export Profile

`Export profile` exports the current active profile.

### Import Into Active Profile

`Import into active profile` replaces the current active profile only.

The control label and popup text should make that explicit so there is no hidden target-selection behavior.

## Code Shape

The change should stay localized to the options UI and tests:

- `OptionsProfiles.lua`
  - remove page-level selected-profile state
  - rename the dropdown to `Active profile`
  - wire dropdown changes directly to active-profile switching
  - remove `Switch active profile`
  - retarget button handlers to `ns.profiles.GetActiveProfileName()`
  - update labels and messages to say `active profile` where relevant
- `tests/test_options.lua`
  - update expectations for the new control set
  - assert dropdown changes switch immediately
  - assert create and duplicate do not auto-switch
  - assert export/import operate on the active profile only

No other module boundaries need to change.

## Risks

### Reduced Inactive-Profile Management

This design intentionally removes the ability to manage an inactive profile directly from the page. That is accepted scope, not a regression.

### UI Text Drift

If labels or popup prompts still say `selected profile`, the page will remain confusing. The implementation should update all visible profile-management wording together.

## Acceptance Criteria

- The `Profiles` page shows one `Active profile` dropdown
- There is no `Switch active profile` button
- Changing the dropdown switches profiles immediately
- `Create profile` and `Duplicate profile` do not switch the active profile automatically
- `Rename profile`, `Delete profile`, `Export profile`, and `Import into active profile` all target the current active profile
- Options tests cover the new behavior
