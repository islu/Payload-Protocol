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
- **[Balance · Rules] Corner packing can make a jump safe** (found 2026-11-12, by Claude). With 1 or 2 known steps, the player can pack all cargo tight into the corner of the two directions. Then no cargo slides, and no hit happens. Example: seed 7, jump 1 (RIGHT): all freight at the right wall gave +33 credits with no risk.
  To decide             Options: (a) keep it: the space limit and scrap make tight packing hard later; check in the playtest;
                        (b) more opposite steps (LEFT then RIGHT) in sectors 2 and 3;
                        (c) fixed walls or bumps inside the hold;
                        (d) a hidden step in sector 3 (Section 24).
- **[Spec · Rules] A forecast of the shift** (found 2026-11-11, by Claude). Section 1.1 says that the player can read each shift. The station does not show the result before the warp.
  To decide             Options: (a) no forecast: the player thinks (the first value); (b) a ghost of the first shift step only; (c) a forecast that costs credits. (b) and (c) make the puzzle easier and add a station view.
- **[Balance · Data] The length of a run** (found 2026-11-11, by Claude). 3 sectors × 3 jumps is the first value. Check the time of one run in the first playtest. The target is 20 to 30 minutes.
- **[Spec · Rules] Heavy cargo in an explosion** (found 2026-11-11, by Claude). Section 11.2 says that heavy cargo is not affected. A Reactor Core is heavy and Volatile: a different explosion does not break it, but it explodes in a chain. Check that this reads clearly in the first playtest.

## To Do

- **[Build · Build] The web export** (found 2026-11-12, by Claude). The export templates of Godot 4.7.2 are not installed. Install them, add the web preset with no thread support, and check a build in a browser on Day 4.
- **[Test · Tests] The i18n tool** (found 2026-11-12, by Claude). Regalia had a Go tool for the translation files. This project has no Go. Write `task i18n` as a script (Python through `uv`): collect `tr()` calls, scene text, the `*_TEXT` constants of the rules, and the text keys of the data. Day 6.
