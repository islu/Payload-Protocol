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
- Change the window mode (maximized, fullscreen) last in `_ready()`. On macOS, the change runs frames and `_process()` before it returns, so each node must exist first. The headless checks skip the window, so they do not find this.

## 2. Text

- Translate each text for the player: `tr("...")` for a literal, `tr(view_value)` for a data name.
- A text with arguments in the view is `{key, args}`. Translate the key and each string argument, then fill in the placeholders.
- Keep constants with text for the player named `*_TEXT`, so that the i18n tool finds them. A `_TEXT` constant can be a string, a triple-quoted string, or a dictionary of strings.
- After a text change, run `task i18n` and translate each new entry in `project/locale/zh_TW.po`. Keep each `{placeholder}` and each `[b]` tag. Use the glossary: hold 貨艙, cargo 貨物, kit 裝備, scrap 廢鐵, dock 碼頭, contract 合約, toll 通行費, clamp 卡榫, sector 星區, shift step 位移, force 撞擊力, credits 信用點.
- Draw a game icon with `CargoDraw.draw_icon()`. Take each color from `Palette`.

## 3. Files

| Folder | Content |
| --- | --- |
| `scenes/main/` | `main.gd`: the title, the screen of each phase, and Esc for the pause. `PhasePanel`: the toll gate and the run end. `Overlay` (the base of a panel on top), `PauseMenu`, `SettingsPanel`, `HowToPlay`, `TutorialPicture` (the picture of each How to Play page) |
| `scenes/common/` | `GameState` (autoload), `DataFiles`, `Settings` (`user://settings.cfg`), `Sound` (plays `audio/sfx/<name>`), `Palette` (all colors), `GameText` (`{key, args}` text), `CargoDraw` (draws a cargo), `CargoChip` (a cargo in a list), `Starfield` |
| `scenes/warp/` | `WarpScreen` (plays the event log, then the arrival report), `FxLayer` (the drawn effects of Section 21) |
| `scenes/station/` | `StationScreen` (the layout, the drag, the drops, the tooltip), `HoldView` (the grid, the cargo, the links, the preview), `DragLayer`, `ClampChip`, `Hints` (the hints of the first runs, SPEC Section 23.3) |

## 4. The Drag

- `StationScreen` owns the drag: `_drag` is `{kind, id, rot, grab, press, held}`. `_input()` follows the mouse, and rotates with a right click or R.
- Two ways to move (SPEC Section 8.2): a release after a drag drops the cargo. A release closer than `CLICK_DISTANCE` to the press is a click: `held` becomes true, and the next press drops it. `_ignore_release` eats the release of that press.
- After a click drop of a cargo from the dock (`from_dock` and `held`), `_pick_next()` picks up the next dock cargo (SPEC Section 8.2). Use `_drop_at(position)` in a check: the headless mouse does not move.
- "Load all" calls `GameState.load_all()`. The scene does not search for places.
- `HoldView` draws the front wall of the first step (`front_wall` of the view) and a jolt icon on each cargo with `jolt_risk` (SPEC Section 12.3).
- A rotation in place that does not fit moves the cargo 1 cell (`Run.ROTATE_KICKS`). The scene only calls `GameState.rotate_cargo()`.
- Do not bend the screen in a shader. The mouse must point at the cell that the player sees (SPEC Section 4.2).
- A drop goes to the first target under the mouse: the sell area, the dock, or the hold. A drop anywhere else does nothing.
- The shape of each rotation comes from `rotations` in the cargo view. Do not rotate a shape in a scene.

## 5. The Warp

- `WarpScreen` copies `warp.before` and changes the copy with each slide and reaction of the log. It calculates no result.
- Wait with `_wait(seconds)`. It divides by `speed`, and it stops during the pause menu. Do not use a timer that runs during the pause.
- Call `Sound.play(self, "<name>")` for each event of Section 21. A new name goes in `Sound.NAMES` and in `tools/sfx/make_sfx.py`. Then run `task sfx`. The UI check fails when a name has no file.
- A sound from outside the project replaces the placeholder with the same name. Record it in `docs/assets.md`.
- The shake reads the setting `shake` (SPEC Section 23.1).

## 6. Hints

- `Hints.current(run)` returns the hint to show, from the view and the setting `hints_seen`. A hint that the view cannot show ends with `Hints.done(id)`.
- Start a run with `start_run()` of `main.gd` (or `Hints.run_started()` first). It counts the runs, so that the hints turn off after the first runs.
- The UI check saves `user://settings.cfg` and puts it back at the end. Do the same in each check that writes a setting.

## 7. Checks

- `task test:ui` (`tests/ui_check.tscn`) plays a full run through the screens and calls the station functions (tooltip, marks, drag, warp). Add a call there for each new screen function. It is a scene, so that the autoload `GameState` exists.
- `task smoke` runs the main scene for 5 frames and fails on an error.
- Do not launch the game with a window or take screenshots to verify a change.
