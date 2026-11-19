# Payload Protocol Spec: The Run

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 14. The Run

- A run starts with these values (`rules.json`):
  - Credits: 40.
  - Clamps: 1.
  - The hold: 6 columns and 6 rows, empty.
  - Shock bay: none (Section 31).
  - Kit: none.
- A new run gets a random seed. The run end screen shows the seed (Section 19.2).
- The first station of the run has contracts and the shop, as each station has.

## 15. Contracts

### 15.1 The Contract Board

- At each station, the contract board offers 4 contracts. Together they have more mass than the ship can carry, so the player cannot take all of them with no fuel fee (Section 25).
- The player can accept 0 to 4 contracts. When the player accepts a contract, its freight goes to the dock.
- The player can cancel an accepted contract before the warp. Then its freight leaves the hold and the dock, with no fee.
- The seed and the leg select the contracts from the templates in `project/data/contracts/`.
- The contracts of a later leg have more freight, more traits, and more pay.

### 15.2 Contract Contents

Each contract has:

- A client name.
- A list of freight. Each piece is a cargo definition.
- The **pay** for each intact piece at the arrival.
- A **bonus** (optional): one condition and a bonus pay. The bonus pays when the condition is true at the arrival.

### 15.3 Bonus Conditions

| Condition | True when |
| --- | --- |
| `all_intact` | Each piece of the contract is delivered. |
| `zone` | Each delivered piece of the contract has all its cells in the zone of the contract: a set of columns or a set of rows. |
| `not_next_to` | No delivered piece of the contract is next to a cargo with the trait of the contract. |

- A bonus pays only when each piece of the contract is delivered. One piece that is scrap, spoiled, lost, or breached cancels the bonus.
- The contract card shows its condition. The station shows the zone of a `zone` bonus on the hold during a drag of its freight.

### 15.4 Breach

- When the player warps with freight of an accepted contract on the dock, each piece on the dock pays the **breach fee** (5 credits) at the arrival.
- That freight stays at the station. The player does not see it again.
- The bonus of that contract cannot pay.

## 16. Arrival

The arrival has these steps, in this order:

1. **Spoil:** each Perishable cargo that no Cooler keeps fresh becomes scrap (Section 12.1).
2. **Delivery:** each intact freight leaves the hold. Its contract pays its pay. The freight of a long contract stays until its last jump (Section 30.2).
3. **Bonus:** each contract with a true condition pays its bonus.
4. **Breach:** each breach fee is paid (Section 15.4).
5. **Penalty:** each VIP contract with a piece that is not delivered pays its penalty (Section 30.1).
6. **Report:** the arrival report shows the result (Section 20.4).

- Scrap stays in the hold. Kit stays in the hold.
- The Insurance mod pays for lost freight at the arrival (Section 27.2).

## 17. The Shop

### 17.1 Kit Offers

- At each station, the shop offers 3 kit definitions. The seed and the leg select them from the kit pool in `rules.json`.
- A purchase puts the kit on the dock. Each offer can be bought one time.
- **Reroll** replaces the 3 offers. The first reroll at a station costs 2 credits. Each next reroll at the same station costs 2 credits more.

### 17.2 Services

| Service | Rule | First price |
| --- | --- | --- |
| **Buy a clamp** | Adds 1 clamp. The maximum is 4 clamps. | 8 credits |
| **Shock bay** | The first purchase installs a shock bay of 2×2 cells. The second purchase makes it 2×3: 2 columns and 3 rows (Section 31). | 20 credits. The second purchase costs 30 credits. |
| **Reinforce hull** | Adds 6 to the mass limit (Section 25). | 12 credits. Each one costs 8 credits more than the last one. |

### 17.3 Sell

- Drag a kit to the sell area of the shop to sell it. The sell price is half of the shop price, rounded down.
- The player cannot sell freight or scrap.

### 17.4 Clear Scrap

- Drag a scrap to the sell area to clear it. It costs 2 credits for each cell of the scrap.
- A cleared scrap is removed.

### 17.5 Prices

- The player cannot buy when the price is more than the credits.
- The credits can go below 0 after a fee: the breach fee, the fuel fee, or the clear price of scrap on the dock (Sections 15.4, 25, and 26.3). Then the player cannot buy until the credits are 0 or more.
- `rules.json` has all prices.

## 18. The Hazard Forecast

- The station shows the hazard of the next jump: each shift step in order, with an arrow and a direction name. An incident comes first (Section 29).
- The hazard is fixed when the station opens. It does not change at the station.
- The number of shift steps depends on the leg:

| Leg | Shift steps |
| --- | --- |
| 1 | 1 at the first jump, 2 at the second and third jumps |
| 2 | 2. The second step is a fork step. |
| 3 | 2 or 3. The last step is a fork step. |

- Two shift steps next to each other in a hazard have different directions.
- A **fork step** has two directions. The two directions are not the same as the step before it, and they are not opposite to each other. Thus one of them is always opposite to the step before it.
  - Example: after LEFT, a fork step is UP or RIGHT, or DOWN or RIGHT.
- The station shows a fork step as "UP or RIGHT". The seed selects the direction that happens when the station opens. The station does not show it.
- Each direction of a fork step has the same chance.

### 18.1 Sensor

