# Payload Protocol: Development Plan

This file has the plan to make the first playtest build. The target is 7 days. The hard limit is 14 days.

- Start: 2026-11-12 (Day 1).
- Target for the playtest build: 2026-11-16 (Day 7). Days 1 to 3 took one day, so the plan moved two days earlier.
- Hard limit: 2026-11-25 (Day 14).

## Goal of the Playtest Build

A person who did not make the game can download it, learn it without help, and play a full run. The build must have:

- All rules of Sections 5 to 19.
- All screens of Section 20, the feedback of Section 21, and the pilot of Section 22.
- How to Play and the hints (Section 23).
- The first content of [content.md](content.md).
- English and zh-TW text.
- A web build on itch.io. Builds for macOS and Windows are optional.

## Architecture

The project uses the work rules of Regalia (`../Regalia`): the spec with section numbers, the backlog, the skills, and a test for each rule. The game is in GDScript only, so that it can run in a browser (Section 4.1).

| Layer | Folder | Job |
| --- | --- | --- |
| Rules | `project/rules` | Pure GDScript classes (`RefCounted` or static). The hold, the slide, the reactions, the run, contracts, the shop. No `Node`, no scenes, no file reads, no floats for game values, no global random source. |
| Game state | `project/scenes/common/game_state.gd` | The autoload `GameState`. It reads the data files, owns the `Run`, takes the actions, and emits `state_changed`. |
| Presentation | `project/scenes` | Draws the view, plays the event log, sends the input. It keeps no game state and calculates no game values. |
| Content | `project/data` | JSON. One file for each definition. |
| Tests | `project/tests` | `run_tests.gd` runs each `test_*` method of `tests/rules/test_*.gd` headless. |
| Tools | `project/tools` | `play.gd`, the text player. |

- The dependencies go in one direction only: scenes → `GameState` → rules.
- A warp returns an **event log**: the slides, hits, and reactions of each shift step, in order. The scenes play the log. They do not calculate a result.
- The text player (`task play`) plays a full run in the terminal. The `playtest` skill uses it.
- The toolchain: devbox (go-task, uv), gdtoolkit 4 through `uvx`, and Godot 4.7.

## Days

Each day ends with `task check` green and a commit.

| Day | Date | Work | Done when |
| --- | --- | --- | --- |
| 0 | 11-11 | Spec, content plan, this plan. | The user approves the spec. |
| 1–3 | 11-12 | **Rules.** Done on 11-12, in GDScript: the toolchain, `CLAUDE.md`, the skills, the rules of Sections 5 to 19, the data, the data check, the view, `GameState`, the test runner, and the text player. | **M1 done:** 81 tests pass. The text player plays a full run. |
| 4 | 11-12 | **Web check and the station screen.** Status: the station screen and `task test:ui` are done. The web check waits for the export templates. First install the export templates, export a web build of the placeholder scene, and open it in a browser. Then the station screen: the hold, drag, rotate, snap, the preview, the dock, the contract board, the shop, the clamp panel, the hazard panel, and the link lines. | A web build starts in a browser. A player can pack the hold and press Warp. |
| 5 | 11-14 | **Warp and the loop.** The playback of the event log, the arrival report, the toll gate, the run end, the title, pause, and settings. | **M2:** a full run plays in the game with placeholder looks. |
| 6 | 11-15 | **Art and feel.** The theme, the drawn cargo and trait icons, the starfield, the CRT shader, shake, particles, hit stop, CC0 sounds, the pilot lines, and zh-TW. | Each event of Section 21 has a visual and a sound. |
| 7 | 11-16 | **Balance and the build.** Playtest agents play runs with the text player. Tune the values. How to Play and the hints. The export presets, the web build on itch.io, the macOS and Windows builds, and a `README` for players. | **M3:** the playtest build. |
| 8–14 | 11-17 to 11-25 | **Buffer.** Feedback from human playtests, bugs, balance, more content, and polish. | The user accepts the build. |

## Milestones

| Milestone | Day | Check |
| --- | --- | --- |
| M1: rules done | 3 (done 11-12) | The text player plays a full run. All rule tests pass. |
| M2: playable | 5 | A full run plays in the game, from the title to the run end. |
| M3: playtest build | 7 | The web build runs on itch.io in Chrome, Firefox, and Safari. A new player finishes a run with How to Play only. |

If M2 is not done at the end of Day 6, cut scope in this order:

1. Hint system (Section 23.3). Keep How to Play.
2. Reroll (Section 17.1).
3. The `not_next_to` bonus (Section 15.3).
4. Music. Keep the sounds.

Do not cut the rules of Sections 9 to 13, the feedback of Section 21, or the zh-TW text.

## Risks

| Risk | Plan |
| --- | --- |
| The web export needs the export templates of Godot 4.7.2, and itch.io needs a build with no thread support. | Install the templates and export a web build on Day 4, before the UI work. Use the export with no thread support. |
| Audio in a browser starts only after the first click. | The title screen needs one click before the music starts. |
| The rules of the slide have corner cases (clamps, Thrusters, chains). | Each rule has a test. The text player shows the hold as text after each step. |
| Packing all cargo tight into a corner can make each shift step harmless. | Play the text player and check it before the art starts. The options are in BACKLOG.md. |
| CC0 sounds do not fit the style. | Make placeholder sounds with a script. Replace them later. |
| The design is not fun in play. | Play the text player first. Change the values before the art starts. |

## Work Rules

- The user approves each spec change.
- Claude does not commit. The user commits, unless the user asks Claude to commit.
- Claude talks to the user in Traditional Chinese. The docs are in English, in Simplified Technical English.
