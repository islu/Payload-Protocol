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
| `scenes/main/` | The main scene. It switches the screens. |
| `scenes/common/` | `GameState` (autoload), `DataFiles`, shared helpers |
| `scenes/<screen>/` | One folder for each screen of SPEC Section 20: `title`, `station`, `warp`, `arrival`, `toll`, `end` |

## 4. Checks

- `task smoke` runs the main scene for 5 frames and fails on an error.
- Do not launch the game with a window or take screenshots to verify a change.
