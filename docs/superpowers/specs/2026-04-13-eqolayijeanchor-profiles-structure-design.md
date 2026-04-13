# EQOLAyijeAnchor Profiles And Structure Design

Date: 2026-04-13

## Summary

Add named manual profiles to `EQOLAyijeAnchor`, let the user manage them from a dedicated settings page, allow import/export against any named profile, and split the addon into smaller modules by responsibility. The split should follow the good pattern used by `EnhanceQoL`: clear modules with stable roles, not a large monolith and not an over-abstracted framework.

## Context

The addon currently works, but its growth path is poor:

- `EQOL.lua` mixes definitions, validation, frame resolution, anchor math, dirty-state handling, mirrored racials behavior, hooks, and event handling.
- The addon stores a single global configuration, which makes switching between layouts inconvenient.
- Import/export is usable, but it assumes a single config and should become profile-aware with explicit payload metadata.
- The settings UI is long and task-mixed. Anchor editing and profile management are different tasks and should not compete for the same page.

The current combat-safe mirrored `party -> cdm_racials` behavior must be preserved.

## Goals

- Add named profiles with manual switching.
- Support create, rename, duplicate, delete, and switch operations.
- Make profile switching apply immediately when possible.
- Allow import/export for any named profile, not only the active one.
- Split the addon into smaller files by responsibility.
- Keep existing anchor behavior stable except where profile support requires plumbing changes.

## Non-Goals

- No additional slash commands beyond `/eaya`.
- No per-character profile assignment.
- No rewrite into a generic anchoring framework.
- No intentional changes to existing anchor semantics apart from profile-aware storage/access.
- No new UI preview system in this pass.

## User-Facing Design

### Settings Layout

The addon should expose two addon settings categories:

- `EQOL Ayije Anchor`
- `EQOL Ayije Anchor - Profiles`

The anchor page remains focused on EQOL frame anchors and Ayije cast bar settings. It should display the active profile name near the top so the user always knows which profile is being edited.

The profiles page owns all profile management:

- active profile dropdown
- create profile
- rename profile
- duplicate profile
- delete profile
- export selected profile
- import into selected profile

This split reduces UI length and separates editing layout behavior from managing saved configurations.

### Profile Behavior

- Profiles are named and shared across the addon.
- There is always exactly one active profile.
- Creating a profile clones the active profile by default. The first pass should not create empty profiles.
- Renaming rejects empty names and duplicate names.
- Duplicating copies one named profile into a new named profile.
- Deleting is blocked when only one profile remains.
- If the active profile is deleted, the addon switches to a deterministic fallback profile before removing the target profile.
- Switching profiles updates addon state immediately and reapplies anchors immediately when not blocked by combat lockdown.
- If profile switching occurs during combat, the profile becomes active immediately in saved state and runtime state, but protected frame movement still follows deferred reapply after combat.

### Import/Export Behavior

- Export operates on a user-selected profile.
- Import targets a user-selected profile.
- Import replaces exactly that target profile after validation.
- Import does not silently switch the active profile unless the selected import target is already the active profile.
- Payload metadata includes addon identity, payload version, and exported profile name.

## Data Model

Saved variables should migrate to this shape:

```lua
EQOLAyijeAnchorDB = {
    version = 2,
    activeProfile = "Default",
    profiles = {
        ["Default"] = {
            eqol = {
                sources = {
                    -- validated EQOL source configs
                },
            },
            castbar = {
                -- validated cast bar config
            },
        },
    },
}
```

### Migration Rules

- Legacy DB shape:

```lua
EQOLAyijeAnchorDB = {
    eqol = { sources = ... },
    castbar = ...,
}
```

- Legacy data migrates into `profiles["Default"]`.
- `activeProfile` becomes `"Default"`.
- `version` becomes `2`.
- If profile storage already exists, validate and normalize it.
- If the DB is missing or corrupt, rebuild a valid DB with a single `Default` profile.

## Module Structure

Use a responsibility-based split in the addon repo:

- `Core.lua`
  - shared constants
  - shared utility helpers
  - addon bootstrap
  - `/eaya` open-settings command
