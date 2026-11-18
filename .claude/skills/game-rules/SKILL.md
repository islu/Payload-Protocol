---
name: game-rules
description: Conventions of the Payload Protocol rules layer (project/rules) and its tests (project/tests) - the file map, Defs constants, the Run actions and error texts, the event log of a warp, determinism, the view, and how to write a rule test with the fixture. Use when you write or change rules, the view, GameState actions, or rule tests.
---

# The Rules Layer (GDScript)

## 1. Hard Rules

- `project/rules` has all game rules and all game state. Its classes extend `RefCounted` or have static functions only.
- Do not use `Node`, scenes, `FileAccess`, `DirAccess`, `Input`, or the screen in `project/rules`.
- Use `int` for all game values. Do not use floats. Convert JSON numbers with `int()` when you read data.
- Use the `RandomNumberGenerator` of the `Run` (`rng` for content, `line_rng` for the pilot). Do not use `randi()` or `randf()`. A shift step uses no random numbers. The direction of a fork step comes from `rng` when the station opens.
- Do not put a hidden value in the view. The direction of a fork step is in the view only when a Sensor is in the hold (SPEC Section 18.1).
- Use the constants of `Defs`. Do not compare with a literal string.
- An action returns `""` when it works, or an error text for the player. A failed action changes nothing. Make each error text a constant that ends in `_TEXT`: the i18n tool collects them.
- Give the spec section in the doc comment of each class and each public function: `## Rotates a cargo in the hold in its place (SPEC Section 8.2).`

## 2. File Map

| File | Content |
| --- | --- |
| `defs.gd` | `Defs`: the fixed strings (kinds, weights, traits, directions, phases, reactions, pieces, bonuses, sides, axes, links, line events, the actions `ACT_*`) and `Defs.delta()` |
| `shapes.gd` | `Shapes`: rotation, size, cells at a place, connected, JSON and view forms |
| `cargo_def.gd`, `cargo.gd` | `CargoDef` (data) and `Cargo` (one cargo in a run): `cells()`, `has()`, `weight()`, `Cargo.next_to()` |
| `contract_template.gd`, `contract.gd` | Contract data, the zone of a bonus, and an offered contract |
| `event_def.gd` | `EventDef`: an event of `data/events/`, its speaker (`data/speakers/`, SPEC Section 20.8), its choices and effects (SPEC Section 26) |
| `catalog.gd` | `Catalog.from_data()`: reads the parsed JSON and checks it (content.md). `errors` has the problems |
| `run.gd` | `Run`: the state, the phases, placement (`ROTATE_KICKS`; `place_cargo(..., to_bay)`; freight in the shock bay gives `BAY_FREIGHT_TEXT`), the shock bay (`bay_size`, `bay_cargo()`, `ship_cargo()`, `shock_bay_offer()`, `buy_shock_bay()`; a cargo is `in_hold`, `in_bay`, or on the dock, and each area has its own cells), clamps, contracts, the shop, the mass (`cargo_mass`, `hold_mass`, `max_mass`, `fuel_fee`, `reinforce_hull`), the hazard of the next jump (`hazard`, `fork_options`), the dock at the warp, the event actions (`event`, `choose_event`, `payment_cut`, `add_contract`) and the mod actions (`mods`, `choose_mod`, `has_mod`; the rules of each mod are in `Shift.force_weight`, `Shift.hit_force` (Shock Floor), `Shift.powers`, `Shift.jolt_force`, `Arrival.cools`, and `Arrival._insurance`; they read the values of the mod data with `cat.mod_value(id, key)`, and `Catalog.MOD_VALUES` lists the values of each mod; `Cargo.within()` is the range of a mod), the environment of the leg (`environment`, `env_value`, `break_limit`; use `run.break_limit()`, not `cat.break_limit()`, in the rules), the incident of the next jump (`incident`), the long contracts on their way (`Contract.carried()`, `jumps_left()`), the pilot lines |
| `route.gd` | `Route`: `make_hazard()` (the shift steps and the fork step, SPEC Section 18), `pick_environment()` (SPEC Section 28.1), `make_incident()` (SPEC Section 29.1). They use the `rng` of the run: keep the order of the calls |
| `station_events.gd` | `StationEvents`: `start_event()`, `choice_error()`, `do_effect()` (SPEC Section 26), `mod_pool()`, `offer_mods()` (SPEC Section 27.1) |
| `shift.gd` | `Shift.step()` (the hold only: the shock bay does not shift; `Run.warp()` puts its cargo views in `warp.bay`): power, slide, hits (`hit_force()` gives the force that a cargo takes from each hit: Cushion and Shock Floor; `_hit()` builds each hit of the log; with the wall jolt of SPEC Section 10.4: a hit with `jolt: true`; with the press of SPEC Section 10.5 (`_press()`): a hit with `press: true`, where `cargo` presses and `other` takes the force. `_still()` gives both to a cargo that did not slide. `first_step_forces()` tries the first step and gives the force of each jolt and press, for `RunView.jolt_risks()`), reactions (each with its lost pay `loss`, its number in the chain `chain` (SPEC Section 21.5), and its `result`: `Defs.RESULT_SCRAP`, `RESULT_REMOVED`, or `RESULT_KEPT`), `Shift.incident()` (the incident before the first step, SPEC Section 29), blast area, shields. It returns the event log of the step |
| `arrival.gd` | `Arrival.arrive()`: spoil, delivery, bonus, breach, the report, the line event |
| `run_record.gd` | `RunRecord`: the seed and each action that worked, as data: `{name: Defs.ACT_*, args}`. `act(name, args)` does and records an action, `apply()` maps a name to its `Run` action, and `actions()` gives the record to save. `undo()` plays the run again from the seed with no last action, back to the arrival at the station (SPEC Section 20.2). |
| `run_view.gd` | `RunView.view()`: the plain data that the UI reads. `hazard()` hides the direction of a fork step unless a Sensor is in the hold. `drop_preview()` and `preview_links()` give the preview of a drag (SPEC Section 8.3). `checklist()` gives the warp checklist (SPEC Section 20.2). The view has the decisions of the screen too: `can_warp`, `mass.state` and each `mass_state` (`Defs.MASS_*`, from `mass_state()`), `afford` for each price and `can_buy_clamp` in the shop, and `sell_action` for each cargo. |

