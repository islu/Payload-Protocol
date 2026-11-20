---
name: godot-ui
description: Conventions of the Payload Protocol scenes and UI (project/scenes) - how a scene reads GameState, sends actions, plays the event log of a warp, shows text for the player, and the folder layout. Use when you write or change a scene, a UI script, or presentation code.
---

# Scenes and UI

## 1. Hard Rules

- A scene reads `GameState.view()` and calls the actions of `GameState`. It keeps no game state.
- A scene does not calculate a game value. If the screen needs a value, add it to `RunView` (see `game-rules`). This includes the decisions: read `can_warp`, `mass.state`, `afford`, `can_buy_clamp`, `sell_action`, and the `result` of a reaction. Do not compare credits, masses, or kinds.
- A scene does not change a `Run` directly. Use the actions of `GameState`.
- Connect to `GameState.state_changed` and draw the view again. Do not keep a copy of the view between frames for rules.
- A drag shows the preview of `GameState.drop_preview()` (SPEC Section 8.3): each cell free or not, the cargo in the way, and the nearest valid place. Do not check the cells in the scene.
- A warp plays `view.run.warp` (the event log) step by step: slides, then hits, then reactions in order (SPEC Section 21). Reactions with the same `cause` chain play 0.15 s apart.
- An action that fails returns an error text. Show it with `tr()` and play the deny sound.
- Make each control work with a mouse and the keyboard (SPEC Section 4.1).
- Show each tooltip with `StationScreen.tip_on(control, show, read_only)`: the mouse and the keyboard focus both show it, and `read_only` gives a question mark cursor (SPEC Section 20.10). A card has one tooltip; a cargo image keeps the tooltip of its cargo.
- Do not use `tooltip_text`: the native tooltip shows late and in a different style. Show the details in a `CargoTip` with `show_text()`. At the station, use `StationScreen._show_text_tip()` (or `_env_tip_on()` for the environment). `ModBar` sends the hovered mod to `_set_hover_mod()`, which shows the tip. An overlay that covers the station has its own `CargoTip` (`EventPanel.tip`, `GearButton.tip`).
- Change the window mode (maximized, fullscreen) last in `_ready()`. On macOS, the change runs frames and `_process()` before it returns, so each node must exist first. The headless checks skip the window, so they do not find this.

## 2. Text

- Translate each text for the player: `tr("...")` for a literal, `tr(view_value)` for a data name.
- A text with arguments in the view is `{key, args}`. Translate the key and each string argument, then fill in the placeholders.
- Keep constants with text for the player named `*_TEXT`, so that the i18n tool finds them. A `_TEXT` constant can be a string, a triple-quoted string, or a dictionary of strings.
- After a text change, run `task i18n` and translate each new entry in `project/locale/zh_TW.po`. Keep each `{placeholder}` and each `[b]` tag. Use the glossary: hold 貨艙, cargo 貨物, kit 裝備, scrap 廢鐵, dock 碼頭, contract 合約, payment 還款, leg 還款期, clamp 卡榫, shift step 位移, force 撞擊力, credits 信用點.
- Draw a game icon with `CargoDraw.draw_icon()`. Take each color from `Palette`.

## 3. Files

