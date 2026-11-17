# Payload Protocol Spec: The Warp and the Shift

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 9. The Warp

- The Warp button at the station starts the jump.
- If cargo is on the dock, a dialog asks the player to confirm. It shows what happens to that cargo (Section 15.4):
  - Freight on the dock stays at the station. Its contract pays a breach fee.
  - Kit on the dock is sold at the sell price (Section 17.3).
  - Scrap on the dock is cleared at the clear price (Section 26.3).
- The warp does not start when the hold mass is more than the maximum (Section 25).
- The warp takes the fuel fee first (Section 25).
- The incident of the jump plays before the first shift step (Section 29).
- The hazard of the jump has 1 to 3 shift steps (Section 18). The warp plays them in order. A fork step shows its direction when the warp reaches it.
- After a shift step, each cargo stays where it stopped. The next shift step starts from there.
- Each shift step has these parts, in this order:
  1. The power check (Section 12.2).
  2. The slide (Section 10).
  3. The hits (Section 10.3).
  4. The reactions (Section 11).
- After the last shift step, the arrival starts (Section 16).

## 10. The Slide

### 10.1 Movement

- In a shift step, each cargo slides in the direction of the step: left, right, up, or down.
- Each cargo slides until a wall or a cargo that stopped blocks it.
- Cargo does not push other cargo.
- The **distance** of a cargo is the number of cells that it slid in this shift step.
- The order of the cargo does not change the result. The same hold and the same direction always give the same positions.

### 10.2 Cargo That Does Not Slide

- A clamped cargo does not slide (Section 13). It blocks other cargo as a wall does.
- A Thruster cargo slides 1 cell at most in each shift step.
- A Thruster cargo that stops after 1 cell with no wall and no cargo in front of it makes no hit.
- In Low Gravity, each cargo slides 2 cells at most in each shift step (Section 28.2).

### 10.3 Hits

- When a cargo stops after a distance of 1 or more, it makes a **hit**.
- The **force** of the hit is the weight value of the cargo (Section 6.1) multiplied by its distance. A mod can change the force (Section 27.2).
  - Example: a heavy cargo (3) that slides 2 cells makes a hit with a force of 6.
- When a wall stops the cargo, the cargo takes the hit.
- When other cargo stops it, it makes one hit on each cargo that blocks it. The cargo and each cargo that blocks it take the hit. All of them take the same force.
- A cargo that a wall and other cargo stop together makes a hit on the wall and a hit on each cargo.
- If the cargo or a cargo that blocks it has the Cushion trait, the force of that hit is 0 for both.
- A cargo with a distance of 0 makes no hit. It can still take a hit from a cargo that stops on it, and a wall jolt (Section 10.4).
- A cargo can take more than one hit in a shift step. Each hit checks the break limits alone. The forces do not add.
- The screen shows the force of each hit (Section 21.2).

### 10.4 Wall Jolt

- The **front wall** of a shift step is the wall in the direction of the step.
- After the slide, each cargo with a distance of 0 and a cell next to the front wall takes a **wall jolt**: a hit with a force equal to its weight value.
  - Example: in a step to the right, a standard Fragile cargo at the right wall that did not slide takes a hit with a force of 2, and breaks.
- A clamped cargo takes the wall jolt too.
- A Cushion cargo takes the wall jolt with a force of 0.
- A cargo that slid into the front wall takes its hit of Section 10.3, and no wall jolt.
- The wall jolt does not go to the cargo behind the cargo at the wall.
- The Padded Walls mod makes the force of each wall jolt 1 less, and 0 at least (Section 27.2).

## 11. Reactions

- A reaction turns cargo into scrap, or removes it. The game does the reactions after all hits of a shift step.
- A reaction can start more reactions. The game does them until no new reaction starts. Then the next shift step starts.
- A Shield can cancel a reaction (Section 12.2).
- A cargo has one reaction at most from its hits. When it has more than one trait that reacts, only the first in this order happens: explosion, leak, break, short (a Radiation Belt, Section 28.2).
  - Example: a Fuel Drum (Fluid, Volatile) leaks at a force of 2. At a force of 3 or more, it explodes and does not leak.
- A cargo that became scrap has no traits, so it does not react again.
- A route environment can change a break limit (Section 28.2).

### 11.1 Break

- A Fragile cargo that takes a hit with a force of 2 or more breaks. It becomes scrap.

### 11.2 Explosion

- A Volatile cargo that takes a hit with a force of 3 or more explodes.
- The **blast area** is each cell at a distance of 1 from a cell of the Volatile cargo, diagonal cells too.
- The explosion has these results:
  - The Volatile cargo is removed. Its cells become empty. It does not become scrap.
  - Each freight and each kit with a cell in the blast area becomes scrap. Heavy cargo is not affected.
  - Each scrap with a cell in the blast area is removed. Its cells become empty.
  - Each other Volatile cargo with a cell in the blast area explodes too.
- An explosion is not a hit. It has no force.

### 11.3 Leak and Short

