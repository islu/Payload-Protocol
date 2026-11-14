# Payload Protocol: Game Specification (Version 1)

**Status:** Approved. A change needs the approval of the user.

The spec is the design of the game. Each rule in it has the approval of the user, and the code follows it. A rule that is in the spec and not in the code yet has a **To Do** item in [BACKLOG.md](BACKLOG.md). An idea that is not ready goes in Section 24, not in the other sections.

The specification is in the files of [spec/](spec/). Each file has some sections. The section numbers are the same in all files, so "SPEC Section 10.2" always means one section.

| Sections | File | Content |
| --- | --- | --- |
| 1–4 | [overview.md](spec/overview.md) | Concept, pillars, references, game structure, platform, art, sound, terms |
| 5–8, 25 | [hold.md](spec/hold.md) | The hold, cargo, traits, placement, mass |
| 9–13, 28–29 | [shift.md](spec/shift.md) | The warp, the slide, hits, reactions, links, clamps |
| 14–19, 26–27, 30 | [run.md](spec/run.md) | The run, contracts, arrival, the shop, the hazard forecast, payments, the end of a run, events, mods |
| 20–23 | [ui.md](spec/ui.md) | Screens, feedback, the pilot, settings, onboarding |
| 24 | [later.md](spec/later.md) | Ideas for later. Do not implement them. |

## Rules for the Spec

- Put a new section in the file of its topic. Give it the next free number.
- Do not change the number of a section. Code and docs refer to the numbers.
- Use the terms of Section 4.4 only. Do not use a synonym for a term.
- [content.md](content.md) has the content design rules. The data files in `project/data` have the values.
- The values in the spec are first values. The data files are the source of the values. Change them after playtests.
