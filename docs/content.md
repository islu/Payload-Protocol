# Payload Protocol: Content Design

This file has the design rules of the game content. The data files in `project/data` are the one source of the content and its values. Read [spec.md](spec.md) for the rules.

## Where the Content Is

| Content | Folder or file |
| --- | --- |
| Balance values: start values, break limits, prices, payments, hazard steps, hold size, the event stations, the mod offers, the numbers of the environments and the incidents | `rules.json` |
| Names and rules text of traits, kinds, weights, and directions | `terms.json` |
| Freight and kit definitions | `cargo/` |
| Contract templates, by leg | `contracts/` |
| Pilot lines, by event | `lines/` |
| Station events and their choices | `events/` |
| The speakers of the events: the name of each character (SPEC Section 20.8) | `speakers/` |
| The name and the rule text of each mod. The rule is in the code (SPEC Section 27.2). | `mods/` |
| The name and the rule text of each route environment. The rule is in the code (SPEC Section 28.2). | `environments/` |

- Use one file for each definition. The `id` is snake_case and is the same as the file name.
- New content must not need a code change. Do not hard-code balance values.

## Cargo Rules

- Each cargo has one job that the player can see from its icons. Do not give a cargo more than two traits.
- A Fragile, Volatile, or Fluid freight pays more than a freight with no traits of the same size. The risk is the price of the pay.
- A large shape (4 or 5 cells) is hard to pack. Give it more pay, or make it a good wall.
- Heavy cargo makes strong hits. It is a danger for its neighbors and a safe wall when it is clamped.
- Kit helps freight. A kit is never a target of a contract.
- Kit has no mass (SPEC Section 25). Its costs are its price and its cells.
- One cell is one standard cargo crate, about 1 m. Give each cargo the size of the real object, relative to the crate and to the other cargo.
- Small goods travel in one crate: 1 cell. Examples are a phone, a can of soda, a bottle, and a sample.
- Each cargo has an image (SPEC Section 4.2). Select an image that fits the shape. Add the image to `tools/art/cargo_art.json` and run `task art`.

## First Content (Version 1)

The first content has 43 freight in contracts, 6 kit, and the Hull Debris (SPEC Section 29.2). The freight has themes: supplies, tech, food, medical, contraband, weapons, robots, and Earth relics. The data files set the shapes and the values.

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
| `ship_engine` | Ship Engine | heavy | — | 5 cells, a P (large freight, SPEC Section 30.3) |
| `ancient_statue` | Ancient Statue | standard | Fragile | 5 cells, a P (large freight, SPEC Section 30.3) |
| `instant_noodles` | Instant Noodles | light | — | 1 cell |
| `flashlight` | Flashlight | light | Electronic | 1 cell |
| `burger` | Burger | standard | Perishable | 1 cell |
| `prosthetic_arm` | Prosthetic Arm | light | Electronic | 1 cell |
| `hydroponic_garden` | Hydroponic Garden | standard | Perishable | 2 cells, a line |
| `warp_core` | Warp Core | heavy | Volatile, Electronic | 2 cells, a line |

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

- A leg 1 contract has 1 to 6 pieces, and one trait at most.
- A leg 2 contract has 1 to 5 pieces, and can mix two traits.
- A leg 3 contract has 1 to 5 pieces. It can have Volatile and Fluid freight together.
- Put Perishable freight only in the contracts of legs 2 and 3. The player can buy a Cooler Unit in leg 1 first.
- A Black Market contract carries contraband or weapons. It pays about 1.5 times a contract with freight of the same size and risk.
- An Earth Heritage Museum or Old Town Collectors contract carries Earth relics: everyday things of old Earth.
- Each freight is in one contract at least.
- A VIP contract has a penalty of about half of its total pay. A long contract pays about 1.8 times a contract of the same freight (SPEC Section 30).
- Large freight (5 cells) is in a contract of its own, with a high pay.
- The 4 offers of a station must have a total mass of 1.3 times the mass limit or more (SPEC Section 25). Then the player must select.

## Event Rules

- Each event has 2 or 3 choices. One choice has no cost. Most events have one choice with no bad effect too.
- A choice text tells what the player does. The screen shows the cost and the effects next to it.
- A contract that only an event gives has `"legs": []`. Give it more pay than an offered contract of the same size: the player did not plan for it.
- Use the effects of SPEC Section 26.2 only. A new kind of effect needs a code change.
- Each event names its speaker: one of the characters with a portrait (SPEC Section 20.8). Use a speaker of `speakers/`. A new speaker needs a portrait of the upper body or the full body: add it to `tools/art/speaker_art.json` with the height of its head, and run `task art`.

## Pilot Lines

- MAGELLAN is calm, dry, and a little rude. It never blames itself.
- Each event has 4 lines at least.
- Write each line in English first. Then add the zh-TW translation.
