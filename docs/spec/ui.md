# Payload Protocol Spec: Screens and Feedback

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 20. Screens

### 20.1 Title

- The title screen has these buttons: New Run, How to Play, Settings, and Quit.
- The background shows a starfield that moves slowly.
- The title, a tagline, and the buttons are in the center. The version is at the bottom right.

### 20.2 Station

The station screen has these areas:

| Area | Position | Content |
| --- | --- | --- |
| Top bar | Top | Four groups: (1) the leg, and a dot for each jump of the leg; (2) the credits, and a bar of the credits against the payment of this leg, with the jumps before the payment; (3) a bar of the hold mass, with a mark at the mass limit and a mark at the maximum (Section 25); (4) a badge with the icon and the name of the environment of the leg, with its rule when the mouse is on it (Section 28). A gear button at the right opens the pause menu (Section 20.7). |
| Pilot box | Bottom left | The portrait and the line of the pilot, in a wide box (Section 22). |
| Hazard panel | Center, at the left of the hold, from top to bottom | The shift steps of the next jump in order (Section 18). Each step is a card with a large arrow, its number, and its direction. A fork step shows its two directions and a question mark. |
| Dock | Left, top | The cargo on the dock (Section 8.1). |
| Contract board | Left, below the dock | The 4 contracts, with Accept and Cancel buttons (Section 15). |
| Hold | Center | The grid and its cargo, the links, and the clamps. Each cell is 100 pixels, the size of the cargo images (Section 4.2). |
| Shock bay | Above the hold | The cells of the shock bay, after its purchase (Section 31.2). |
| Mod bar | Below the hold | A card with the icon of each mod of the ship (Section 27). The mouse on a card shows the name and the rule of the mod, and marks the area of the mod on the hold. |
| Shop | Right | The kit offers, Reroll, the services, and the sell area (Section 17). |
| Clamp panel | Right, below the services | The free clamps (Section 13). |
| Warp button | Bottom right | Starts the warp (Section 9). The warp checklist is above it. |

Contracts and the dock:

- Each contract card shows on its first line the client, the total pay, and the mass of the contract. The second line shows the freight and the bonus. The same freight shows one time, with its image, "×N", and its trait icons.
- The mouse on a contract card shows the details: the number of pieces, the pay for each piece, the rules of the traits, and the mass after it is accepted (the mass of the hold and the dock, plus the mass of the contract).
- The mass of a contract that is not accepted is yellow when the mass after it is above the mass limit (a fuel fee), and red when it is above the maximum.
- An accepted contract has a bright border and shows "Loaded N/M": N pieces of its M pieces are in the hold.
- When the mouse is on a contract card, the hold marks the freight of that contract.
- The dock title shows the number of cargo on the dock. The dock shows its cargo at 48 pixels for each cell. An empty dock is one line of text.

The hazard:

- When the mouse is on a hazard card, the hold marks the front wall of that step with the stripes of Section 12.3. A fork step that the player does not know marks both walls. The wall jolt warnings are for the first step only.
- A fork step that a Sensor shows has a Sensor icon and its one direction (Section 18).

The shop and the services:

- Each kit offer shows its image, each trait with its icon and its rule, its weight, and its price on the Buy button. A price that is more than the credits shows in red.
- Each kit offer shows how it helps the accepted freight on the dock and in the hold: "Helps N of your freight". A Cooler counts Perishable freight. A Cushion counts Fragile freight. A Shield counts freight that is Fragile, Volatile, Fluid, or Electronic. A Battery counts the Shield kit on the dock and in the hold. A Sensor shows "The next jump has a fork step" when it does. Other kit and a count of 0 show nothing.
- Each service shows the value now and the value after the purchase: the clamps (1/4 → 2/4), the shock bay (none → 2×2, or 2×2 → 3×2), and the mass limit (24 → 30).
- The sell area is a small bar. During a drag of a kit, it is green and shows the sell price. During a drag of a scrap, it is red and shows the clear price.

The warp:

- The **warp checklist** above the Warp button shows: the fuel fee, the number of cargo on the dock, the number of cargo with a wall jolt warning (Section 12.3), and the incident of the jump (Section 29.3).
- An Undo button and Ctrl+Z take back the last action at this station: a placement, a contract, a purchase, a sale, a reroll, or a service. Undo does not go back past the arrival at the station. After an undo, the same action gives the same result again.

### 20.3 Warp

- The hold stays at the center. The other panels go out of the screen.
- The background shows the warp: stars become lines.
- Before the first shift step, a banner shows the environment of the leg. Then the incident plays, with a banner (Section 29.3).
- For each shift step:
  1. An alarm sounds. A banner shows the arrow and the direction for 0.6 seconds.
  2. The ship tilts a little in the direction.
  3. The slide plays (Section 21.1). Then the hits and the reactions play (Section 21.2).
- A click or the Space key during the warp makes the rest of the warp play at 4× speed.

### 20.4 Arrival Report

- The report shows each contract: its pieces (delivered, scrap, spoiled, lost, or breached), its pay, and its bonus. A lost piece is a piece that an explosion removed.
- The report shows a card for each contract: the client, its pay, and its pieces. Pieces with the same freight and the same state share one image, with "×N" and an icon of the state.
- Below the cards, a ledger shows the deliveries, the bonuses, the insurance (Section 27.2), the breach fees, the penalties (Section 30.1), the kit sold from the dock, the scrap cleared from the dock (Section 26.3), the fuel fee, and the net. Then it shows the credits before the warp and after the arrival.
- The pilot speaks a line about the result, with the portrait of the pilot.
- Delivered freight stays in the hold at half alpha, with a check mark, until Continue.
- A Continue button goes to the next station, or to the payment screen.
- When the report covers the hold, the hold moves to the left.
- When the mouse is on a line of pieces, the hold marks those pieces at their place at the end of the warp.
- A Replay button plays the warp again from the start, at half speed. A click or the Space key during the replay makes it faster (Section 20.3). The replay plays no coin sound.

