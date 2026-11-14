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

- **[Balance · Data] Environments, incidents, and special contracts** (found 2026-11-14, by /game-design). The first values of SPEC Sections 28 to 30: Low Gravity 2 cells, the meteor force 3, the incident chance 50% in leg 2 and 100% in leg 3, the VIP penalty, and the long contract pay. Check in a playtest: is leg 3 too hard with an incident at each jump, and does Low Gravity make leg 2 too easy?

- **[Balance · Data] Events and mods** (found 2026-11-14, by /game-design). The first values of SPEC Sections 26 and 27: the costs 8, 10, 15, and 20, the drifting container +12, and the audit payment -15. Check in a playtest: are Padded Walls and Array Power always the best mod, and do 1 or 2 events in each leg make the run too slow?

- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 legs × 3 jumps is the first value. The target is 20 to 30 minutes.
  Waiting on a trigger  Waits for: the station events of phase 2 (SPEC Section 24).
                        Fix then: measure the time of one run in a playtest.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest.

- **[Balance · Data] The numbers of mass, fork steps, and payments** (found 2026-11-12, by /playtest seed 2026). The first values: mass limit 24, the maximum 125%, fuel fee 2, Reinforce hull +6 for 12 (+8), payments 70 / 180 / 350. Check them in the next playtest: can the player make each payment, and does each jump have a real choice?
- **[Balance · Rules] Full rows of light cargo** (found 2026-11-12, by /game-design). With the mass limit, a player can still fill a few full rows (wall to wall) with light cargo. Those rows are safe for each direction. The light freight pays little, so it can be a fair choice. Check it in the next playtest.
- **[UX · Tests] The text player log** (found 2026-11-12, by /playtest seed 2026). A hit line does not say if it caused a reaction. A Thruster stop has no line. Each cargo has a letter and an ID.

- **[Balance · Data] The free clamp and the payments after the wall jolt** (found 2026-11-12, by /playtest round 2). Round 2 (before the wall jolt) found: the free clamp comes back each jump and fills the last gap of a tight pack; zero-risk income was about 140 for each jump, so the payments 70 / 180 / 350 were easy. The agents suggest payments of about 120 / 350 / 650, and 1 free clamp for each leg.
  Waiting on a trigger  Waits for: a playtest with the wall jolt (SPEC Section 10.4).
                        Fix then: set the payments from the income that the playtest measures.
- **[UX · Scenes] Small issues from round 2** (found 2026-11-12, by /playtest round 2). The end screen of the text player still shows "payment 350 after 1 jump(s)". The text player does not show the Reinforce hull price.

- **[UX · Scenes] Shaders for the effects** (found 2026-11-13, by Claude). The pixelfx sheets are flat sprites. Three options can make them stronger:
  (a) Light with additive blend: `make_fx.mjs` exports the light buffer of pixelfx as a second sheet, and `FxLayer` draws it with `BLEND_MODE_ADD`. Low cost. The best first step.
  (b) A palette swap shader: one gray sheet, colored by the trait of the cargo. Fewer files.
  (c) Screen space: a shock wave ring at an explosion (`hint_screen_texture`), and a short color split on a heavy hit. The largest effect on the show (SPEC Section 1.1).
  To decide             Options: do (a), (c), or (b), in any order, or none. Each needs a line in SPEC Section 21.

- **[Balance · Data] The cargo shapes of the images** (found 2026-11-13, by /game-design). The images changed four shapes: Cargo Crate and Shield Generator are 1 cell (mass 2), Coolant Pipe is an L (mass 6), and Specimen Tube is a line of 2 (mass 4). Check in the next playtest: do the contracts still fill the mass limit, and is packing still hard?
- **[UX · Scenes] Pixel density of the cargo and the effects** (found 2026-11-13, by /game-design). The cargo images show at half their size, with fine pixels. The effects show at 3 times their size, with large pixels. Check with `task shots` and players that the two look good together.
- **[Balance · Data] The 24 new freight** (found 2026-11-13, by /game-design). The themes medical, contraband, weapons, robots, and Earth relics added 24 freight and 21 contracts. Check in the next playtest: is the Black Market pay (about 1.5 times) worth the risk, and is the Mech Suit (heavy, Thruster, a square) a wall that is always best?

- **[UX · Spec] Keep the cargo after a bad drop** (found 2026-11-14, by /code-review). SPEC Section 8.3: after a drop that is not valid, the cargo goes back to its last place. A cargo from the dock goes back to the dock with no animation, and the player must find it and pick it up again.
  To decide             Options: (a) after a bad drop over the hold, the player keeps the cargo (a deny sound and a small shake). Only Esc or a drop outside the hold puts it back. (b) Keep the rule, and move the cargo back with a short tween. Needs a change of SPEC Section 8.3.
- **[UX · Spec] The same feedback for each miss** (found 2026-11-14, by /code-review). A drop 0.4 cell outside the hold plays the deny sound and a toast. A drop 0.6 cell outside does nothing, and the cargo goes back with no sound.
  To decide             Options: (a) the same feedback for each return (a tween and a soft sound). (b) Also snap a near miss to the nearest valid place within 1 cell, in the order of the rotate fallback of SPEC Section 8.2.
- **[UX · Spec] A preview that says why** (found 2026-11-14, by /code-review). A red preview does not show why the drop fails: outside the hold, or a cargo in the way.
  To decide             Options: color each blocked cell red and each free cell green, mark the cargo in the way, and show the nearest valid place as a faint ghost. Needs a line in SPEC Section 8.3.
- **[UX · Spec] Place many cargo with drags** (found 2026-11-14, by /code-review). Only the click mode picks up the next cargo of the dock (SPEC Section 8.2). Players who drag do not find it.
  To decide             Options: (a) mark the next cargo of the dock, and show a hint after the first drag. (b) A drag also picks up the next cargo, with a setting to turn it off.

## To Do


- **[UX · Scenes] A glyph that the font does not have** (found 2026-11-14, by Claude). The pilot box of the station shows "▸" (U+25B8). The font jf open huninn does not have it. On the desktop a system font shows it, but the web build can show a box.
  To do                 Fix: use a glyph of the font (for example ":" or "→"), or draw the mark. Check the other symbols of the text with the font too.

- **[Art · Data] A new image for the Foam Pad** (found 2026-11-14, by the user). The Foam Pad uses a rolled yoga mat (`tools/art/cargo_art.json`). The image does not look like a cushion kit, and the "fit" scale makes it a little soft.
  To do                 Fix: find a FreePixel image of a foam pad or a cushion that fits a line of 2 cells. Change its `source` and run `task art`.
- **[Docs · Docs] A README for players** (found 2026-11-12, by the first plan). The itch.io page needs a short text for players: how to start, the controls, and where to send feedback.
  To do                 Fix: write the text. Keep README.md for developers.
- **[Build · Build] Builds for macOS and Windows** (found 2026-11-12, by the first plan). Only the web build exists. These builds are optional.
  Waiting on a trigger  Waits for: a player who asks for a download, or a second playtest round.
                        Fix then: add the export presets, a task for each, and sign or note the macOS build.
- **[Cleanup · Tests] Resources in use at the exit of task shots** (found 2026-11-13, by Claude). `task shots` prints "2 resources still in use at exit" when it quits. A run with `--verbose` does not print it, so the two resources are not known. The screenshots are correct.
  To do                 Fix: find the two resources (for example the music stream or the FxSheets cache) and free them before quit().
