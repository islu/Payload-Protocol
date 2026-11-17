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

- **[Balance · Data] Kit with no mass, the new mods, and the shock bay** (found 2026-11-14, by /game-design). The first values of the change of SPEC Sections 25, 27.2, and 31: kit mass 0, "within 2 cells" for Array Power and Cryo Line, Padded Walls -1, and the shock bay 2×2 for 20 and 3×2 for 30. Check in a playtest: does the player fill the hold with Shields and Batteries, does someone still select Padded Walls, and is the shock bay always the first purchase?

- **[Balance · Data] Environments, incidents, and special contracts** (found 2026-11-14, by /game-design). The first values of SPEC Sections 28 to 30: Low Gravity 2 cells, the meteor force 3, the incident chance 50% in leg 2 and 100% in leg 3, the VIP penalty, and the long contract pay. Check in a playtest: is leg 3 too hard with an incident at each jump, and does Low Gravity make leg 2 too easy?

- **[Balance · Data] Events and mods** (found 2026-11-14, by /game-design). The first values of SPEC Sections 26 and 27: the costs 8, 10, 15, and 20, the drifting container +12, and the audit payment -15. Check in a playtest: are Padded Walls and Array Power always the best mod, and do 1 or 2 events in each leg make the run too slow? Playtest seed 22 (2026-11-14) found choices that are always best: Company Audit (pay 10 to cut the payment by 15), Pirate Demand (refuse for 8 of scrap cleanup, not a bribe of 15), and Ship Mechanic (a clamp for 10, but the shop sells one for 8). The event contracts pay much more than others: Smuggler Run 68 for 4 mass, Rescue Supplies 46 for 6 mass.

- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 legs × 3 jumps is the first value. The target is 20 to 30 minutes.
  Waiting on a trigger  Waits for: the station events of phase 2 (SPEC Section 24).
                        Fix then: measure the time of one run in a playtest.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest.

- **[Balance · Data] The numbers of mass, fork steps, and payments** (found 2026-11-12, by /playtest seed 2026). Playtest seed 22 (2026-11-14) had no pressure: each persona paid each leg by jump 1 or 2, and the fuel fee 2 was less than the pay per mass. The values are now payments 100 / 240 / 420 and fuel fee 3. Other values: mass limit 24, the maximum 125%, Reinforce hull +6 for 12 (+8). Check in the next playtest: can a newcomer make each payment, and is overload still always best?
- **[Balance · Rules] Full rows make the hold safe** (found 2026-11-12, by /game-design; confirmed 2026-11-14, by /playtest seed 22). All 3 personas filled full rows or columns against the known walls. Then no cargo slides, and no trait matters. Padded Walls removes the wall jolt, and the free clamp fills the last gap. The run had 0 scrap for each persona.
  To decide             Options: (a) a hidden step or a hidden fork direction, so one block cannot answer each jump. (b) A shear step that moves only some rows. (c) Incidents that open gaps in a full row. (d) 1 free clamp for each leg, not for each jump. Needs a change of the spec.
- **[UX · Scenes] Shaders for the effects** (found 2026-11-13, by Claude). The pixelfx sheets are flat sprites. Three options can make them stronger:
  (a) Light with additive blend: `make_fx.mjs` exports the light buffer of pixelfx as a second sheet, and `FxLayer` draws it with `BLEND_MODE_ADD`. Low cost. The best first step.
  (b) A palette swap shader: one gray sheet, colored by the trait of the cargo. Fewer files.
  (c) Screen space: a shock wave ring at an explosion (`hint_screen_texture`), and a short color split on a heavy hit. The largest effect on the show (SPEC Section 1.1).
  To decide             Options: do (a), (c), or (b), in any order, or none. Each needs a line in SPEC Section 21.

- **[Balance · Data] The cargo shapes of the images** (found 2026-11-13, by /game-design). The images changed four shapes: Cargo Crate and Shield Generator are 1 cell (mass 2), Coolant Pipe is an L (mass 6), and Specimen Tube is a line of 2 (mass 4). Check in the next playtest: do the contracts still fill the mass limit, and is packing still hard?
- **[UX · Scenes] Pixel density of the cargo and the effects** (found 2026-11-13, by /game-design). The cargo images show at half their size, with fine pixels. The effects show at 3 times their size, with large pixels. Check with `task shots` and players that the two look good together.
- **[Balance · Data] The 24 new freight** (found 2026-11-13, by /game-design). The themes medical, contraband, weapons, robots, and Earth relics added 24 freight and 21 contracts. Check in the next playtest: is the Black Market pay (about 1.5 times) worth the risk, and is the Mech Suit (heavy, Thruster, a square) a wall that is always best?

## To Do

- **[Balance · Data] The offer rate of the new contracts** (found 2026-11-14, by /playtest seed 22). The 3 personas saw 27 stations, and only `greenhouse` was offered (once). `prosthetics` and `warp_core` were not offered. The pay of `prosthetics` (now 4 each) and `greenhouse` (now 13 each) changed from the data, not from play. `warp_core` (24 + 10) pays 5.7 for each point of mass, more than the leg 3 median 4.7, but a wall jolt explodes it.
  To do                 Fix: count the offers of each contract over many seeds, and play the 3 contracts in a playtest.

- **[Art · Data] A new image for the Foam Pad** (found 2026-11-14, by the user). The Foam Pad uses a rolled yoga mat (`tools/art/cargo_art.json`). The image does not look like a cushion kit, and the "fit" scale makes it a little soft.
  To do                 Fix: find a FreePixel image of a foam pad or a cushion that fits a line of 2 cells. Change its `source` and run `task art`.
- **[Docs · Docs] A README for players** (found 2026-11-12, by the first plan). The itch.io page needs a short text for players: how to start, the controls, and where to send feedback.
  To do                 Fix: write the text. Keep README.md for developers.
- **[Build · Build] Builds for macOS and Windows** (found 2026-11-12, by the first plan). Only the web build exists. These builds are optional.
  Waiting on a trigger  Waits for: a player who asks for a download, or a second playtest round.
                        Fix then: add the export presets, a task for each, and sign or note the macOS build.