`scenes/common/game_state.gd` (the autoload `GameState`) and `scenes/common/data_files.gd` (`DataFiles`) are the only places that read files and own a `Run`.

## 3. Add a Rule

1. Add the data field and its check in `Catalog` (`_check_*`).
2. Add the rule in the file of its topic. A new reaction goes in `Shift.reaction_at()` (what starts it) and `Shift._apply()` (what it does), with a `Defs.REACT_*` constant.
3. Add each value that the screen needs to `RunView`. The UI must not calculate it.
4. Add the action: a `Defs.ACT_*` name, its line in `RunRecord.apply()`, one line in `GameState` (`_act(Defs.ACT_*, [args])`), and the text player (`COMMANDS` and `ACTIONS` in `project/tools/play.gd`).

## 4. Tests

- A test file is `project/tests/rules/test_<topic>.gd`. It extends `RuleTest`. Each method that starts with `test_` runs on a new instance, so methods do not share state.
- `RuleTest` gives a `Run` on the fixture catalog (`fixture.gd`), at a station, with an empty hold. Helpers: `put(def, x, y, rot)`, `on_dock(def)`, `accept([template ids])`, `shift([dirs])` (it charges the Shields with `Shift.charge_shields()`, as a warp does), `warp_with([dirs])`, `skip_event()`, `gone(cargo)`, `reaction_kinds(logs)`, `hits_of(step, id)`.
- Use `check(ok, what)` and `eq(got, want, what)`. Give the spec section in `what`.
- Write a comment that tells the board of each setup: where each cargo goes, and why.
- Use the fixture data for rules. Use the real data only in `test_data.gd`.
- A second run in one method: `var tr := RuleTest.new()`, then add `failures.append_array(tr.failures)` at the end.
- Run one file: `devbox run -- task test -- <part of the file name>`.
