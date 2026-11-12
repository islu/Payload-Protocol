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

- **[Spec · Docs] Approve the rules that the code added** (found 2026-11-12, by Claude). The code needed rules that the spec did not have. They are in the spec now, and they wait for approval:
  - Section 4.1: the web is the first platform.
  - Section 10.2: a Thruster that stops by itself makes no hit.
  - Section 10.3: a cargo makes one hit on each cargo that blocks it, and one on the wall.
  - Section 11: one reaction for each cargo, in the order explosion, leak, break.
  - Section 12.2: a Shield also stops an explosion of a protected cargo. It does not stop the removal of scrap or a spoil.
  - Section 20.4: the piece state "lost" for freight that an explosion removed.
  To decide             Options: approve each rule, or change it.
- **[Spec · Rules] A forecast of the shift** (found 2026-11-11, by Claude). Section 1.1 says that the player can read each shift. The station does not show the result before the warp.
  To decide             Options: (a) no forecast: the player thinks (the first value); (b) a ghost of the first shift step only; (c) a forecast that costs credits. (b) and (c) make the puzzle easier and add a station view.
- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 sectors × 3 jumps is the first value. Check the time of one run in the first playtest. The target is 20 to 30 minutes.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest.

- **[Balance · Data] The numbers of mass, fork steps, and tolls** (found 2026-11-12, by /playtest seed 2026). The first values: mass limit 24, the maximum 125%, fuel fee 2, Reinforce hull +6 for 12 (+8), tolls 70 / 180 / 350. Check them in the next playtest: can the player pay each toll, and does each jump have a real choice?
- **[Balance · Rules] Full rows of light cargo** (found 2026-11-12, by /game-design). With the mass limit, a player can still fill a few full rows (wall to wall) with light cargo. Those rows are safe for each direction. The light freight pays little, so it can be a fair choice. Check it in the next playtest.
- **[Spec · Rules] A bonus with lost pieces** (found 2026-11-12, by /playtest seed 2026). `not_next_to` and `zone` pay when 1 piece arrives, even when the other pieces broke or spoiled (SPEC Section 15.3). The Gambler found it odd.
  To decide             Options: (a) keep it; (b) a bonus pays only when no piece of its contract is scrap, spoiled, or lost.
- **[UX · Tests] The text player log** (found 2026-11-12, by /playtest seed 2026). A hit line does not say if it caused a reaction. A Thruster stop has no line. Each cargo has a letter and an ID.

- **[Balance · Data] The free clamp and the tolls after the wall jolt** (found 2026-11-12, by /playtest round 2). Round 2 (before the wall jolt) found: the free clamp comes back each jump and fills the last gap of a tight pack; zero-risk income was about 140 for each jump, so the tolls 70 / 180 / 350 were easy. The agents suggest tolls of about 120 / 350 / 650, and 1 free clamp for each sector.
  Waiting on a trigger  Waits for: a playtest with the wall jolt (SPEC Section 10.4).
                        Fix then: set the tolls from the income that the playtest measures.
- **[UX · Scenes] Small issues from round 2** (found 2026-11-12, by /playtest round 2). The station does not mark a fork step that a Sensor shows. The end screen of the text player still shows "toll 350 after 1 jump(s)". The text player does not show the Reinforce hull price.

## To Do

- **[Build · Build] The web export** (found 2026-11-12, by Claude). The export templates of Godot 4.7.2 are not installed. Install them, add the web preset with no thread support, and check a build in a browser on Day 4.
