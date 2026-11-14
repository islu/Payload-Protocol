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
| `defs.gd` | `Defs`: the fixed strings (kinds, weights, traits, directions, phases, reactions, pieces, bonuses, sides, axes, links, line events) and `Defs.delta()` |
| `shapes.gd` | `Shapes`: rotation, size, cells at a place, connected, JSON and view forms |
| `cargo_def.gd`, `cargo.gd` | `CargoDef` (data) and `Cargo` (one cargo in a run): `cells()`, `has()`, `weight()`, `Cargo.next_to()` |
| `contract_template.gd`, `contract.gd` | Contract data, the zone of a bonus, and an offered contract |
| `catalog.gd` | `Catalog.from_data()`: reads the parsed JSON and checks it (content.md). `errors` has the problems |
| `run.gd` | `Run`: the state, the phases, placement (`ROTATE_KICKS`), clamps, contracts, the shop, the mass (`cargo_mass`, `hold_mass`, `max_mass`, `fuel_fee`, `reinforce_hull`), the hazard with its fork step (`fork_options`), the dock at the warp, the pilot lines |
| `shift.gd` | `Shift.step()`: power, slide, hits (with the wall jolt of SPEC Section 10.4: a hit with `jolt: true`), reactions (each with its lost pay `loss` and its number in the chain `chain`, SPEC Section 21.5), blast area, shields. It returns the event log of the step |
| `arrival.gd` | `Arrival.arrive()`: spoil, delivery, bonus, breach, the report, the line event |
| `run_record.gd` | `RunRecord`: the seed and each action that worked (a `Callable` on the `Run`). `undo()` plays the run again from the seed with no last action, back to the arrival at the station (SPEC Section 20.2). |
| `run_view.gd` | `RunView.view()`: the plain data that the UI reads. `hazard()` hides the direction of a fork step unless a Sensor is in the hold. |

`scenes/common/game_state.gd` (the autoload `GameState`) and `scenes/common/data_files.gd` (`DataFiles`) are the only places that read files and own a `Run`.

## 3. Add a Rule

1. Add the data field and its check in `Catalog` (`_check_*`).
2. Add the rule in the file of its topic. A new reaction goes in `Shift._react()` and `Shift._apply()`, with a `Defs.REACT_*` constant.
3. Add each value that the screen needs to `RunView`. The UI must not calculate it.
4. Add the action to `GameState` (one line with `_act`: a `Callable` that takes the `Run`, so that `RunRecord` can play it again) and to the text player (`_act` and `ACTIONS` in `project/tools/play.gd`).

## 4. Tests

- A test file is `project/tests/rules/test_<topic>.gd`. It extends `RuleTest`. Each method that starts with `test_` runs on a new instance, so methods do not share state.
- `RuleTest` gives a `Run` on the fixture catalog (`fixture.gd`), at a station, with an empty hold. Helpers: `put(def, x, y, rot)`, `on_dock(def)`, `accept([template ids])`, `shift([dirs])`, `warp_with([dirs])`, `gone(cargo)`, `reaction_kinds(logs)`, `hits_of(step, id)`.
- Use `check(ok, what)` and `eq(got, want, what)`. Give the spec section in `what`.
- Write a comment that tells the board of each setup: where each cargo goes, and why.
- Use the fixture data for rules. Use the real data only in `test_data.gd`.
- A second run in one method: `var tr := RuleTest.new()`, then add `failures.append_array(tr.failures)` at the end.
- Run one file: `devbox run -- task test -- <part of the file name>`.
