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

- **[Spec · Rules] A hit at the slide limit of Low Gravity and Thruster** (found 2026-11-18, by /playtest seed 77; Playtest seed 77 round 3 (2026-11-18, kit mass) found the larger case). Two cases are not clear in the spec:
  - A cargo that stops at the limit with nothing in front. Section 10.2 says that a Thruster makes no hit. Section 28.2 does not say it for Low Gravity. The code makes no hit in both cases.
  - A block that slides as one body and stops at the limit. In Playtest seed 77 round 3 (2026-11-18, kit mass), 6 light Fragile cargo slid up 2 cells in Low Gravity. Each rear cargo hit the cargo in front with force 2, and 5 of 6 broke. The front cargo stopped at the limit, not at an obstacle. Section 10.3 says "When other cargo stops it". The code (`Shift._hits`) makes a hit when a cargo in front blocks the next cell, also when the limit stopped both. Two Thruster cargo next to each other do the same.
  To decide             Options: (a) a cargo that stops at its slide limit makes no hit, with a cargo in front or not. A block that moves together stays intact. (b) Keep the code, and write in Sections 10.2 and 28.2 that a cargo at the limit hits the cargo in front of it. The player must see it before the warp. Then add a rule test for each case.

- **[Balance · Data] Kit with no mass, the new mods, and the shock bay** (found 2026-11-14, by /game-design). The first values of the change of SPEC Sections 25, 27.2, and 31: kit mass 0, "within 2 cells" for Array Power and Cryo Line, Padded Walls -1, and the shock bay 2×2 for 20 and 3×2 for 30. Check in a playtest: does the player fill the hold with Shields and Batteries, does someone still select Padded Walls, and is the shock bay always the first purchase? Decided 2026-11-18 by /game-design: kit has mass as freight does, and cargo in the shock bay has no mass (SPEC Sections 25 and 31.1). See "The press and the shock bay with no freight". Playtest seed 77 (2026-11-18): nobody filled the hold with Shields. Array Power did nothing with no Shields. The shock bay was a safe box for each risky cargo (see "Full rows make the hold safe").

- **[Balance · Data] Environments, incidents, and special contracts** (found 2026-11-14, by /game-design). The first values of SPEC Sections 28 to 30: Low Gravity 2 cells, the meteor force 3, the incident chance 50% in leg 2 and 100% in leg 3, the VIP penalty, and the long contract pay. Check in a playtest: is leg 3 too hard with an incident at each jump, and does Low Gravity make leg 2 too easy? Playtest seed 77 (2026-11-18): the incidents of leg 3 did no damage to any persona. Low Gravity did not matter, because no cargo slid.

- **[Balance · Data] Events and mods** (found 2026-11-14, by /game-design). The first values of SPEC Sections 26 and 27: the costs 8, 10, 15, and 20, the drifting container +12, and the audit payment -15. Check in a playtest: are Padded Walls and Array Power always the best mod, and do 1 or 2 events in each leg make the run too slow? Playtest seed 22 (2026-11-14) found choices that are always best: Company Audit (pay 10 to cut the payment by 15), Pirate Demand (refuse for 8 of scrap cleanup, not a bribe of 15), and Ship Mechanic (a clamp for 10, but the shop sells one for 8). The event contracts pay much more than others: Smuggler Run 68 for 4 mass, Rescue Supplies 46 for 6 mass. Playtest seed 77 (2026-11-18) confirmed Company Audit (+5 each time), Pirate Demand, and Ship Mechanic. The Smuggler's Offer contract paid 17 for each point of mass.
  To do                 Fix: give each event two real choices. For example: the Ship Mechanic clamp costs less than the shop clamp, the audit saves less than its cost on some legs, and the bribe costs less than the cleanup of the scrap.

- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 legs × 3 jumps is the first value. The target is 20 to 30 minutes.
  Waiting on a trigger  Waits for: the station events of phase 2 (SPEC Section 24).
                        Fix then: measure the time of one run in a playtest.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest. Playtest seed 77 (2026-11-18) had no explosion, so it is not checked yet. Note: the wall jolt of a heavy cargo is 3, so a Reactor Core next to the front wall always explodes.