- A Fluid cargo that takes a hit with a force of 2 or more leaks. It becomes scrap.
- Each Electronic cargo next to a cargo that leaks shorts. It becomes scrap.

## 12. Links

A **link** is a rule between two cargo that are next to each other.

### 12.1 Cold Chain

- At the arrival, each Perishable cargo must be next to a Cooler.
- A Perishable cargo that is not next to a Cooler spoils. It becomes scrap before the delivery (Section 16). Its contract does not pay for it.
- Only the positions at the arrival count. A Perishable cargo can lose its Cooler in one shift step and find it again in the next.
- With the Cryo Line mod, a Cooler keeps each Perishable cargo within 2 cells fresh (Section 27.2).

### 12.2 Power and Shields

- At the start of each shift step, the power check looks at each Shield. A Shield has **power** in that shift step when it is next to a Battery that is not scrap.
- A Shield has 1 **charge** at the start of each jump.
- A Shield with power protects itself and each cargo next to it.
- When a reaction would make a protected cargo scrap or make it explode, a protecting Shield with a charge spends it. The cargo stays intact. The reaction does not happen.
- A Shield does not stop the removal of scrap in a blast area. A Shield does not stop a spoil (Section 12.1).
- When two Shields protect the same cargo, the Shield with the smaller `(y, x)` of its origin spends its charge first.
- A Battery is Electronic. A leak next to it can short it. Then the Shield has no power in the next shift steps.
- With the Array Power mod, a Battery powers each Shield within 2 cells (Section 27.2).
- In a Magnetic Storm, no Shield has power, with the Array Power mod too (Section 28.2).

### 12.3 Link Display

- At the station, a line connects each two cargo that have a link now: a Cooler and a Perishable cargo, and a Battery and a Shield.
- A Perishable cargo with no Cooler next to it shows a warning icon.
- A Shield with no power shows a "no power" icon.
- The hold marks the front wall of the first shift step of the next jump (Section 10.4) with a band of yellow and black stripes.
- Each cargo at that wall shows a warning icon when its wall jolt would make it react (Section 11). The station shows this for the first step only: the places in the next steps depend on the slides.

## 13. Clamps

- The player has a number of clamps. A run starts with 1 clamp. The player can buy more (Section 17.2).
- At a station, the player puts a clamp on a cargo in the hold: drag the clamp from the clamp panel onto the cargo. A click on the clamp of a cargo takes it off.
- A cargo can have one clamp at most.
- A clamped cargo does not slide in any shift step (Section 10.2).
- A clamped cargo takes hits as other cargo do. A clamp does not stop a reaction.
- When a clamped cargo leaves the hold or is removed, its clamp goes back to the clamp panel.
- A clamp can go on scrap.
- The player cannot put a clamp on a cargo on the dock.

## 28. Route Environments

An **environment** is a rule of the route for all jumps of a leg.

### 28.1 When Environments Happen

- Leg 1 has no environment. The seed selects one environment for leg 2 and one for leg 3. The two are not the same.
- The station shows the environment of the leg in the top bar and in the hazard panel. The mouse on it shows its rule. The warp shows it in the banner before the first step.

### 28.2 The Environments

| Environment | Rule |
| --- | --- |
| **Low Gravity** | Each cargo slides 2 cells at most in each shift step. |
| **Magnetic Storm** | No Shield has power. The Array Power mod does not change this. |
| **Radiation Belt** | An Electronic cargo that takes a hit with a force of 2 or more shorts. It becomes scrap. |
| **Heat Zone** | The break limit of Volatile is 2, and the break limit of Fluid is 1. |

- An environment is stronger than a mod. When an environment and a mod give different rules, the environment is correct.
- `rules.json` has the numbers of the environments.

## 29. Incidents

An **incident** is an event of the route that happens before the first shift step of a warp.

### 29.1 When Incidents Happen

- Leg 1 has no incidents. In leg 2, a jump has an incident with a chance of one half. In leg 3, each jump has an incident.
- A jump has one incident at most.
- The seed selects the kind and the place of the incident when the station opens. The place has a cargo in it when the station opens, if one can.

### 29.2 The Incidents

| Incident | Place | Rule |
| --- | --- | --- |
| **Meteor** | A column | The cargo with the top cell in that column takes a hit with a force of 3. The rules of Section 11 apply. When the column is empty, nothing happens. |
| **Ion Pulse** | A row | Each Electronic cargo with a cell in that row shorts. It becomes scrap. |
| **Hull Breach** | A cell | When the cell is empty, a debris appears in it: a scrap of 1 cell. When a cargo is in the cell, that cargo becomes scrap, and no debris appears. |

- A debris has the name Hull Debris. No contract has it as freight.
- The reactions of an incident are reactions of Section 11: a Shield can cancel them, and they can start a chain.
- The power check of Section 12.2 happens before the incident.

### 29.3 Display

- The hazard panel shows the incident as the first card, before the shift steps: its name and its place ("Meteor · Column 4").
- The hold marks the place of the incident: the column, the row, or the cell.
- The warp plays the incident before the first shift step, with a banner.