- When a Sensor that is not scrap is in the hold or in the shock bay, the station shows the direction of the fork step that will happen.
- When the player takes the Sensor out of the hold, the station shows the fork step as two directions again.
- When an action takes the last Sensor out of the hold and the shock bay, and the fork step was known, the station shows a warning: "No Sensor: the fork step is hidden again."

## 19. Payments and the End of the Run

### 19.1 Payments

- After the arrival of the last jump of a leg, the freight company takes the payment of that leg.
- The payments are 100, 240, and 380 credits. An event can make the payment of a leg smaller (Section 26.2).
- If the credits are less than the payment, the run ends in a loss.
- If not, the game takes the payment, and the next leg starts at a new station.

### 19.2 The End of the Run

- The run ends in a win when the player makes the payment of leg 3.
- The **score** is the credits after the last payment.
- The run end screen shows: win or loss, the score, the delivered freight, the scrap made, the explosions, and the best jump (the jump with the largest net).
- It shows one row for each leg that started: its payment, paid or missed, and its net.
- It shows the ship: the mods, the clamps, the size of the shock bay, the mass limit, and the seed with a Copy button.
- The pilot speaks a line of a win or a loss.
- The run end screen has two buttons: New Run and Title.

## 26. Events

### 26.1 When Events Happen

- The second station of each leg has an event. The third station of each leg has an event with a chance of one half.
- The seed selects the event of a station from the event templates in `project/data/events/`. A run does not show the same event two times.
- The event shows when the station opens, before the player can act (Section 20.8).

### 26.2 Event Contents

- Each event has a name, a text, and 2 or 3 **choices**.
- Each choice has a text, an optional cost in credits, and a list of **effects**.
- One choice of each event has no cost.
- The player must select one choice. The player cannot select a choice when its cost is more than the credits.
- The player cannot select a choice with a cost when one of its effects cannot happen: a `clamp` effect at the maximum of clamps, or a `mod` effect with no mod left.
- The effects happen in the order of the list:

| Effect | Result |
| --- | --- |
| `credits` | Adds a number of credits. The number can be less than 0. |
| `kit` | Puts a kit of a definition on the dock, at no cost. |
| `clamp` | Adds 1 clamp, up to the maximum (Section 17.2). |
| `scrap` | Puts a scrap of a cargo definition on the dock. It has the shape of that definition. |
| `contract` | Adds the contract of a template to the contract board. The player can accept it or not (Section 15). |
| `mod` | Starts a mod choice (Section 27.1). |
| `payment` | Makes the payment of this leg smaller by a number of credits. |

- A contract that only events give has no leg. The station does not offer it at other times.

### 26.3 Scrap on the Dock

- The player can move a scrap from the dock into the hold.
- At the warp, each scrap on the dock is cleared. The player pays its clear price (Section 17.4).

## 27. Mods

A **mod** is a permanent part of the ship. It uses no cell of the hold. The player keeps each mod until the end of the run.

### 27.1 Mod Choice

- After the payment of leg 1 and the payment of leg 2, the player gets a mod choice. An event can give a mod choice too (Section 26.2).
- A mod choice shows 3 mods that the player does not have. The seed selects them. When fewer than 3 are left, it shows the mods that are left.
- The player selects one mod (Section 20.9). When no mod is left, the mod choice does not happen.
- A run has no maximum number of mods.

### 27.2 The Mods

| Mod | Rule |
| --- | --- |
| **Shock Floor** | A cargo with a cell in the bottom row takes each hit with a force 1 less, and 0 at least. This includes the wall jolt. |
| **Cryo Line** | A Cooler keeps each Perishable cargo within 2 cells fresh, not only the cargo next to it (Section 12.1). |
| **Padded Walls** | Each wall jolt has a force 1 less, and 0 at least (Section 10.4). |
| **Gravity Damper** | The weight value of heavy cargo is 2 for the force of its hits and its wall jolt. Its mass does not change. |
| **Array Power** | A Battery powers each Shield within 2 cells, not only the Shields next to it (Section 12.2). |
| **Insurance** | At the arrival, each piece of an accepted contract that is scrap, spoiled, or lost pays half of its pay, rounded down. A breached piece does not pay. |

- **Within 2 cells**: a cell of one cargo is at a distance of 2 or less from a cell of the other cargo. A diagonal step counts as 1, as in the blast area (Section 11.2).
- The hold shows the area of a mod with an area: the bottom row for Shock Floor.

## 30. Special Contracts

A special contract is a contract template with more fields. The contract board offers it as other contracts (Section 15.1). Its card shows a mark.

### 30.1 VIP Contract

- A VIP contract has a **penalty**.
- At the arrival, when a piece of the contract is not delivered, the contract pays its penalty. A piece that is scrap, spoiled, lost, or breached is not delivered.
- The penalty is in addition to the breach fees.

### 30.2 Long Contract

- A long contract has a number of jumps: 2.
- The contract board does not offer a long contract when the run has fewer jumps left than the contract needs. The jump of the station counts.
- Its freight stays in the hold at the arrival of each jump but the last. It is not delivered, and it does not pay.
- At the arrival of the last jump, the contract is delivered as other contracts (Section 16). Then it leaves the contract board, as other contracts.
- The contract stays accepted at the stations between. The player can move its freight in the hold. Freight of the contract on the dock at the warp is breached (Section 15.4).
- The station shows the contract with the jumps that are left.

### 30.3 Large Freight

- Some freight has a shape of 5 cells. It has no other rule. Its contracts pay more (content.md).
