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
- Import/export and reset support for saved settings
- Settings UI with preview toggles

## Combat-safe party-to-racials behavior

If the EQOL `party` source targets `CDM Racials`, the addon uses a mirrored absolute anchor instead of a live direct frame anchor. This is intended to avoid protected-action errors when Ayije updates the racials container in combat.

## Installation

1. Copy the `EQOLAyijeAnchor` folder into your WoW `Interface/AddOns` directory.
2. Make sure `EnhanceQoL` and `Ayije_CDM` are installed and enabled.
3. Reload the UI.

## Configuration

- Open the Blizzard settings panel:
  - `Esc -> Options -> AddOns -> EQOL Ayije Anchor`
- Or use the slash command:
  - `/eaya`

## Files

- `Core.lua` - saved-variable handling, import/export, slash command
- `EQOL.lua` - EQOL source/target anchor logic
- `CastBar.lua` - Ayije cast bar anchor logic
- `Options.lua` - settings UI

## Notes

- This addon is written for Retail interface versions listed in `EQOLAyijeAnchor.toc`.
- Runtime validation for WoW combat behavior should still be checked in game after updates to `EnhanceQoL` or `Ayije_CDM`.
