# Payload Protocol Spec: Screens and Feedback

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 20. Screens

### 20.1 Title

- The title screen has these buttons: New Run, How to Play, Settings, and Quit.
- The background shows a starfield that moves slowly.

### 20.2 Station

The station screen has these areas:

| Area | Position | Content |
| --- | --- | --- |
| Top bar | Top | The sector and the jump ("Sector 2 · Jump 1"), the credits, the toll of this sector, and the jumps before the toll. |
| Hazard panel | Top, below the top bar | The shift steps of the next jump (Section 18). |
| Dock | Left | The cargo on the dock (Section 8.1). |
| Contract board | Left, below the dock | The 3 contracts, with Accept and Cancel buttons (Section 15). |
| Hold | Center | The grid and its cargo, the links, and the clamps. |
| Shop | Right | The kit offers, Reroll, the services, and the sell area (Section 17). |
| Clamp panel | Right, below the shop | The free clamps (Section 13). |
| Warp button | Bottom right | Starts the warp (Section 9). |
| Pilot box | Bottom left | The line of the pilot (Section 22). |

- Each contract card shows its client, its freight with small shapes, its pay, and its bonus.
- When the mouse is on a contract, the hold marks the freight of that contract.

### 20.3 Warp

- The hold stays at the center. The other panels go out of the screen.
- The background shows the warp: stars become lines.
- For each shift step:
  1. An alarm sounds. A banner shows the arrow and the direction for 0.6 seconds.
  2. The ship tilts a little in the direction.
  3. The slide plays (Section 21.1). Then the hits and the reactions play (Section 21.2).
- A click or the Space key during the warp makes the rest of the warp play at 4× speed.

### 20.4 Arrival Report

- The report shows each contract: its pieces (delivered, scrap, spoiled, lost, or breached), its pay, and its bonus. A lost piece is a piece that an explosion removed.
- It shows the total credits that the jump gave.
- The pilot speaks a line about the result.
- A Continue button goes to the next station, or to the toll gate.

### 20.5 Toll Gate

- The toll gate shows the credits, the toll, and the credits after the toll.
- When the player can pay, the button is Pay. When the player cannot pay, the screen shows the loss, and the button goes to the run end screen.

### 20.6 Run End

- Section 19.2 has the content.

### 20.7 Pause

- Esc opens the pause menu at the station and during the warp. It has these buttons: Resume, How to Play, Settings, and Abandon Run.
- Abandon Run asks the player to confirm. Then it goes to the title screen.

## 21. Feedback

### 21.1 Placement and Slide

- A drag lifts the cargo: a shadow and a scale of 1.05.
- A valid drop plays the clack sound and a small bounce.
- In a slide, all cargo of the shift step moves at the same time, at the same speed (8 cells each second). Each cargo stops at its distance.
- A slide plays a low rumble.

### 21.2 Hits

- Each hit shows sparks at the contact edge and the force number above the cargo.
- The screen shakes. A larger force makes a larger shake. A setting turns the shake off (Section 23.1).
- A hit with a force of 0 plays a soft sound. A hit with a force of 1 or more plays a metal hit sound. A larger force plays a louder sound.

### 21.3 Reactions

| Reaction | Visual | Sound |
| --- | --- | --- |
| Break | Shards fly. The cargo turns gray with cracks. | Glass break |
| Explosion | A white flash, a ring of fire on the blast area, a large shake, and a hit stop of 0.1 seconds. | Explosion |
| Leak | Liquid spreads to the cells next to the cargo. | Splash |
| Short | Electric sparks on the cargo. | Electric buzz |
| Spoil | A green cloud at the arrival. | Squelch |
| Shield | A blue bubble on the protected cargo. | Shield hum |

- Reactions of one chain play one after the other, 0.15 seconds apart, so that the player can see the chain.

### 21.4 Station

- A purchase plays a coin sound. A sale and a delivery play a coin sound too.
- The credits count up or down in the top bar.
- The link lines glow and move slowly.

## 22. The Pilot

- The pilot is the AI of the ship. Its name is **PIP**. The pilot box shows its icon and one line.
- The pilot speaks at these events:
  - The station opens: a line about the hazard.
  - The arrival: a line about the result (all intact, a break, an explosion, a chain of explosions, a leak, a spoil).
  - The toll gate: a line about the toll.
  - The run end: a line about the win or the loss.
- `project/data/lines/` has the lines for each event. The game selects one line with the seed. It does not select the same line two times in a row.
- The lines are funny and short. A line has 90 characters at most in English.

## 23. Settings and Onboarding

### 23.1 Settings

- The settings are: music volume, sound volume, the CRT filter (on or off), the screen shake (on or off), the warp speed (1× or 2×), fullscreen (on or off), the language (English or 繁體中文), and hints (on or off).
- The game keeps the settings in `user://settings.cfg`.
- A change of a setting applies at once. When the player changes the language, all text on the screen changes at once, also in the open menus.

### 23.2 How to Play

- How to Play has 4 pages with a picture on each page:
  1. Contracts and the hold: accept, drag, and rotate.
  2. The warp: the slide, distance, weight, and force.
  3. Traits and reactions.
  4. Links, clamps, the shop, and tolls.

### 23.3 Hints

- When hints are on, the pilot gives hints in the first run: one hint for each new thing that the player sees for the first time.
- The first hints are: accept a contract, drag a cargo, rotate a cargo, read the hazard, warp.
- After the first win or the first 3 runs, the game turns hints off. The player can turn them on in the settings.
