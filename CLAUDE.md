# Payload Protocol

Payload Protocol is a single-player puzzle game about cargo in the hold of a spaceship. The player packs freight into a grid. Each warp shifts the hold: cargo slides, hits, breaks, explodes, and leaks (SPEC Section 1).

**Status:** The rules of Sections 5 to 19, the events of Section 26, the mods of Section 27, the environments and incidents of Sections 28 and 29, and the special contracts of Section 30 are in the code, with tests and a text player. All screens of Section 20 are in the code: the title, the station, the warp with the arrival report, the payment screen and the run end (`PhasePanel`), the pause menu with its gear button, the event with its speaker (`EventPanel`) and the mod choice (`ChoicePanel`), the settings, How to Play with pictures, and the hints of the first runs. The effects of Section 21, the placeholder sounds, the CRT filter, the trait icons, and the zh-TW text are in the code. One CC0 music loop plays on all screens. The spec change of 2026-11-14 (the new station layout, the shock bay, the mod bar, the event speakers, the drag feedback, and the warp checklist) is in the code. Its values wait for a playtest (the To Decide items of [docs/BACKLOG.md](docs/BACKLOG.md)).

[docs/spec.md](docs/spec.md) is the source of truth for game design. If the code and the spec do not agree, ask the user. Do not change the spec without approval. [docs/content.md](docs/content.md) has the content design rules.

## Skills

Load the skill for the work before you start. The skills have the detailed rules.

| Work | Skill |
| --- | --- |
| Any change to the game: a rule, a bug fix, content, values (start here) | `change` |
| Design talk before code (mechanics, UI, UX, the core loop) | `game-design` |
| The rules layer and its tests (`project/rules`, `project/tests`) | `game-rules` |
| Scenes, UI, and presentation (`project/scenes`) | `godot-ui` |
| Agents that play runs with the text player and report | `playtest` |

- Use `change` for each change to the game, even if the user does not name it. Do not use it for a change with no behavior (docs, comments, format).
- Put each finding that you do not fix now in [docs/BACKLOG.md](docs/BACKLOG.md), not only in a report.
- Keep the skills the same as the code. A change that renames, moves, or removes a file or a symbol also updates each skill that names it.

## Documentation Language

- Write all documents in English.
- Use Simplified Technical English (ASD-STE100):
  - Write one instruction in each sentence.
  - Use the imperative for instructions ("Run the tests.").
  - Use the active voice.
  - Keep procedural sentences to 20 words or fewer. Keep descriptive sentences to 25 words or fewer.
  - Use one word for one meaning. Use the terms of SPEC Section 4.4.
  - Write "Do not ..." for prohibitions.
- Talk to the user in Traditional Chinese (zh-TW). Keep identifiers, paths, and commands in English.

## Technology

| Item | Value |
| --- | --- |
| Engine | Godot 4.7, 2D, GL Compatibility renderer |
| Language | GDScript only. The game must run in a browser (SPEC Section 4.1). |
| Toolchain versions | devbox (go-task, uv, coreutils, nodejs) |
| Lint and format | gdtoolkit 4 through `uvx` (`gdlintrc`). JSON: `tools/fmt_json/fmt_json.py` |
| Godot binary | System `godot`, not in devbox. Set `GODOT=...` to use a different binary. |

The Godot project is in `project/`. The repository root is not a Godot project.

## Commands

Run all commands in the devbox environment. Use `devbox shell` or `devbox run -- task <name>`.

```sh
task import       # Import the project headless. Run after a clone, and after you add a class_name.
task run          # Run the game
task editor       # Open the Godot editor
task test         # Run the rule tests. Filter by file: task test -- slide
task test:ui      # Play a full run through the screens, headless
task export:web   # Export the web build to build/web
task serve:web    # Serve build/web at http://localhost:8060
task play -- help # The text player: one command in each call (the playtest skill)
task smoke        # Run the game headless for 5 frames. Fails on an error.
task shots        # Take screenshots of each screen into shots/ (a window opens). Delete them after the review.
task i18n         # Collect the text for translation into project/locale/
task sfx          # Make the placeholder sounds in project/audio/sfx
task fx           # Make the effect sheets in project/art/fx with pixelfx (tools/fx/fx.json)
task art          # Make the cargo images, the speaker portraits, and project/icon.png from FreePixel images (tools/art/)
task fmt          # Format the GDScript code and the JSON data (tab indentation)
task lint         # Lint the GDScript code, check the format, and check that the font has each character
task check        # Run lint, test, test:ui, and smoke
task check:quiet  # Run task check. Print only the failures. The full output is in .task/check.log.
```

