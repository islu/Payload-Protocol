---
name: game-design
description: Design Payload Protocol with the user through rounds of multiple-choice questions - mechanics, traits, contracts, the run, UI, UX, and the core loop. Asks questions with options and a recommendation, then changes the spec after approval. Use whenever the user wants to brainstorm, discuss, rethink a rule, or shape an idea before code, even if they only say "I have an idea", "what if", 發想, 討論, 設計, or 改 spec. Do not use it to implement a rule that the spec already has (use change).
---

# Design With the User

This skill is a conversation. Do not write code. The output is a decision summary, and spec changes after the user approves them.

Talk to the user in their language. Write the spec text in English with Simplified Technical English (`CLAUDE.md`).

## 1. Read Before You Ask

1. Read `docs/spec.md` and the spec files of the topic.
2. Read the pillars in Section 1.1: the player can read each shift, space is always tight, a disaster is a show, a run is short.
3. Read Section 24 (`docs/spec/later.md`). If the idea is there, build on it.
4. Read `docs/BACKLOG.md`. A **To Decide** item can be the question of this topic.
5. When the spec answers a question, quote the section. Do not ask it.

## 2. Ask in Rounds

Use `AskUserQuestion` for every question.

- Ask 1 to 4 questions that do not depend on each other.
- Give 2 to 4 options. Put the recommended option first, with "(Recommended)".
- In each description, give the trade-off in one sentence: what the player feels, and what it costs.
- For a rule, put a short example hold in `preview` (a text grid). For UI, put an ASCII mockup.
- Go in this order: feel → rule → edge cases → numbers.

## 3. Test the Idea

- **Play it in text.** Draw a hold, a hazard, and the result of each shift step. A rule that you cannot draw is not clear yet.
- **Find the dominant choice.** If one placement is always best (for example a tight corner), the decision is not real.
- **Check readability.** The player must see each new rule on the screen before the warp (Section 1.1).
- **Check the words.** Each new term goes in Section 4.4 and `terms.json`, with one meaning.
- **Ask the players.** Offer `/playtest` for an idea that changes how a run plays.

## 4. Close the Topic

1. Write a decision summary: Decided, Open (playtest questions), Later, Cost (data only or a new mechanic), and Changes ("Section X.Y: old rule → new rule").
2. Ask the user to approve it.
3. After approval, write the spec. A new rule goes in a new section with the next free number. Do not change section numbers. Add Open questions to `docs/BACKLOG.md`.
4. To implement now, continue with `change`.
