# EQOLAyijeAnchor

`EQOLAyijeAnchor` is a World of Warcraft addon that combines two companion behaviors for `EnhanceQoL` and `Ayije_CDM`:

- anchor EQOL unit frames to selected EQOL, CDM, Blizzard, or screen targets
- anchor Ayije's player cast bar to supported CDM targets while keeping the cast bar locked

## Requirements

- `EnhanceQoL`
- `Ayije_CDM`

The addon declares both as required dependencies in its TOC.

## Features

- EQOL frame anchoring for:
  - player
  - target
  - targettarget
  - focus
  - pet
  - boss
  - party
- Ayije cast bar anchoring to:
  - CDM Essential viewer
  - CDM Utility viewer
  - Ayije's own screen/resources positions
- Named manual profiles with create, rename, duplicate, delete, switch, export, and import support
- Separate settings pages for anchors and profile management
- Settings UI with preview toggles

## Combat-safe party-to-racials behavior

If the EQOL `party` source targets `CDM Racials`, the addon uses a mirrored absolute anchor instead of a live direct frame anchor. This is intended to avoid protected-action errors when Ayije updates the racials container in combat.

## Profiles

`EQOL Ayije Anchor - Profiles` lets you create, rename, duplicate, delete, export, and import named profiles. The main `EQOL Ayije Anchor` page edits the currently active profile, while the separate profiles page manages which profile is selected and which profile is active.

Profile changes apply immediately out of combat. During combat, protected frame movement follows the addon's normal deferred reapply behavior and settles after combat ends.

## Installation

1. Copy the `EQOLAyijeAnchor` folder into your WoW `Interface/AddOns` directory.
2. Make sure `EnhanceQoL` and `Ayije_CDM` are installed and enabled.
3. Reload the UI.

## Configuration

- Open the anchor settings page:
  - `Esc -> Options -> AddOns -> EQOL Ayije Anchor`
- Open the separate profile management page:
  - `Esc -> Options -> AddOns -> EQOL Ayije Anchor - Profiles`
- Or use the slash command:
  - `/eaya`

## Files

- `Core.lua` - saved-variable handling, import/export, slash command
- `Profiles.lua` - profile storage, migration, CRUD, and active-profile switching
- `Serialization.lua` - versioned profile export/import
- `EQOLConfig.lua` - EQOL source/target definitions and validation
- `EQOLRuntime.lua` - EQOL anchoring runtime logic
- `EQOLHooks.lua` - EQOL and Ayije hook/event wiring
- `CastBar.lua` - Ayije cast bar anchor logic
- `Options.lua` - shared settings helpers and page registration
- `OptionsAnchors.lua` - main anchors settings page
- `OptionsProfiles.lua` - dedicated profiles settings page

## Notes

- This addon is written for Retail interface versions listed in `EQOLAyijeAnchor.toc`.
- Runtime validation for WoW combat behavior should still be checked in game after updates to `EnhanceQoL` or `Ayije_CDM`.