- **[Balance · Data] The numbers of mass, fork steps, and payments** (found 2026-11-12, by /playtest seed 2026). Playtest seed 22 (2026-11-14) had no pressure: each persona paid each leg by jump 1 or 2, and the fuel fee 2 was less than the pay per mass. The values are now payments 100 / 240 / 420 and fuel fee 3. Other values: mass limit 24, the maximum 125%, Reinforce hull +6 for 12 (+8). Check in the next playtest: can a newcomer make each payment, and is overload still always best? Playtest seed 77 (2026-11-18): the Newcomer had exactly 420 for the leg 3 payment, and found the last placement only with a brute-force script. The Optimizer and the Gambler had 209 and 101 left. A small overload was often best, and the first Reinforce (12) was better than the fee. Playtest seed 77 round 2 (2026-11-18, after the press): the Newcomer had 19 left after 420, the Gambler 35, and the Optimizer 227. The pressure of the run comes from the economy, not from the hold. The Gambler needed risky contracts (3.3 to 13.7 for each point of mass, against 1.5 to 3.5) to make 420.
  Decided 2026-11-18 by /game-design: the leg 3 payment is 380, with the kit mass (see "The press and the shock bay with no freight").
- **[Balance · Rules] The press and the shock bay with no freight** (found 2026-11-18, by /game-design). The first values of SPEC Sections 10.5 and 31.1: a press has the force of the weight value of the cargo behind, a clamped cargo does not press, and freight cannot go in the shock bay. They answer the dominant play of full rows, which playtests seed 22 and seed 77 found (0 scrap for each persona). Check in the next playtest:
  - Is the press too hard for a newcomer? The Newcomer of seed 77 had exactly 420 for the leg 3 payment.
  - Is a Cushion kit next to each Fragile cargo, or a clamp on each heavy cargo, a new dominant play?
  - Does someone still select Padded Walls?
  Playtest seed 77 round 2 (2026-11-18, after the press): the press did not break the play. Each persona had 0 scrap, and no press made a reaction (all forces 1 or 2). The players learned one easy constraint: the cargo behind each Fragile or Fluid cargo is light, Cushion, clamped, or the wall ("heavy at the front wall, fragile behind"). New strong plays: the Foam Pad (6, kept, 0 mass) cancels presses both ways and a meteor; a clamp is a safe roof, because a clamped cargo does not press; light scrap and debris are free isolators. Gravity Damper makes each heavy press 2. Padded Walls is still the first pick of the Optimizer. The shock bay with kit and scrap only is not worth 20: the Newcomer and the Optimizer did not buy it.
  Decided 2026-11-18 by /game-design: the cause is the free fillers. Kit had no mass, so the players filled each line from wall to wall. Now kit has mass as freight does (SPEC Section 25), and cargo in the shock bay has no mass (Section 31.1). The leg 3 payment is 380. The Foam Pad and the clamps do not change yet. The feel to reach: the player sees a risk and takes it for the pay. Check in the next playtest:
  - Does a player take a small loss for the pay? Does the Optimizer still have 0 scrap?
  - Does the player still buy kit? Is a Cooler or a Shield now a load?
  - Is 380 reachable for a newcomer?
  - Is the shock bay now always the first purchase?
  Playtest seed 77 round 3 (2026-11-18, kit mass): the play changed, but the feel is not there yet. "Nothing slides, 0 scrap" is still reachable and still the best score (Optimizer 296, against 209 and 227). Freight is the filler now: a staircase in the corner for steps at 90°, and full lines for opposite steps. The hold had 25 of 36 cells at most: mass is the only limit. The Optimizer weighed one small loss (+4 credits) and declined it. The Newcomer bought only the Sensor, and the Gambler no kit. The Optimizer used the shock bay as a 0-mass place for kit; the others did not buy it. Light scrap and debris are still free fillers and meteor shields. Clamps are still strong (Gambler).
  To decide             Options for the next /game-design: (a) a high-pay contract that is hard to place safely (a large shape, or a zone at a front wall). (b) A clear cost for 0 scrap: for example, the safe pack needs an overload that costs more than one lost cargo. (c) Hidden steps (SPEC Section 24), against the pillar of Section 1.1. Also: scrap and debris as free fillers.

