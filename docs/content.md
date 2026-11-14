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
- One cell is one standard cargo crate, about 1 m. Give each cargo the size of the real object, relative to the crate and to the other cargo.
- Small goods travel in one crate: 1 cell. Examples are a phone, a can of soda, a bottle, and a sample.
- Each cargo has an image (SPEC Section 4.2). Select an image that fits the shape. Add the image to `tools/art/cargo_art.json` and run `task art`.

## First Content (Version 1)

The first content has 38 freight and 6 kit. The freight has themes: supplies, tech, food, medical, contraband, weapons, robots, and Earth relics. The data files set the shapes and the values.

### Freight

| ID | Name | Weight | Traits | Shape idea |
| --- | --- | --- | --- | --- |
| `ration_crate` | Ration Crate | light | — | 1 cell |
| `cargo_crate` | Cargo Crate | standard | — | 1 cell |
| `steel_ingot` | Steel Ingot | heavy | — | 2 cells, a line |
| `energy_crystal` | Energy Crystal | light | Fragile | 1 cell |
| `specimen_tube` | Specimen Tube | standard | Fragile | 2 cells, a line |
| `radar_dish` | Radar Dish | standard | Fragile, Electronic | 4 cells, a square |
| `circuit_boards` | Circuit Boards | light | Electronic | 1 cell |
| `coolant_pipe` | Coolant Pipe | standard | Fluid | 3 cells, an L |
| `plasma_cell` | Plasma Cell | light | Volatile | 1 cell |
| `fuel_drum` | Fuel Drum | standard | Fluid, Volatile | 1 cell |
| `reactor_core` | Reactor Core | heavy | Volatile | 4 cells, a square |
| `space_cheese` | Space Cheese | standard | Perishable | 1 cell |
| `frozen_octopus` | Frozen Octopus | standard | Perishable | 4 cells, a T |
| `courier_drone` | Courier Drone | light | Thruster, Electronic | 1 cell |
| `pill_bottle` | Pill Bottle | light | — | 1 cell |
| `vaccine_vial` | Vaccine Vial | light | Perishable | 1 cell |
| `blood_sample` | Blood Sample | standard | Perishable, Fragile | 1 cell |
| `artificial_heart` | Artificial Heart | standard | Perishable, Electronic | 1 cell |
| `medkit` | Medkit | standard | — | 1 cell |
| `liquor_bottle` | Liquor Bottle | light | Fragile | 1 cell |
| `cigarette_pack` | Cigarette Pack | light | — | 1 cell |
| `stim_pack` | Stim Pack | light | Fragile | 1 cell |
| `laser_rifle` | Laser Rifle | standard | Electronic | 2 cells, a line |
| `rocket_launcher` | Rocket Launcher | standard | Volatile | 2 cells, a line |
| `ammo_crate` | Ammo Crate | standard | Volatile | 1 cell |
| `weapon_rack` | Weapon Rack | heavy | — | 4 cells, a square |
| `helper_bot` | Helper Bot | standard | Electronic | 1 cell |
| `service_android` | Service Android | heavy | Electronic | 2 cells, a line |
| `mining_bot` | Mining Bot | heavy | Electronic | 4 cells, a square |
| `mech_suit` | Mech Suit | heavy | Thruster | 4 cells, a square |
| `antique_phone` | Antique Phone | light | Fragile, Electronic | 1 cell |
| `antique_soda` | Antique Soda | light | Fluid | 1 cell |
| `fire_hydrant` | Fire Hydrant | heavy | — | 2 cells, a line |
| `parking_meter` | Parking Meter | standard | Electronic | 2 cells, a line |
| `mailbox` | Mailbox | standard | — | 2 cells, a line |
| `instant_noodles` | Instant Noodles | light | — | 1 cell |
| `flashlight` | Flashlight | light | Electronic | 1 cell |
| `burger` | Burger | standard | Perishable | 1 cell |

### Kit

| ID | Name | Weight | Traits | Shape idea |
| --- | --- | --- | --- | --- |
| `foam_pad` | Foam Pad | light | Cushion | 2 cells, a line |
| `cooler_unit` | Cooler Unit | standard | Cooler | 2 cells, a line |
| `battery_pack` | Battery Pack | standard | Battery, Electronic | 1 cell |
| `shield_generator` | Shield Generator | standard | Shield | 1 cell |
| `inertia_anchor` | Inertia Anchor | heavy | Thruster | 1 cell |
| `sensor_array` | Sensor Array | standard | Sensor | 1 cell |

## Contract Rules

- A sector 1 contract has 1 to 6 pieces, and one trait at most.
- A sector 2 contract has 1 to 5 pieces, and can mix two traits.
- A sector 3 contract has 1 to 5 pieces. It can have Volatile and Fluid freight together.
- Put Perishable freight only in the contracts of sectors 2 and 3. The player can buy a Cooler Unit in sector 1 first.
- A Black Market contract carries contraband or weapons. It pays about 1.5 times a contract with freight of the same size and risk.
- An Earth Heritage Museum or Old Town Collectors contract carries Earth relics: everyday things of old Earth.
- Each freight is in one contract at least.
- The 4 offers of a station must have a total mass of 1.3 times the mass limit or more (SPEC Section 25). Then the player must select.

## Pilot Lines

- MAGELLAN is calm, dry, and a little rude. It never blames itself.
- Each event has 4 lines at least.
- Write each line in English first. Then add the zh-TW translation.