| Folder | Content |
| --- | --- |
| `scenes/main/` | `main.gd`: the title, the screen of each phase, and Esc and `GearButton` for the pause. `PhasePanel`: the payment screen (the receipt in large numbers, the Paid or Missed `stamp`, a row for each jump, the next leg; `_pay()` counts the credits, shows the stamp, and calls `make_payment()` after `STAMP_WAIT`) and the run end (the score, the `tiles`, a row for each leg, the `ship_card` with Copy). `Overlay` (the base of a panel on top), `EventPanel` (the event on top of the station, SPEC Section 20.8: the speaker portrait from `res://art/speakers`, cut at `FIGURE_HEIGHT` and faded with a shader, at the left of the dialogue box with the choices; `Overlay.panel` has no frame here. After a choice, the reply and Continue take the place of the choices: `hold` makes `StationScreen.held` true before the action, and on `closed` main calls `StationScreen.play_event_effects()`, which pops in the new dock cargo and contracts, then opens the next panel), `ChoicePanel` (the mod choice, on top of the station), `PauseMenu`, `SettingsPanel`, `HowToPlay`, `TutorialPicture` (the picture of each How to Play page, with the cargo images of `PAGE_CARGO`) |
| `scenes/common/` | `GameState` (autoload), `DataFiles`, `Settings` (`user://settings.cfg`), `Sound` (plays `audio/sfx/<name>`), `Palette` (all colors; `trait_color()` and `link_color()`), `Ui` (the shared builders: `label()` translates its text, `panel()`, `panel_style()`, and `clear()`. Use them, not a new StyleBoxFlat or label factory), `GameText` (`{key, args}` text; `trait_line()` is the one lookup of the line of a trait), `CargoDraw` (draws a cargo: its image, or a drawn shape), `CargoArt` (loads `art/cargo/<id>`, and turns the image upright when the cells allow it), `CargoChip` (a cargo in a list), `Starfield`, `FxSheets` (loads `art/fx/<name>`), `TextSize` (the four text sizes of SPEC Section 4.2: use them, not numbers. Set display text with `TextSize.display()`: the UI check `UiCheckText` fails on other sizes), `ModIcon` (the icon of each mod, drawn with lines: a new mod needs a case in `_draw()` and in `ICONS`) |
| `scenes/warp/` | `WarpScreen` (plays the event log, then the arrival report; delivered freight stays with `HoldView.checks`), `ReportPanel` (the arrival report: the cards, the ledger, the credits before and after, the bar of the leg, the pilot. It fits its content: `_fit_cards()` sizes it and sends `fitted`, and `WarpScreen._place_report()` centers the hold and the report as one group), `FxLayer` (the effects of Section 21: pixel art sheets, force numbers, the blast glow, the flash; and the drawn effects of an incident, Section 29.3: `meteor()`, `wave()`, `crack()`) |
| `scenes/station/` | `StationScreen` (the layout, the refresh from the view, the sell area, the input), `ModBar` (the mod bar below the hold: a card with the `ModIcon` of each mod; the mouse on a card sets `HoldView.hover_mod`), `TopBar` (the four groups of the top bar: `JumpDots`, the `Gauge` of the payment and of the mass, and the environment badge with `EnvIcon`), `StationDrag` (the drag and the drops), `CargoTip` (the tip of the station: a cargo with `show_cargo()`, SPEC Section 8.4, and the details of a mod card or a contract card with `show_text()`), `ContractCard` (a contract card of two lines: the client, the total pay, and the mass; then the freight groups ×N and the tags of Loaded N/M, the bonus, VIP, long, and each contract tag (`TAG_TEXT` and `TAG_COLOR`: Black Market is purple). The mouse on it shows the details in the station tip: `show_text_tip()`), `WarpChecklist` (the warp checklist above the Launch button: 4 rows of `view.run.checklist`, with a drawn check or warning mark), `RouteBar` (the route bar above the hold, SPEC Section 20.2: `set_route()` builds the points Depart, Incident, Step1..., Arrive in `points`, and the environment band `env_band`; `go_to()` moves the ship during the warp and adds to `visited`; `step_hovered` marks the front wall of a step. The station and the warp both have one), `RouteCards` (the environment tag and the incident card, used by `RouteBar`), `ShopPanel` (two instances in the right column: `_shop` has the kit cards with their rules and `helps` and Reroll; `_services` with `show_services` has the services with the values now and after), `HoldView` (the grid, the cargo, the links, the preview with the red frames and the ghost (`ghost_cells()`), the hover frame; a cell is `HoldView.CELL`, 100 pixels: use `hold.cell`. With `bay = true`, it draws the shock bay: only the cargo `in_bay`, a padded frame, and the coupling; the station has it as `bay_view` at the left of `hold_view`), `DragLayer`, `PilotFace` (the pixel portrait of the pilot), `ClampChip`, `Hints` (the hints of the first runs, SPEC Section 23.3) |

## 4. The Drag