### 20.5 Payment

- The payment screen shows the credits, the payment, and the credits after the payment.
- When the player can pay, the button is Pay. When the player cannot pay, the screen shows the loss, and the button goes to the run end screen.

### 20.6 Run End

- Section 19.2 has the content.

### 20.7 Pause

- Esc opens the pause menu at the station and during the warp. A gear button at the top right of the station and the warp opens it too.
- At the station, Esc puts back a held cargo first (Section 8.3). With no held cargo, it opens the pause menu. It has these buttons: Resume, How to Play, Settings, and Abandon Run.
- Abandon Run asks the player to confirm. Then it goes to the title screen.

### 20.8 Event

- When a station with an event opens, the event shows at the center, above the dark station (Section 26).
- The speaker stands at the left of the dialogue box, outside a frame. Each event names its speaker. The speakers are a small set of characters, for example a pirate and a mechanic (content.md).
- All speakers have the same proportions: their heads have the same size and are at the same height. Each speaker fades out at the bottom edge of the dialogue box.
- The dialogue box shows the name of the speaker, the name of the event, its text, and a button for each choice. Each button shows the text of the choice, its cost, and its effects.
- A choice that the player cannot select is disabled (Section 26.2).
- The player cannot use the station until the player selects a choice. Esc and the gear button do nothing.

### 20.9 Mod Choice

- The mod choice shows a card for each mod: its icon, its name, and its rule. The icon is the same as on the mod bar (Section 20.2). A click on a card selects the mod (Section 27.1).
- The player must select a mod.

## 21. Feedback

### 21.1 Placement and Slide

- A drag lifts the cargo: a shadow and a scale of 1.05.
- A valid drop plays the clack sound and a small bounce.
- In a slide, all cargo of the shift step moves at the same time, at the same speed (8 cells each second). Each cargo stops at its distance.
- A slide plays a low rumble.

### 21.2 Hits

- Each hit shows a spark flare at the contact edge that sprays back against the slide, and the force number above the cargo in large bold digits with a dark outline.
- The screen shakes. A larger force makes a larger shake. A setting turns the shake off (Section 23.1).
- A hit with a force of 0 plays a soft sound. A hit with a force of 1 or more plays a metal hit sound. A larger force plays a louder sound.

### 21.3 Reactions

| Reaction | Visual | Sound |
| --- | --- | --- |
| Break | Glass shards fly out from the cargo. The cargo turns gray with cracks. | Glass break |
| Explosion | A white flash, a fire blast with smoke, a glow on the blast area, a large shake, and a hit stop of 0.1 seconds. | Explosion |
| Leak | A splash of liquid on the cargo. | Splash |
| Short | A bolt of electricity hits the cargo. | Electric buzz |
| Spoil | A green cloud with bubbles at the arrival. | Squelch |
| Shield | A dome of force on the protected cargo takes the hit. | Shield hum |

- Reactions of one chain play one after the other, 0.15 seconds apart, so that the player can see the chain.

### 21.4 Station

- A purchase plays a coin sound. A sale and a delivery play a coin sound too. Each coin sound shows a gold sparkle: at the credits on the station, and at the title of the arrival report.
- The credits count up or down in the top bar.
- The link lines glow and move slowly.

### 21.5 Losses

- When a freight becomes scrap in the warp, its lost pay shows above it ("−8"). The event log gives the lost pay. A kit shows no number.
- From the second reaction of a chain, the warp shows "Chain ×N". N is the number of reactions of that chain so far.
- At the end of the warp, the warp shows the total lost pay ("Lost −24") before the arrival report.

## 22. The Pilot

- The pilot is the AI of the ship. Its name is **MAGELLAN**. The name does not change with the language. The pilot box shows its pixel art portrait and one line.
- The portrait blinks. A new line types out at 40 characters each second, and the mouth of the portrait moves while it types.
- The pilot speaks at these events:
  - The station opens: a line about the hazard.
  - The arrival: a line about the result (all intact, a break, an explosion, a chain of explosions, a leak, a spoil, or no freight).
  - The payment screen: a line about the payment.
  - The run end: a line about the win or the loss.
- `project/data/lines/` has the lines for each event. The game selects one line with the seed. It does not select the same line two times in a row.
- The lines are funny and short. A line has 90 characters at most in English.

## 23. Settings and Onboarding

### 23.1 Settings

- The settings are: music volume, sound volume, the CRT filter (on or off), the screen shake (on or off), the warp speed (1× or 2×), fullscreen (on or off), the language (English or 繁體中文), hints (on or off), and the pick up of the next cargo (on or off, Section 8.2).
- The game keeps the settings in `user://settings.cfg`.
- Each switch shows its state clearly: off is an outlined capsule, on is a filled capsule.
- A change of a setting applies at once. When the player changes the language, all text on the screen changes at once, also in the open menus.

### 23.2 How to Play

- How to Play has 4 pages. Each page has a large picture and 3 short points:
  1. Contracts and the hold: accept, drag, and rotate.
  2. The warp: the slide, distance, weight, and force.
  3. Traits and reactions.
  4. Links, clamps, the shop, and payments.
- Each picture shows the cargo images of Section 4.2.

### 23.3 Hints

- When hints are on, the pilot gives hints in the first run: one hint for each new thing that the player sees for the first time.
- The first hints are: accept a contract, drag a cargo, rotate a cargo, read the hazard, warp.
- After the first win or the first 3 runs, the game turns hints off. The player can turn them on in the settings.