## Project Structure

```text
project/rules/        # The game rules: pure GDScript classes. Run is the state and the actions.
project/scenes/       # Scenes and scripts by feature. common/game_state.gd is the autoload GameState.
project/data/         # Game content (JSON): rules.json, terms.json, cargo/, contracts/, lines/, events/, speakers/, mods/, environments/
project/tests/        # run_tests.gd, TestCase, the rule tests in tests/rules/test_*.gd, and ui_check.tscn
project/tools/        # play.gd, the text player
project/locale/       # messages.pot (made by task i18n) and the .po file for each language
project/audio/sfx/    # The sounds. tools/sfx/make_sfx.py makes the placeholders.
tools/                # godot_check.sh (runs Godot headless and fails on a script error), i18n/ (i18n.py, glyphs.py: each character is in the font), sfx/make_sfx.py, fmt_json/fmt_json.py (Python through uv), fx/ (Node: make_fx.mjs, fx.json, effects/), art/ (import_art.py, cargo_art.json, speaker_art.json)
project/art/          # Font, theme, fx/ (the effect sheets of task fx), cargo/ and speakers/ (the cargo images and the portraits of task art)
docs/                 # spec.md (index) and spec/ (the spec by topic), content.md, BACKLOG.md, assets.md
docs/notes/           # Notes that are not in git (the first draft)
```

## Core Rules

- Dependencies go in one direction only: **scenes → GameState → rules**.
- `project/rules` has all game rules and all game state. It does not use `Node`, scenes, files, or the screen. It extends `RefCounted`, or it has static functions only.
- `GameState` is the one owner of the game state. Scenes call its actions and read `GameState.view()`.
- Scenes are presentation only. They do not keep game state or calculate game values. A value that the screen shows comes from the view.
- A warp gives an event log. Scenes play the log. They do not calculate the result of a shift.
- All content is JSON in `project/data/`. New content must not need a code change. Do not hard-code balance values.
- Use one file for each definition. The `id` is snake_case and is the same as the file name.
- Put text for the player in data only in `name`, `text`, and keys that end in `_name`.
- Translate all text for the player. After you change text, run `task i18n` and translate each new entry of `project/locale/zh_TW.po`. `task lint` fails when an entry has no translation.
- Use the words of Taiwan in zh-TW, not the words of mainland China. `task lint` fails on a word of `tools/i18n/zh_tw_avoid.json`.

## Key Prohibitions

- Do not use floats for game values. Use `int`. JSON numbers are floats: convert them with `int()` when you read data.
- Do not use the global random functions (`randi()`, `randf()`) in the rules. Use the `RandomNumberGenerator` of the `Run`. The same seed and the same actions must give the same run (SPEC Section 3).
- Do not compare with a literal string in code. Use the constants of `Defs` (`project/rules/defs.gd`).
- Do not read files in `project/rules`. `DataFiles` (`scenes/common/data_files.gd`) reads them.
- Do not use the gdtoolkit package from nixpkgs (version 3.x).
- Do not commit. The user commits.

## After Each Change

1. Run `task fmt`.
2. Run `task check:quiet`. Make sure that it passes.
3. The tests and `task smoke` are the check. Do not launch the game with a window to verify a change. For a review of the look of a screen, use `task shots` only, and delete `shots/` after.
4. If the change affects game rules or values, make sure that it agrees with `docs/spec.md`.
5. Add each problem that you found and did not fix to `docs/BACKLOG.md`. Delete each item that the change completed.
