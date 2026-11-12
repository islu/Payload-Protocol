# Payload Protocol: Content Design

This file has the design rules of the game content. The data files in `project/data` are the one source of the content and its values. Read [spec.md](spec.md) for the rules.

## Where the Content Is

| Content | Folder or file |
| --- | --- |
| Balance values: start values, break limits, prices, tolls, hazard steps, hold size | `rules.json` |
| Names and rules text of traits, kinds, weights, and directions | `terms.json` |
| Freight and kit definitions | `cargo/` |
| Contract templates, by sector | `contracts/` |
| Pilot lines, by event | `lines/` |

- Use one file for each definition. The `id` is snake_case and is the same as the file name.
- New content must not need a code change. Do not hard-code balance values.

## Cargo Rules

- Each cargo has one job that the player can see from its icons. Do not give a cargo more than two traits.
- A Fragile, Volatile, or Fluid freight pays more than a freight with no traits of the same size. The risk is the price of the pay.
- A large shape (4 or 5 cells) is hard to pack. Give it more pay, or make it a good wall.
- Heavy cargo makes strong hits. It is a danger for its neighbors and a safe wall when it is clamped.
- Kit helps freight. A kit is never a target of a contract.

## First Content (Version 1)

The first content has 14 freight and 6 kit. The data files set the shapes and the values.

### Freight

| ID | Name | Weight | Traits | Shape idea |
| --- | --- | --- | --- | --- |
| `mail_bundle` | Mail Bundle | light | — | 1 cell |
| `cargo_crate` | Cargo Crate | standard | — | 2 cells, a line |
| `steel_ingot` | Steel Ingot | heavy | — | 2 cells, a line |
| `crystal_vase` | Crystal Vase | light | Fragile | 1 cell |
| `glass_sculpture` | Glass Sculpture | standard | Fragile | 3 cells, an L |
| `radar_dish` | Radar Dish | standard | Fragile, Electronic | 4 cells, a square |
| `circuit_boards` | Circuit Boards | light | Electronic | 2 cells, a line |
| `coolant_tank` | Coolant Tank | standard | Fluid | 2 cells, a line |
| `plasma_cell` | Plasma Cell | light | Volatile | 1 cell |
| `fuel_drum` | Fuel Drum | standard | Fluid, Volatile | 1 cell |
| `reactor_core` | Reactor Core | heavy | Volatile | 4 cells, a square |
| `space_cheese` | Space Cheese | standard | Perishable | 1 cell |
| `frozen_squid` | Frozen Squid | standard | Perishable | 4 cells, a T |
| `courier_drone` | Courier Drone | light | Thruster, Electronic | 1 cell |

### Kit

| ID | Name | Weight | Traits | Shape idea |
| --- | --- | --- | --- | --- |
| `foam_pad` | Foam Pad | light | Cushion | 2 cells, a line |
| `cooler_unit` | Cooler Unit | standard | Cooler | 1 cell |
| `battery_pack` | Battery Pack | standard | Battery, Electronic | 1 cell |
| `shield_generator` | Shield Generator | standard | Shield | 2 cells, a line |
| `inertia_anchor` | Inertia Anchor | heavy | Thruster | 1 cell |
| `sensor_array` | Sensor Array | standard | Sensor | 1 cell |

## Contract Rules

- A sector 1 contract has 1 to 6 pieces, and one trait at most.
- A sector 2 contract has 2 to 5 pieces, and can mix two traits.
- A sector 3 contract has 1 to 5 pieces. It can have Volatile and Fluid freight together.
- Put Perishable freight only in the contracts of sectors 2 and 3. The player can buy a Cooler Unit in sector 1 first.
- The 4 offers of a station must have a total mass of 1.3 times the mass limit or more (SPEC Section 25). Then the player must select.

## Pilot Lines

- PIP is calm, dry, and a little rude. It never blames itself.
- Each event has 4 lines at least.
- Write each line in English first. Then add the zh-TW translation.
