---
name: playtest
description: Playtest Payload Protocol with agents that act as types of players. Each agent plays a run with the text player (task play) and reports on clarity, decisions, balance, and fun. The skill merges the reports into one report of suggestions. Use when the user asks for a playtest, player feedback, balance checks, "is this fun", or a check after a fix. It changes no code, data, or spec.
---

# Playtest With Agents

This skill gives the user the view of players. It does not change code, data, or the spec. A finding that the user accepts goes to `game-design` or `change`.

Talk to the user in Traditional Chinese (zh-TW).

## 1. Limits

Tell the user these limits in the report.

| Lens | Covered | Why |
| --- | --- | --- |
| Balance, economy | Yes | The agents play to the end and see the credits, the tolls, and the scrap. |
| Decisions, dominant plays | Yes | The agents find the safe placement, for example a tight corner. |
| Clarity of the rules | Partly | The agents read the text view, not the screen. |
| UI, feel, timing | No | The agents do not see the screen. |

## 2. Personas

| Persona | Plays |
| --- | --- |
| Newcomer | Reads the rules once. Accepts what looks good. Reports what confused it. |
| Optimizer | Plans each placement for the hazard. Looks for a dominant play. |
| Gambler | Takes each risky contract for the pay. Reports if risk pays off. |

## 3. Play

1. Each agent uses its own session file: `devbox run -- task play -- -s playtest/sessions/<persona>-<seed>.json new <seed>`.
2. Each agent runs `task play -- -s <file> help` first, then plays with `do "<action>; <action>"` until the run ends.
3. Use the same seed for each persona, so that the reports compare.
4. Each agent writes a report: the result, the credits after each jump, 3 moments of confusion, the dominant play if any, and 3 suggestions.

## 4. Report

1. Merge the reports into `playtest/<mode>-<seed>-<date>.md`. The folder is not in git.
2. Give the user, in zh-TW: the results, the findings by lens, and the suggestions in order of value.
3. Offer to add each finding to `docs/BACKLOG.md`. Add only the findings that the user accepts.
