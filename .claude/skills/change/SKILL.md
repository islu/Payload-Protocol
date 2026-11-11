---
name: change
description: The one entry point for any Payload Protocol work that changes the game - a rule change, a bug fix, new content or values, a new trait or mechanic, or a design idea. It classifies the request, routes it, checks the spec and the backlog, pins each rule with a test that fails first, and reports. Use it whenever the user asks to add, change, adjust, remove, or fix anything in the game, even if they do not name a skill.
argument-hint: "<what to change, add, or fix> [--go]"
---

# Change the Game

Request: `$ARGUMENTS`

## Rules for All Steps

- **The spec tells what must happen. A test shows that it happens.** Each rule that this change adds or changes is in the spec and has a test that fails when the rule breaks.
- **Each check message gives its spec section**: `check(vase.kind == Defs.KIND_SCRAP, "a Fragile cargo breaks at force 2 (SPEC Section 11.1)")`.
- **The spec has what the player can see and the design choices.** Put the implementation in code comments and tests.
- **The user decides the design.** When a rule can go two ways, ask. Do not choose.
- **Do not change the spec without approval.** Do not commit. The user commits.
- Talk to the user in Traditional Chinese (zh-TW). Keep identifiers, paths, and commands in English.

## 1. Classify and Route

| Kind | When | Procedure |
| --- | --- | --- |
| **Design idea** | A feeling or an idea with no spec rule yet ("too easy", "what if"). | Load `game-design`. Come back after the user approves the spec. |
| **Balance** | Numbers in `project/data` only. | Steps 2, 6, 8. Run `task test -- data` and a playtest if the change is large. |
| **Content** | New or changed cargo, contracts, kit pools, or lines. Existing traits express it. | Steps 2, 6, 8. Follow `docs/content.md`. |
| **New mechanic** | A new trait, reaction, bonus type, link, or service. | All steps. Load `game-rules`. |
| **Rule change** | A rule of the spec, changed on purpose. | All steps. |
| **Bug fix** | The code does not agree with the spec, and the spec is correct. | All steps. |

## 2. Find (Read Only)

1. Read the table of `docs/spec.md`. Then read only the sections that the request touches. Search the spec for the key words too. Quote the sentences that the change touches.
2. Read `docs/BACKLOG.md`. Name each item that this change touches, and offer to include it.
3. Find each place of the rule in the code: data and `Catalog` checks → `project/rules` → `RunView` → `GameState` → scenes → `project/tools/play.gd` → tests.

## 3. Plan and Stop

Show the user, in zh-TW:

- **Spec 修改**: the sentences to add or replace, file by file.
- **待決策**: each design choice that the request does not answer, with the options.
- **修改位置**: each file to change, by layer.
- **測試規劃**: one row for each rule.

  | # | 規則（spec 出處） | 類型 | 測試（檔案 → 方法） | 現況 | 改之前會怎樣失敗 |
  | --- | --- | --- | --- | --- | --- |

Then **stop** and wait for approval. Skip the stop only if the request has `--go` and there is no 待決策.

## 4. Spec, Then Failing Tests

1. Write the approved spec changes.
2. Write the tests. Run `devbox run -- task test -- <file>`. **Show that they fail for the expected reason.** A test that passes before the change tests nothing.

## 5. Implement

1. Change the layers in this order: data and its check → rules → view → `GameState` → scenes → text player → text.
2. Update each doc, skill, and backlog item that the change made stale, in the same change.

## 6. Check

1. Run `devbox run -- task fmt`.
2. Run `devbox run -- task check:quiet`. It must pass.

## 7. Report

Write in zh-TW: 改了什麼 (with links), 規則 ↔ 測試 (改之前 / 改之後), 檢查 (each command and its result), 沒有測試保護的部分, and the backlog items that you added or deleted.
