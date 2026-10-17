# EasyCast

**Click-casting for OctoWoW, using your existing unit frames.**

EasyCast assigns spells and actions to mouse buttons, the mouse wheel and additional keyboard keys. Heal and buff friendly units, attack enemies, and keep the familiar interface instead of replacing it with another set of unit frames.

**Version:** 0.7.38-alpha · **Author:** VanCleef

## Features

- Separate friendly and hostile bindings, with Shift, Ctrl, Alt and their combinations.
- Click-casting on supported existing player, target and party frames.
- Optional world casting, including left/right mouse buttons and two-button running.
- Spell-name entry and drag-and-drop assignment; support for macros, items, action-bar slots and basic target actions.
- Self-cast and bypass modifiers, selectable under Options.
- Named profiles and copying bindings between modifiers within the same target type.
- Compact binding hints: a separate tooltip or icons integrated into the WoW unit tooltip.
- Cooldown displays, range feedback where supported, and indicators for detected self-only spells.
- Independent visibility and positioning for Friendly / World, Hostile / World, Friendly / Unit frames and Hostile / Unit frames.
- Minimap settings button and optional diagnostics.
- Interface languages: English, German, French, Spanish, Brazilian Portuguese, Russian, Korean and Simplified Chinese.

## Installation

1. Download this repository using **Code → Download ZIP** and extract it.
2. Copy the enclosed **EasyCast** folder into your game's `Interface/AddOns` directory.
3. Check that the resulting path is `Interface/AddOns/EasyCast/EasyCast.toc`.
4. Enable EasyCast on the character-selection screen, then enter the game.
5. Open settings with **`/ec`** or the minimap icon.

When updating, close the game and replace the addon folder. Keep your SavedVariables if you want to retain profiles and settings.

## Quick start

### 1. Assign spells

Open **Casting**, choose **Friendly** or **Hostile**, then choose a modifier. Enter a learned spell name exactly as it appears in your game client, or drag a spell icon into a row. Press Enter or leave the field to save it.

The row's type selector also supports macros, items, action-bar slots and target actions. Additional keys, including function keys, can be added to the list. Native WoW raid-target marker bindings retain priority over EasyCast.

To copy a setup, select the destination modifier at the top, select the source beside **Copy from**, then copy. This replaces the destination list, including empty entries, within Friendly or Hostile only.

### 2. Enable world casting

World casting is **off by default**. Enable it under **Options** after configuring your bindings.

- **Left / Right:** cast on a short release. The maximum hold time defaults to 150 ms; the drag threshold defaults to 6 pixels. Both are adjustable.
- **Middle / Mouse 4 / Mouse 5 / keyboard:** cast on release without the left/right duration and movement filter.
- **Mouse wheel:** performs the assigned action on each wheel step.
- **Both mouse buttons:** running takes priority over casting. Release either button to stop; the gesture does not trigger a spell.

For hostile world targets, choose **Select first** or **Direct**. Select first lets a left-click select a different enemy before casting on a subsequent click. Direct selects and casts when the client provides a reliable target identity. Without that identity, selecting the target first remains necessary.

A friendly world unit takes priority when the exact input has a friendly binding. If that input has no friendly binding and an enemy is selected, EasyCast can use the selected enemy instead. Friendly casts restore the previous selection after the cast attempt.

### 3. Set self-cast and bypass modifiers

Under **Options**, choose a self-cast modifier, such as **Shift**, and configure its spells under **Friendly**. Holding it in the world explicitly targets yourself. This also works when the client does not report your own character under the mouse.

Choose a different bypass modifier, such as **Alt**. Hold it **before clicking** to interact with NPCs or use ordinary WoW mouse actions. Leave a binding empty if you want that input to retain its normal behavior whenever possible.

### 4. Adjust tooltips

Choose a shared tooltip style, layout, icon size, spacing and input labels. Then select one of the four friendly/hostile and world/unit-frame contexts to adjust visibility and positioning. Standard WoW unit tooltips can be switched independently for each context.

Range and target restrictions use faded, desaturated spell icons with a small reason indicator. A self-only symbol marks detected self-cast restrictions; range arrows appear when the available data supports them. An unknown range is not treated as a confirmed out-of-range result.

### 5. Save a profile

Use **Options → Profiles** to save a named set of bindings and tooltip settings. Profiles also retain world-casting settings and additional keys.

## Compatibility and limits

EasyCast targets the OctoWoW / Vanilla-style interface (`11200`) and has been tested in OctoWoW 1.18.1. It is designed to fit alongside DragonForgeUI, ShaguTweaks and EasyThreat. Compatibility with every frame replacement or client modification is not guaranteed.

Basic casting has a Vanilla fallback and does not require SuperWoW. Optional client extensions can provide more reliable unit identities, spell IDs and range information; available APIs are detected at runtime.

- **Range without action-bar buttons:** supported when the client exposes a suitable spell-range API. The stock fallback requires a matching spell/rank in an action slot and only applies to the selected target. The action-bar button itself does not have to be visible.
- **Own character in the world:** some clients do not expose a mouseover unit for the player's model. Use the self-cast modifier in that case.
- **Changing game language:** changing the EasyCast menu language does not translate spell names. When genuine spell IDs are available, load the addon in the old game language and log out or reload before changing the game language. Existing foreign-language bindings without a stored ID may need reassignment.
- **Macros and actions:** execution depends on the APIs and restrictions of the client. EasyCast does not automatically retry a failed cast through another execution path.
- **Diagnostics:** detailed reports and experimental test windows currently use German. A logged API return does not by itself prove a successful spell cast.

This is an alpha release. The native two-button movement integration in 0.7.38 has passed in-client testing; other combinations of addons, clients and input settings may behave differently.

## Troubleshooting

| Command | Purpose |
| --- | --- |
| `/ec` | Open settings |
| `/ec probe` | Toggle the live mouse/input display |
| `/ec record on` | Start a new diagnostic recording |
| `/ec record off` | Stop recording and retain the report |
| `/ec report` | Open the diagnostic report |
| `/ec range` | Inspect available range information |
| `/ec keys` | Inspect F-key and target-marker bindings |
| `/ec stop` | Cancel EasyCast gestures and end its owned camera movement; release both mouse buttons |

For a reproducible problem, start a recording, reproduce it briefly, stop recording, then open the report. Include the addon version, client version and relevant addon names in an issue. **Review reports before sharing:** they may contain character names, unit identifiers and your configured bindings. Do not upload your entire SavedVariables or game account folders.

Experimental diagnostic tests are separate from normal casting and may temporarily pause it. Close their windows before testing regular play.

## License

See [LICENSE](LICENSE). You may use, copy, modify and share EasyCast while retaining the notice. Use with official Blizzard-operated World of Warcraft services is not permitted; OctoWoW use is welcome. This is an independent fan project, provided without warranty. Game artwork and fonts remain the property of their respective owners.