- `Profiles.lua`
  - DB bootstrap
  - migration to version 2
  - profile CRUD
  - active-profile accessors
  - profile switching
- `Serialization.lua`
  - export/import encode and decode
  - payload validation
  - profile-specific export/import operations
- `EQOLConfig.lua`
  - source definitions
  - target definitions
  - defaults
  - target ordering
  - validation
  - active-profile config accessors and setters
- `EQOLRuntime.lua`
  - frame resolution
  - anchor math
  - dirty-state management
  - apply/deferred apply
  - mirrored `party -> cdm_racials` behavior
- `EQOLHooks.lua`
  - EQOL hooks
  - Ayije hooks
  - event frame and runtime refresh triggers
- `CastBar.lua`
  - validated cast bar config access and setters
  - runtime application
  - existing Ayije cast bar hook behavior
- `Options.lua`
  - shared settings helpers
  - shared popup helpers
  - category registration glue
- `OptionsAnchors.lua`
  - main anchor settings category
- `OptionsProfiles.lua`
  - profile management category

The `.toc` should load modules in dependency order so configuration/state services are available before runtime and options modules.

## Runtime Boundaries

### Profile Service Boundary

All modules should stop reading and writing `ns.GetDB().eqol` and `ns.GetDB().castbar` directly. Instead:

- the profile service owns active-profile lookup
- EQOL config access goes through profile-aware accessors
- cast bar config access goes through profile-aware accessors

This prevents parts of the addon from accidentally bypassing profiles.

### EQOL Boundary

`EQOLConfig.lua` should own pure configuration concerns:

- source and target catalogs
- default builders
- normalization
- validation
- target/source labels and ordering

`EQOLRuntime.lua` should own runtime execution:

- resolving source and target frames
- computing and applying anchors
- storing dirty state and last-known absolute anchors
- preserving mirrored racials behavior

`EQOLHooks.lua` should own integration boundaries:

- installing hooks into EQOL and Ayije
- registering events
- triggering apply/deferred apply based on events

This split keeps special-case anchor behavior in runtime code without polluting definitions and validation.

### Cast Bar Boundary

The cast bar module can remain as a single runtime module, but it must be upgraded so:

- it reads from the active profile
- writes go through validated setters
- options no longer assign directly into the DB table

Existing passthrough behavior for `screen` and `resources` should remain unchanged.

## Serialization Design

Keep the string prefix, but treat it as transport framing rather than the only version marker.

Payload shape:

```lua
{
    meta = {
        addon = "EQOLAyijeAnchor",
        version = 2,
        profile = "Arena",
    },
    data = {
        eqol = {
            sources = {
                -- validated EQOL source configs
            },
        },
        castbar = {
            -- validated cast bar config
        },
    },
}
```

Rules:

- decode first
- validate payload type and metadata
- validate EQOL config
- validate cast bar config
- only then replace the target profile

The imported profile name in metadata is informational. The user-selected target profile controls where the data is written.

## Error Handling

- Profile operations return explicit errors for invalid names, duplicates, missing profiles, or deleting the last profile.
- Invalid import payloads fail before any writes.
- Failed runtime apply due to combat or unresolved frames keeps the existing deferred or last-good-position behavior.
- UI actions should surface concise error text through the addon’s existing print helpers.

## Verification Expectations

Implementation is complete only when all of the following are verified:

- legacy single-config DB migrates to `version = 2` with `Default`
- fresh install creates a valid `Default` profile
- switching profiles updates anchors immediately out of combat
- switching profiles during combat defers protected movement and settles after combat
- create, rename, duplicate, and delete all keep active-profile state coherent
- deleting the active profile switches to a fallback cleanly
- export works for arbitrary named profiles
- import into arbitrary named profiles validates correctly and does not corrupt other profiles
- existing non-profile anchor behavior remains intact
- mirrored `party -> cdm_racials` behavior remains combat-safe

## Rationale

This design delivers both of the user’s priorities in one pass:

- better usability through named manual profiles
- better maintainability through a responsibility-based split

It avoids the two bad extremes:

- bolting profiles onto the current monolithic runtime
- rewriting the addon into an unnecessary generic framework
