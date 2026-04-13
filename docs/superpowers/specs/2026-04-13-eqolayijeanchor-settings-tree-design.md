# EQOLAyijeAnchor Settings Tree Design

Date: 2026-04-13
Repo: `/home/qiyu/Documents/wow_addons/AddOns/EQOLAyijeAnchor`
Status: Proposed

## Problem

`EQOLAyijeAnchor` currently registers two separate top-level Blizzard Settings addon categories:

- `EQOL Ayije Anchor`
- `EQOL Ayije Anchor - Profiles`

That is not the intended UX. The addon should appear as a single root entry in the Blizzard Settings left sidebar, with a `+` expander and two child pages:

- `Anchors`
- `Profiles`

This should follow the same structural pattern used by addons like `RoyMicroMenu`, which register one root category and then child subcategories under it.

## Goals

- Show exactly one top-level Blizzard Settings entry for the addon:
  - `EQOL Ayije Anchor`
- Show two child pages under that root:
  - `Anchors`
  - `Profiles`
- Keep `/eaya` opening the `Anchors` page
- Preserve the current internal page split:
  - shared options helpers in `Options.lua`
  - anchor UI in `OptionsAnchors.lua`
  - profile UI in `OptionsProfiles.lua`
- Preserve existing behavior inside the pages:
  - previews
  - reset actions
  - profile CRUD
  - selected-profile import/export

## Non-Goals

- No redesign of the anchor controls UI
- No redesign of the profiles UI
- No new slash commands
- No custom fake expandable tree widget
- No additional pages beyond `Anchors` and `Profiles`

## Reference Pattern

Two local patterns informed this design:

1. `RoyMicroMenu`
   - registers one root settings category
   - registers subcategories under that root
   - uses the Blizzard Settings tree for expansion

2. `EnhanceQoL`
   - uses a helper layer around the same parent/child category concept
   - keeps nested organization separate from within-page expandable sections

The `RoyMicroMenu` pattern is the better direct fit here because the requirement is specifically about the Blizzard Settings sidebar tree, not just collapsible sections inside a single page.

## Chosen Design

Use one root addon category and two child subcategories:

- Root category:
  - `EQOL Ayije Anchor`
- Child subcategories:
  - `Anchors`
  - `Profiles`

`/eaya` should continue to open the `Anchors` child page directly.

The root category exists to anchor the settings tree entry. It is not a second copy of the anchors page and should not be treated as a separate addon page in the UX.

## Registration Model

### Root

`Options.lua` should create and register a single root category for the addon. This root becomes the only `Settings.RegisterAddOnCategory(...)` call owned by `EQOLAyijeAnchor`.

Tracked state should include:

- `ns.rootCategory`
- `ns.rootCategoryID`
- `ns.category`
- `ns.categoryID`
- `ns.profileCategoryID`

### Anchors Subcategory

`OptionsAnchors.lua` should register the current anchors page as a child subcategory under the root category.

Visible label:

- `Anchors`

This page continues to contain:

- active-profile display
- EQOL anchor controls
- cast bar controls
- reset actions

### Profiles Subcategory

`OptionsProfiles.lua` should register the current profiles page as a child subcategory under the root category.

Visible label:

- `Profiles`

This page continues to contain:

- selected profile dropdown
- switch active profile
- create
- rename
- duplicate
- delete
- export selected profile
- import into selected profile

## Open Behavior

`ns.OpenSettings()` should continue to open the `Anchors` child page, not the root container and not the `Profiles` page.

This preserves current user expectation and keeps `/eaya` behavior stable.

## Code Shape

The current file split remains valid:

- `Options.lua`
  - shared helpers
  - proxy registration helpers
  - refresh plumbing
  - root category creation
  - category ID tracking
  - `ns.OpenSettings()`
- `OptionsAnchors.lua`
  - builds the `Anchors` subcategory
- `OptionsProfiles.lua`
  - builds the `Profiles` subcategory

No page logic should be moved back into one monolithic file.

## Testing

`tests/bootstrap.lua` and `tests/test_options.lua` should be updated to reflect the parent/subcategory structure.

The options test should assert:

- one root addon category is registered for `EQOL Ayije Anchor`
- `Anchors` exists as a subcategory under that root
- `Profiles` exists as a subcategory under that root
- `/eaya` opens the `Anchors` page
- selected-profile popup and dropdown flows still work from the `Profiles` page

## Risks

### Root Category API Shape

The Blizzard Settings API for parent/subcategory registration differs from the current direct vertical layout registration. The implementation should use the real parent/subcategory API rather than simulate hierarchy by naming.

### Test Harness Drift

The current settings test harness models top-level categories well, but subcategory registration will require explicit parent/child tracking. The harness should be extended carefully so it validates the real tree model rather than a test-only approximation.

## Acceptance Criteria

- The Blizzard Settings sidebar shows:
  - `EQOL Ayije Anchor`
    - `Anchors`
    - `Profiles`
- `EQOL Ayije Anchor - Profiles` no longer appears as a separate top-level addon entry
- `/eaya` opens `Anchors`
- Existing anchor/profile behavior remains intact
- Options tests cover the new tree structure
