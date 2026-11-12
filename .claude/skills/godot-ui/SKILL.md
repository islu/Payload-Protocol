---
name: godot-ui
description: Conventions of the Payload Protocol scenes and UI (project/scenes) - how a scene reads GameState, sends actions, plays the event log of a warp, shows text for the player, and the folder layout. Use when you write or change a scene, a UI script, or presentation code.
---

# Scenes and UI

## 1. Hard Rules

- A scene reads `GameState.view()` and calls the actions of `GameState`. It keeps no game state.
- A scene does not calculate a game value. If the screen needs a value, add it to `RunView` (see `game-rules`).
- A scene does not change a `Run` directly. Use the actions of `GameState`.
- Connect to `GameState.state_changed` and draw the view again. Do not keep a copy of the view between frames for rules.
- A drag shows the preview of `GameState.can_place()` (SPEC Section 8.3). Do not check the cells in the scene.
- A warp plays `view.run.warp` (the event log) step by step: slides, then hits, then reactions in order (SPEC Section 21). Reactions with the same `cause` chain play 0.15 s apart.
- An action that fails returns an error text. Show it with `tr()` and play the deny sound.
- Make each control work with a mouse and the keyboard (SPEC Section 4.1).

## 2. Text

- Translate each text for the player: `tr("...")` for a literal, `tr(view_value)` for a data name.
- A text with arguments in the view is `{key, args}`. Translate the key and each string argument, then fill in the placeholders.
- Keep constants with text for the player named `*_TEXT`, so that the i18n tool finds them.

## 3. Files

| Folder | Content |
| --- | --- |
| `scenes/main/` | `main.gd`: it shows the screen of the phase. `phase_panel.gd`: the simple arrival, toll, and end panel until those screens exist. |
| `scenes/common/` | `GameState` (autoload), `DataFiles`, `Palette` (all colors), `GameText` (`{key, args}` text), `CargoDraw` (draws a cargo), `CargoChip` (a cargo in a list) |
| `scenes/station/` | `StationScreen` (the layout, the drag, the drops, the tooltip), `HoldView` (the grid, the cargo, the links, the preview), `DragLayer`, `ClampChip` |
| `scenes/<screen>/` | One folder for each other screen of SPEC Section 20: `title`, `warp`, `arrival`, `toll`, `end` |

## 4. The Drag

- `StationScreen` owns the drag: `_drag` is `{kind, id, rot, grab}`. `_input()` follows the mouse, rotates with a right click or R, and drops on release.
- A drop goes to the first target under the mouse: the sell area, the dock, or the hold. A drop anywhere else does nothing.
- The shape of each rotation comes from `rotations` in the cargo view. Do not rotate a shape in a scene.

## 5. Checks

- `task test:ui` (`tests/ui_check.tscn`) plays a full run through the screens and calls the station functions (tooltip, marks, drag, warp). Add a call there for each new screen function. It is a scene, so that the autoload `GameState` exists.
- `task smoke` runs the main scene for 5 frames and fails on an error.
- Do not launch the game with a window or take screenshots to verify a change.
