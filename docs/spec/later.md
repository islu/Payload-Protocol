# Payload Protocol Spec: Later

This file is part of the [game specification](../spec.md). The section numbers are the same in all spec files.

## 24. Later

- **Tilt and rotation steps:** a shift step that turns the whole hold, or a diagonal slide.
- **Hidden steps:** a step that shows "?" (any of three directions). The fork step of Section 18 is the first part of this idea.
- **A save of the run** between jumps.
- **Unlocks between runs:** new kit, new clients, and ship types with a different hold shape.
- **A daily seed** and a score list.
- **Touch controls:** a long press does what a right click does.
- **More traits:** Magnetic (pulls metal cargo next to it), Living (moves 1 cell at random), Sticky (cargo next to it does not slide).
- **Damaged freight:** a state between intact and scrap that pays half.
- **Contraband scan:** some jumps have a scan from one wall, shown at the station. At the arrival, the scan takes each contraband freight that it can see from that wall. Other cargo can hide it.
- **Robot kit:** a Cleaning Bot stops each leak next to it. A Bomb Disposal Bot stops each explosion next to it.
- **Walking robots:** a robot has an arrow. Before each warp, it moves 1 cell in the direction of the arrow, and stops at a cargo or a wall.
- **Repair:** a Medical Bot kit changes one scrap next to it into damaged freight at the arrival (see Damaged freight).
- **Recoil:** a launcher fires when it takes a hit, and breaks the first cargo in the direction of its barrel.
- **Alien egg event:** an alien jelly creature puts an Alien Egg in the cargo of the player by force. The rule of the egg is not decided: for example, it grows after each jump, it breaks and splashes acid, or it hatches. Art candidates: the FreePixel images `alien-blob-amorphous-creature-acid-004` (the speaker) and `xenomorph-egg-organic-pulsing-alien-membrane-slimy` (the egg; use the name Alien Egg).
