# Payload Protocol Spec: The Hold and Cargo

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 5. The Hold

- The hold is a grid of cells. At the start of a run, it has 6 columns and 6 rows.
- A hold upgrade adds one column at the right or one row at the bottom (Section 17.2). The maximum is 8 columns and 8 rows.
- A cell is at `(x, y)`. `(0, 0)` is the cell at the upper left. `x` goes to the right. `y` goes down.
- The edges of the grid are the **walls**.
- Each cell is empty or has one cargo.

## 6. Cargo

### 6.1 Properties

Each cargo has these properties:

| Property | Meaning |
| --- | --- |
| `id` | The definition ID. It is snake_case. |
| `name` | The name that the player sees. |
| `kind` | `freight`, `kit`, or `scrap`. |
| `shape` | The cells of the cargo, relative to its origin `(0, 0)`. A shape has 1 to 5 cells. All cells of a shape are connected by edges. |
| `weight` | `light` (1), `standard` (2), or `heavy` (3). The number is the weight value of Section 10.3. |
| `traits` | A list of traits (Section 7). It can be empty. |
| `value` | Freight: the pay for one intact piece is in its contract (Section 15). Kit: the price in the shop. |

- **Rotation** turns a shape 90° clockwise. A cargo has 4 rotations. The game keeps the rotation of each cargo in the hold.
- After a rotation, the game moves the shape so that its smallest `x` and its smallest `y` are 0.

### 6.2 Freight

- Freight comes only from contracts (Section 15).
- Freight goes to the next station. Each contract ends at the arrival of the jump after the player accepts it.
- At the arrival, intact freight leaves the hold (Section 16).

### 6.3 Kit

- The player buys kit in the shop (Section 17).
- Kit stays in the hold after each arrival. The player can sell it at a station (Section 17.3).
- Kit has traits that help freight, for example Cooler, Battery, Shield, and Cushion (Sections 7 and 12).
- Kit can break, explode, or short as freight can. Broken kit becomes scrap.

### 6.4 Scrap

- When a reaction breaks a cargo, the cargo becomes scrap (Section 11).
- Scrap has the same shape, the same rotation, and the same cells as the cargo before it.
- Scrap is light. It has no traits and no value.
- Scrap stays in the hold until the player clears it at a station (Section 17.4).
- The player can move scrap inside the hold. The player cannot put scrap on the dock.
- Scrap slides as other cargo do. Thus scrap can be a wall for other cargo.

## 7. Traits

A cargo can have more than one trait.

| Trait | Rule | Section |
| --- | --- | --- |
| **Fragile** | Breaks at a hit with a force of 2 or more. | 11.1 |
| **Volatile** | Explodes at a hit with a force of 3 or more. The explosion breaks cargo around it. | 11.2 |
| **Fluid** | Leaks at a hit with a force of 2 or more. The leak shorts each Electronic cargo next to it. | 11.3 |
| **Electronic** | Shorts when a Fluid cargo next to it leaks. | 11.3 |
| **Perishable** | Spoils at the arrival if it is not next to a Cooler. | 12.1 |
| **Thruster** | Slides 1 cell at most in each shift step. | 10.2 |
| **Cushion** | Each hit on it or by it has a force of 0. | 10.3 |
| **Cooler** | Keeps each Perishable cargo next to it fresh. | 12.1 |
| **Battery** | Powers each Shield next to it. | 12.2 |
| **Shield** | When it has power, it protects each cargo next to it from one reaction in each jump. | 12.2 |
| **Sensor** | At the station, it shows the direction of the fork step. | 18.1 |

- A **break limit** is the force at which a trait reacts: Fragile 2, Volatile 3, Fluid 2. `rules.json` has the values.
- A cargo with no Fragile, Volatile, or Fluid trait never breaks from a hit. It can break only from an explosion, a short, or a spoil.

## 8. Placement

### 8.1 The Dock

- The dock is an area at the left of the station screen. It has cargo that is not in the hold.
- The dock has no size limit. The dock shows its cargo in a list.
- New freight and new kit go to the dock first. A scrap that an event gives goes to the dock too (Section 26.3).
- The **Load all** button puts each cargo on the dock into the hold, in the order of the dock. Each cargo goes to the first place where it fits: the cells are tried row by row from (0, 0), first in its rotation now, then in the next rotations. A cargo that does not fit stays on the dock.

### 8.2 Move and Rotate

- The player moves cargo only at a station. The warp and the arrival do not let the player move cargo.
- The player can move a cargo from the dock to the hold, from the hold to the dock, and inside the hold. The player moves a cargo in one of two ways:
  - **Drag:** press the left mouse button on the cargo, move the mouse, and release the button.
  - **Pick up:** click the cargo. It follows the mouse. Click again to drop it.
- A click is a press and a release less than 8 pixels apart.
- After the player drops a picked-up cargo from the dock into the hold, the next cargo on the dock is picked up. Thus the player can place a full contract with clicks. Esc puts the held cargo back and ends it. A drag does not pick up the next cargo.
- While the player holds a cargo, a right click or the R key rotates it. Esc puts it back in its last place.
- A right click on a cargo in the hold rotates it in its place. If the new shape does not fit there, the game tries the places 1 cell away, in this order: left, right, up, down, then up-left, up-right, down-left, down-right. The cargo goes to the first place where it fits.
- If no place fits, the cargo does not change, and the game plays the deny sound.
- A move is free. The player can move cargo any number of times.
- A clamped cargo can move. Its clamp moves with it.

### 8.3 Preview and Snap

- During a drag over the hold, the shape snaps to the cells under the cursor.
- The preview shows each cell of the shape. A cell is green when the drop is valid, and red when it is not valid.
- A drop is not valid when a cell of the shape is outside the hold, or when a cell has a different cargo.
- After a valid drop, the cargo goes to those cells, and the game plays the clack sound.
- After a drop that is not valid, the cargo goes back to its last place.
- During a drag, the preview shows the links that the cargo would make (Section 12.3).

### 8.4 Cargo Details

- When the mouse is on a cargo, a tooltip shows its name, its kind, its weight, its traits with their rules, and the pay of its contract.
- The tooltip shows each break limit as a number, for example "Fragile: breaks at force 2".

## 25. Mass

- Each cargo has a **mass**: its weight value (Section 6.1) multiplied by the number of its cells.
  - Example: a Steel Ingot (heavy, 2 cells) has a mass of 6. A Reactor Core (heavy, 4 cells) has a mass of 12.
- Freight, kit, and scrap have mass. Scrap is light, so each cell of scrap has a mass of 1.
- The **hold mass** is the sum of the mass of each cargo in the hold. Cargo on the dock does not count.
- The ship has a **mass limit**. A run starts with a mass limit of 24. The **Reinforce hull** service adds to it (Section 17.2).
- The hold mass can be more than the mass limit by 25% at most, rounded down. Example: with a mass limit of 24, the maximum is 30.
- When the hold mass is more than the maximum, the Warp button does not work. The top bar shows the mass in red.
- When the hold mass is more than the mass limit, the warp takes the **fuel fee**: 2 credits for each point of mass over the limit. The credits can go below 0 (Section 16).
- The top bar shows the hold mass, the mass limit, and the fuel fee of the warp now.
- The tooltip of a cargo shows its mass (Section 8.4).