- `StationDrag` has the drag. `StationScreen` owns it as `_drag` and sends it each input event: `_drag.handle_input()`. `_drag.state` is `{kind, id, rot, grab, press, held, from_dock}`, or empty. Start a drag with `begin_cargo()` or `begin_clamp()`, and stop it with `end()`.
- A drop goes to the area under the mouse: `StationDrag._target()` returns the shock bay first, then the hold. The preview and the drop pass `to_bay` to `GameState` (SPEC Section 31.1).
- Two ways to move (SPEC Section 8.2): a release after a drag drops the cargo. A release closer than `StationDrag.CLICK_DISTANCE` to the press is a click: `held` becomes true, and the next press drops it. `ignore_release` eats the release of that press.
- After a drop of a cargo from the dock (`from_dock`), by a drag or a click, `_pick_next()` picks up the next dock cargo when the setting `pick_next` is on (SPEC Sections 8.2 and 23.1). After a drop over the hold or the shock bay that is not valid, `_keep()` keeps the cargo held and `DragLayer.shake()` shakes it (SPEC Section 8.3). A check that drops a dock cargo must call `_drag.end()` after it.
- Use `_drag.drop_at(position)` and `_drag.update(position)` in a check: the headless mouse does not move. `UiCheckDrag` (`tests/ui_check_drag.gd`) has the checks of the drag feedback.
- The contract cards and the shop show a tooltip with `screen._show_tip(cargo_view)`. It shows nothing during a drag.
- "Load all" calls `GameState.load_all()`. The scene does not search for places.
- `HoldView` draws the front wall of the first step (`front_wall` of the view) and a jolt icon on each cargo with `jolt_risk`: its wall jolt or a press in the first step would make it react (SPEC Section 12.3). `show_front_walls()` marks the walls of the hazard card under the mouse, with no jolt icons after the first step (SPEC Section 20.2).
- `HoldView` draws the bulkhead (`FRAME`), the corner brackets, a deck plate in each cell (`_draw_plate()`), and 2 lights on each wall (SPEC Section 21.6). The warp lights them: `light_wall(wall, color, seconds)` (seconds 0 keeps the color until `lights_off(wall)`), `light_all()`, and `light_near(point, ...)`, with the colors `LIGHT_*`. A light ignores a flash less than `FLASH_GAP` after its last flash. `light_log` keeps each request for `UiCheckHold`. The shock bay has the deck plates and no lights.
- A rotation in place that does not fit moves the cargo 1 cell (`Run.ROTATE_KICKS`). The scene only calls `GameState.rotate_cargo()`.
- Do not bend the screen in a shader. The mouse must point at the cell that the player sees (SPEC Section 4.2).
- A drop goes to the first target under the mouse: the sell area, the dock, or the hold. A drop anywhere else does nothing.
- The shape of each rotation comes from `rotations` in the cargo view. Do not rotate a shape in a scene.

## 5. The Warp

- `WarpScreen` copies `warp.before` and `warp.bay` and changes the copy with each slide and reaction of the log. The shock bay (`_bay`, a child of `_hold`, at the left of the grid) and the route bar (`route_bar`, above the grid; `_place_parts()` places both) are children of `_hold`. The shock bay shares `fades` and `checks` with the hold; a step does not remove cargo that is `in_bay`. It calculates no result. The force number of a hit shows on `cargo`, and of a press on `other` (SPEC Section 10.5). A removed cargo stays in the copy with a fade of 0, so that a line of the report can mark it: the mouse on a group of pieces sends `pieces_hovered` of `ReportPanel`, and `_mark_pieces()` marks them. Replay plays the same log again.
- Wait with `_wait(seconds)`. It divides by `speed`, and it stops during the pause menu. Do not use a timer that runs during the pause.
- Call `Sound.play(self, "<name>")` for each event of Section 21. A new name goes in `Sound.NAMES` and in `tools/sfx/make_sfx.py`. Then run `task sfx`. The UI check fails when a name has no file.
- A new cargo needs an image: add it to `tools/art/cargo_art.json`, then run `task art` and `task import`. The UI check fails when a cargo has no image. A new speaker needs a portrait in `tools/art/speaker_art.json` the same way, with `head`: the height of its head in the source image. `task art` scales each portrait to the same head size.
- Show an effect with a method of `FxLayer`. A new effect goes in `FxLayer.NAMES` and in `tools/fx/fx.json`. Then run `task fx` and `task import`. The UI check fails when a name has no sheet.
- A new effect: first look for one in pixelfx (`node .local/pixelfx/tools/list.mjs <words>`). If none fits, write it in `tools/fx/effects/payload/` with the pixelfx skill (`.local/pixelfx/skills`). The hold is seen from above: an effect has no floor.
- A sound from outside the project replaces the placeholder with the same name. Record it in `docs/assets.md`.
- The shake reads the setting `shake` (SPEC Section 23.1).

