# Payload Protocol Spec: Overview

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 1. Concept

Payload Protocol is a single-player puzzle game about cargo in the hold of a spaceship. The player is a freight pilot.

- At each station, the player accepts contracts and packs their freight into the hold. The hold is a grid. Each cargo has a shape.
- Then the player warps to the next station. The warp shifts the hold: all cargo slides in one direction, then in the next direction.
- Cargo that slides hits walls and other cargo. Hits break fragile cargo, explode volatile cargo, and make fluid cargo leak.
- At the next station, intact freight leaves the hold and pays credits. Broken cargo stays in the hold as scrap.
- At the end of each sector, the player pays a toll. A player who cannot pay loses the run.

### 1.1 Design Pillars

- **The player can read each shift before the warp.** The station shows each direction of the next warp, in order. A shift has no random parts. The same hold and the same directions always give the same result.
- **Space is always tight.** Freight leaves at each station, but scrap stays. Kit stays too. The player must decide what to keep.
- **A disaster is a show.** A break, a chain of explosions, or a leak has strong feedback and a line from the pilot. A loss must be funny, not only a loss.
- **A run is short.** A run takes about 20 to 30 minutes.

## 2. References

These games are references for mechanics only. Do not copy their art, names, items, or text.

- Backpack Hero (Thunder Lotus): a grid inventory, cargo with shapes, rotation, and items that act on their neighbors.
- 2048 (Gabriele Cirulli): all tiles slide in one direction until a wall or another tile stops them.

## 3. Game Structure

- A **run** has 3 **sectors**. Each sector has 3 **jumps**. A run has 9 jumps.
- Each jump has three phases, in this order:
  1. **Station:** the player accepts contracts, uses the shop, and packs the hold (Sections 15 and 17).
  2. **Warp:** the shift steps of the jump play (Sections 9 to 12).
  3. **Arrival:** freight is delivered and pays (Section 16).
- After the arrival of the last jump of a sector, the player pays the toll of that sector (Section 19).
- The run ends in a win when the player pays the toll of the last sector. It ends in a loss when the player cannot pay a toll.
- Nothing stays after a run. Version 1 has no unlocks between runs (Section 24).
- Each run has a **seed**. The seed sets the contracts, the shop offers, and the hazards. Two runs with the same seed and the same player actions have the same result.
- The game uses no random numbers in a shift step.

## 4. Platform, Art, and Sound

### 4.1 Platform

- The first platform is the web: the game runs in a browser on itch.io. Builds for macOS and Windows are a second option.
- The controls are the mouse and the keyboard.
- The base resolution is 1920×1080. The screen scales with the window and keeps its aspect.
- The languages are English and Traditional Chinese (zh-TW). English is the source language.

### 4.2 Art

- The art style is a clean sci-fi dashboard: a dark navy background, thin bright lines, and flat panels.
- The game draws all cargo with code or with SVG files. Do not use pixel art.
- Each trait has one color and one icon. Each cargo shows the icon of each trait. Do not show a trait with a color only.
- A **CRT filter** draws scanlines, a small curve, and a vignette on the full screen. A setting turns it off (Section 23.1).
- The font is jf open huninn 2.1 (SIL Open Font License 1.1). It has Latin and Traditional Chinese glyphs.
- An art file can replace a drawn shape with no code change (the `fx-art` skill has the file names).

### 4.3 Sound

- Sounds and music come from CC0 sources, for example Kenney. Record each file in [assets.md](../assets.md).
- Each event in Section 21 has a sound.
- A setting sets the volume of the music and of the sounds (Section 23.1).

### 4.4 Terms

Use these terms in the spec, the code, the data, and the text of the game. Do not use other words for them.

| Term | Meaning |
| --- | --- |
| **hold** | The grid of the ship where cargo goes (Section 5). |
| **cell** | One square of the hold. |
| **cargo** | Each thing that can be in the hold: freight, kit, or scrap. |
| **freight** | Cargo of a contract. It leaves the hold at the arrival (Section 6.2). |
| **kit** | Cargo that the player buys. It stays in the hold until the player sells it (Section 6.3). |
| **scrap** | Broken cargo. It stays in the hold until the player clears it (Section 6.4). |
| **trait** | A property of cargo that gives it a rule (Section 7). |
| **dock** | The area at a station for cargo that is not in the hold (Section 8.1). |
| **station** | The place between two jumps. |
| **jump** | One travel from a station to the next station. |
| **sector** | A group of 3 jumps that ends with a toll. |
| **hazard** | The list of shift steps of a jump (Section 18). |
| **shift step** | One direction of a hazard. All cargo slides in that direction (Section 10). |
| **slide** | The movement of cargo in a shift step. |
| **hit** | What happens when cargo stops after a slide (Section 10.3). |
| **force** | The strength of a hit (Section 10.3). |
| **next to** | Two cargo are next to each other when a cell of one shares an edge with a cell of the other. Diagonal cells are not next to each other. |
| **credits** | The money of the player. |
| **contract** | An order to carry freight to the next station for pay (Section 15). |
| **toll** | The credits that the player pays at the end of a sector (Section 19). |
| **clamp** | A lock that stops a cargo from a slide (Section 13). |
| **pilot** | The ship AI that speaks lines (Section 22). |
