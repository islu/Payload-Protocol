# Payload Protocol Spec: The Run

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 14. The Run

- A run starts with these values (`rules.json`):
  - Credits: 40.
  - Clamps: 1.
  - The hold: 6 columns and 6 rows, empty.
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

1. **Spoil:** each Perishable cargo that is not next to a Cooler becomes scrap (Section 12.1).
2. **Delivery:** each intact freight leaves the hold. Its contract pays its pay.
3. **Bonus:** each contract with a true condition pays its bonus.
4. **Breach:** each breach fee is paid (Section 15.4).
5. **Report:** the arrival report shows the result (Section 20.4).

- Scrap stays in the hold. Kit stays in the hold.
- Credits can go below 0 after a breach fee. Then the player cannot buy until the credits are 0 or more.

## 17. The Shop

### 17.1 Kit Offers

- At each station, the shop offers 3 kit definitions. The seed and the leg select them from the kit pool in `rules.json`.
- A purchase puts the kit on the dock. Each offer can be bought one time.
- **Reroll** replaces the 3 offers. The first reroll at a station costs 2 credits. Each next reroll at the same station costs 2 credits more.

### 17.2 Services

| Service | Rule | First price |
| --- | --- | --- |
| **Buy a clamp** | Adds 1 clamp. The maximum is 4 clamps. | 8 credits |
| **Hold upgrade** | Adds one column at the right, or one row at the bottom (the player selects). The maximum is 8 columns and 8 rows. It does not change the mass limit. | 15 credits. Each upgrade costs 10 credits more than the last one. |
| **Reinforce hull** | Adds 6 to the mass limit (Section 25). | 12 credits. Each one costs 8 credits more than the last one. |

### 17.3 Sell

- Drag a kit to the sell area of the shop to sell it. The sell price is half of the shop price, rounded down.
- The player cannot sell freight or scrap.

### 17.4 Clear Scrap

- Drag a scrap to the sell area to clear it. It costs 2 credits for each cell of the scrap.
- A cleared scrap is removed.

### 17.5 Prices

- The player cannot buy when the price is more than the credits.
- `rules.json` has all prices.

## 18. The Hazard Forecast

- The station shows the hazard of the next jump: each shift step in order, with an arrow and a direction name.
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

- When a Sensor that is not scrap is in the hold, the station shows the direction of the fork step that will happen.
- When the player takes the Sensor out of the hold, the station shows the fork step as two directions again.
- The pilot speaks a line about the hazard when the station opens (Section 22).

## 19. Payments and the End of the Run

### 19.1 Payments

- After the arrival of the last jump of a leg, the freight company takes the payment of that leg.
- The payments are 70, 180, and 350 credits.
- If the credits are less than the payment, the run ends in a loss.
- If not, the game takes the payment, and the next leg starts at a new station.

### 19.2 The End of the Run

- The run ends in a win when the player makes the payment of leg 3.
- The **score** is the credits after the last payment.
- The run end screen shows: win or loss, the score, the delivered freight, the scrap made, the explosions, and the seed.
- The run end screen has two buttons: New Run and Title.