## 6. Hints

- The hints are for the things that the tutorial does not teach (SPEC Section 23.3). `Hints.current(run)` returns the first hint of `Hints.ORDER` that the player did not see, for a thing that the station shows. It reads the view and the setting `hints_seen`.
- A station hint ends at the warp: `_on_warp_pressed()` calls `Hints.done(Hints.current(run_data))`. The event and the mod choice show their hint with `Overlay.pilot_hint(id)`, and end it at the pick.
- `UiCheckHints` checks the order and the end of the hints.
- Start a run with `start_run()` of `main.gd` (or `Hints.run_started()` first). It counts the runs, so that the hints turn off after the first runs.
- The UI check saves `user://settings.cfg` and puts it back at the end. Do the same in each check that writes a setting.

## 7. The Station Screen

- `StationScreen` has a small public interface for its helpers (`StationDrag`, `ShopPanel`, `ContractCard`): `view_data`, `run_data`, `hold_view`, `bay_view`, `dock_panel`, `sell_area`, `drag_layer`, `act()`, `add_button()`, `cargo_view()`, `show_tip()`, `show_text_tip()`, `hide_tip()`, `show_sell()`, `show_pilot()`, `set_hover_contract()`, `update_marks()`. A helper does not use a member that starts with `_`.
- `refresh()` builds a list again only when its part of the view changed (`_changed()`). A new list needs its own `_changed()` key with each view value that it reads.
- `_check_sensor_lost()` (in `refresh()`) shows `SENSOR_LOST_TEXT` in the toast when a known fork step is hidden again at the same station (SPEC Section 18.1). `_fork_seen` keeps the leg, the jump, and `known` of the last refresh. `UiCheckSensor` checks it. The text player prints the same warning, and marks a known fork step "(fork, Sensor)".

## 8. The Tutorial Guide

- `TutorialGuide` (`scenes/main/tutorial_guide.gd`) is in its own `CanvasLayer` (layer 5), over the screen and under the overlays. It reads `view.tutorial` (SPEC Section 23.4).
- It draws the screen dark except for `open_rects`. `_has_point()` is false in an open area, so a click goes to the screen below. Only the target works.
- Each screen gives the open areas of a step with `tutorial_rects(step) -> Array[Rect2]`: `StationScreen`, `WarpScreen` (the Continue button), and `PhasePanel` (the Pay button). A new target kind needs a case in the screen and in `Defs.TARGETS`.
- `TutorialGuide.start_run()` starts the tutorial until the setting `tutorial_done` is true. `finish()` sets it and starts a normal run. The Tutorial button of the title calls `GameState.start_tutorial()`.
- In the tutorial, the station shows no hints, and Ctrl+Z does nothing.
- `UiCheckTutorial` plays the tutorial through the screens. `ui_check.gd` sets `tutorial_done` before the other checks.

## 9. Checks

- `task test:ui` (`tests/ui_check.tscn`) plays a full run through the screens and calls the station functions (tooltip, marks, drag, warp). Add a call there for each new screen function. It is a scene, so that the autoload `GameState` exists.
- `task smoke` runs the main scene for 5 frames, starts a run in the text player, and fails on an error.
- In a UI check, call `_finish_tweens()` to end the tweens. Do not wait for a timer in real time. `UiCheckDrag.free_cell()` finds a place for a cargo. `HoldView.cell_global()` gives the global position of a point of the grid.
- To set up a scene for `task shots` or a UI check, use `GameState.set_up(func(run): ...)`. Do not change `GameState._record`.
- Do not launch the game with a window to verify a change. To review the look of the screens, run `task shots`: it saves an image of each screen in `shots/` (not in git). Read the images, then delete `shots/`. Add a screen to `tests/shots.gd` when a new screen needs a review.