- **[UX · Scenes] Shaders for the effects** (found 2026-11-13, by Claude). The pixelfx sheets are flat sprites. Three options can make them stronger:
  (a) Light with additive blend: `make_fx.mjs` exports the light buffer of pixelfx as a second sheet, and `FxLayer` draws it with `BLEND_MODE_ADD`. Low cost. The best first step.
  (b) A palette swap shader: one gray sheet, colored by the trait of the cargo. Fewer files.
  (c) Screen space: a shock wave ring at an explosion (`hint_screen_texture`), and a short color split on a heavy hit. The largest effect on the show (SPEC Section 1.1).
  To decide             Options: do (a), (c), or (b), in any order, or none. Each needs a line in SPEC Section 21.

- **[Balance · Data] The cargo shapes of the images** (found 2026-11-13, by /game-design). The images changed four shapes: Cargo Crate and Shield Generator are 1 cell (mass 2), Coolant Pipe is an L (mass 6), and Specimen Tube is a line of 2 (mass 4). Check in the next playtest: do the contracts still fill the mass limit, and is packing still hard?
- **[UX · Scenes] Pixel density of the cargo and the effects** (found 2026-11-13, by /game-design). The cargo images show at half their size, with fine pixels. The effects show at 3 times their size, with large pixels. Check with `task shots` and players that the two look good together.
- **[Balance · Data] The 24 new freight** (found 2026-11-13, by /game-design). The themes medical, contraband, weapons, robots, and Earth relics added 24 freight and 21 contracts. Check in the next playtest: is the Black Market pay (about 1.5 times) worth the risk, and is the Mech Suit (heavy, Thruster, a square) a wall that is always best? Playtest seed 77 (2026-11-18): the Black Market pay is 3.5 to 4.5 times the pay of safe freight (13.7 to 17 for each point of mass, against 3 to 4). Risky contracts paid 3.2 to 17 for each point of mass, and safe contracts 1.5 to 3.5.
  To do                 Fix: lower the Black Market pay to about 1.5 times the pay of safe freight. Run `task test -- data`.

## To Do

- **[Balance · Rules] Insurance pays for a spoil, and the Sensor sells at the last station** (found 2026-11-18, by Playtest seed 77 round 3 (2026-11-18, kit mass)). The Gambler took Perishable freight with no Cooler on purpose, and Insurance paid 16 for the spoil. The Optimizer sold the Sensor at the last station for 7: the fork is set when the station opens, so the reveal is already used.
  To decide             Options: (a) Insurance does not pay for a spoil. (b) Insurance pays less for a spoil. (c) Keep it. For the Sensor: (a) keep it, a small reward. (b) The sell price of kit is lower at the last station. Needs a change of SPEC Section 27.2.
- **[UX · Scenes] Blind rerolls** (found 2026-11-18, by Playtest seed 77 round 3 (2026-11-18, kit mass)). The Optimizer spent 12 credits on rerolls and no Cooler came. The shop does not show which kit a station can offer.
  To do                 Fix: show the kit pool of the leg in the shop tooltip, or make the reroll cheaper. Needs a line in SPEC Section 17.

- **[UX · Scenes] Show the projected mass and the wall jolt force** (found 2026-11-18, by /playtest seed 77). The mass line counts only the cargo in the hold. With 26 mass of accepted contracts, it showed "Mass 0/24". The wall jolt force (light 1, standard 2, heavy 3) is not on the screen, but 2 breaks a Fragile cargo. The JOLT RISK mark shows the first step only (SPEC Section 12.3). Playtest seed 77 round 2 (2026-11-18, after the press): the text player shows JOLT RISK only in the cargo list, not in the grid, and it does not say the cause (a jolt or a press). The marks do not count the debris of the incident. A kit shows a mass of 0, but it presses with its weight value.
  To do                 Fix: add the mass of the accepted contracts to the mass line as a projection, and show the jolt force of a cargo in its tooltip. Add both to the view and the spec. Show the cause of each JOLT RISK mark. Playtest seed 77 round 3 (2026-11-18, kit mass): the text player says "JOLT RISK at the front wall" for a press away from the wall. The mark covers step 1 only, so it missed the Low Gravity slide of a fork step. Each round asked for marks of each known step and both fork directions.

