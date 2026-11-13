# Backlog

This file keeps each problem that is found and not fixed yet. Each item is in one place only:

- **Here**, while it is not decided or not done.
- **Nowhere**, after it is fixed. Delete it here in the same change.

## Format

```md
- **[Type · Layer] Title** (found YYYY-MM-DD, by /skill or person). The problem and a
  scenario that shows it. Then:
  To decide             Options: each choice and what it changes for the player or the code.
  To do                 Fix: what to change.
  Waiting on a trigger  Waits for: a signal that someone can check.
                        Fix then: what to change when the signal comes.
```

- **Type**: `Bug`, `Spec`, `Balance`, `Test`, `Refactor`, `Cleanup`, `UX`.
- **Layer**: `Rules`, `Scenes`, `Data`, `Locale`, `Tests`, `Docs`, `Skills`, `Build`.

## To Decide

- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 sectors × 3 jumps is the first value. Check the time of one run in the first playtest. The target is 20 to 30 minutes.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest.

- **[Balance · Data] The numbers of mass, fork steps, and tolls** (found 2026-11-12, by /playtest seed 2026). The first values: mass limit 24, the maximum 125%, fuel fee 2, Reinforce hull +6 for 12 (+8), tolls 70 / 180 / 350. Check them in the next playtest: can the player pay each toll, and does each jump have a real choice?
- **[Balance · Rules] Full rows of light cargo** (found 2026-11-12, by /game-design). With the mass limit, a player can still fill a few full rows (wall to wall) with light cargo. Those rows are safe for each direction. The light freight pays little, so it can be a fair choice. Check it in the next playtest.
- **[UX · Tests] The text player log** (found 2026-11-12, by /playtest seed 2026). A hit line does not say if it caused a reaction. A Thruster stop has no line. Each cargo has a letter and an ID.

- **[Balance · Data] The free clamp and the tolls after the wall jolt** (found 2026-11-12, by /playtest round 2). Round 2 (before the wall jolt) found: the free clamp comes back each jump and fills the last gap of a tight pack; zero-risk income was about 140 for each jump, so the tolls 70 / 180 / 350 were easy. The agents suggest tolls of about 120 / 350 / 650, and 1 free clamp for each sector.
  Waiting on a trigger  Waits for: a playtest with the wall jolt (SPEC Section 10.4).
                        Fix then: set the tolls from the income that the playtest measures.
- **[UX · Scenes] Small issues from round 2** (found 2026-11-12, by /playtest round 2). The station does not mark a fork step that a Sensor shows. The end screen of the text player still shows "toll 350 after 1 jump(s)". The text player does not show the Reinforce hull price.

- **[UX · Scenes] Shaders for the effects** (found 2026-11-13, by Claude). The pixelfx sheets are flat sprites. Three options can make them stronger:
  (a) Light with additive blend: `make_fx.mjs` exports the light buffer of pixelfx as a second sheet, and `FxLayer` draws it with `BLEND_MODE_ADD`. Low cost. The best first step.
  (b) A palette swap shader: one gray sheet, colored by the trait of the cargo. Fewer files.
  (c) Screen space: a shock wave ring at an explosion (`hint_screen_texture`), and a short color split on a heavy hit. The largest effect on the show (SPEC Section 1.1).
  To decide             Options: do (a), (c), or (b), in any order, or none. Each needs a line in SPEC Section 21.

## To Do

- **[Docs · Docs] A README for players** (found 2026-11-12, by the first plan). The itch.io page needs a short text for players: how to start, the controls, and where to send feedback.
  To do                 Fix: write the text. Keep README.md for developers.
- **[Build · Build] Builds for macOS and Windows** (found 2026-11-12, by the first plan). Only the web build exists. These builds are optional.
  Waiting on a trigger  Waits for: a player who asks for a download, or a second playtest round.
                        Fix then: add the export presets, a task for each, and sign or note the macOS build.