- **[UX · Data] Small clarity problems** (found 2026-11-18, by /playtest seed 77).
  - The Drifting Container event does not say that its scrap adds mass.
  - The warp log does not explain the Shock Floor -1, or that Insurance rounds down for each cargo (16, not 18).
  - The bonus "2 lines at the bottom" has no mark on the hold.
  - The win line "The cargo survived. Mostly." can show after a run with 0 scrap (`data/lines/win.json`).
  - Text player: the `rot` of `place` is absolute. A rotated kit on the dock fails with the old rotation, and the error is easy to miss in a long `do`.
  - The text does not explain the force of a slide hit (weight × distance). The Gravity Damper text says "hits", but the mod changes wall jolts and presses too (Playtest seed 77 round 2 (2026-11-18, after the press)).
  - The bonus "no piece next to Fluid" counted two Sodas of the same contract. The arrival report does not say why a bonus was missed (Playtest seed 77 round 2 (2026-11-18, after the press)).
  - A LONG freight can go to the dock in the middle of its trip with no warning (Playtest seed 77 round 2 (2026-11-18, after the press)).
  - A `do` batch stops at the first error, and the cause is easy to miss (again in Playtest seed 77 round 2 (2026-11-18, after the press), and in Playtest seed 77 round 3 (2026-11-18, kit mass): show "stopped at action N").
  - The help of the text player does not have the force of a slide hit (Playtest seed 77 round 3 (2026-11-18, kit mass)).
  - The text player does not mark which step is the fork when a Sensor shows it in the hazard line (Playtest seed 77 round 3 (2026-11-18, kit mass)). "max 37" after a Reinforce is not clear.
  - The incident text "HULL BREACH at cell 2 3" has no x= and y= (Playtest seed 77 round 3 (2026-11-18, kit mass)).
  To do                 Fix: add the text to the event, the log, and the hold mark. Select the win line by the scrap count. Show the failed action at the end of a `do` in the text player.

- **[Balance · Data] The offer rate of the new contracts** (found 2026-11-14, by /playtest seed 22). The 3 personas saw 27 stations, and only `greenhouse` was offered (once). `prosthetics` and `warp_core` were not offered. The pay of `prosthetics` (now 4 each) and `greenhouse` (now 13 each) changed from the data, not from play. `warp_core` (24 + 10) pays 5.7 for each point of mass, more than the leg 3 median 4.7, but a wall jolt explodes it. Playtest seed 77 (2026-11-18): none of the 3 contracts was offered in 27 stations again.
  To do                 Fix: count the offers of each contract over many seeds, and play the 3 contracts in a playtest.

- **[Art · Data] A new image for the Foam Pad** (found 2026-11-14, by the user). The Foam Pad uses a rolled yoga mat (`tools/art/cargo_art.json`). The image does not look like a cushion kit, and the "fit" scale makes it a little soft.
  To do                 Fix: find a FreePixel image of a foam pad or a cushion that fits a line of 2 cells. Change its `source` and run `task art`.
- **[Docs · Docs] A README for players** (found 2026-11-12, by the first plan). The itch.io page needs a short text for players: how to start, the controls, and where to send feedback.
  To do                 Fix: write the text. Keep README.md for developers.
- **[Build · Build] Builds for macOS and Windows** (found 2026-11-12, by the first plan). Only the web build exists. These builds are optional.
  Waiting on a trigger  Waits for: a player who asks for a download, or a second playtest round.
                        Fix then: add the export presets, a task for each, and sign or note the macOS build.
