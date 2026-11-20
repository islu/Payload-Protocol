# Assets From Outside the Project

This file records each art, font, and sound file that the project did not make. Record it when you add the file. A release must give the attribution that each license asks for.

- Record the source at the original creator or vendor, not at a repost.
- Do not record "free" or "royalty-free" as a license. Find the license name.
- Keep the attribution when you rename, convert, crop, or pack a file.
- Files that a tool of the project makes need no row. The placeholder sounds in `project/audio/sfx` come from `tools/sfx/make_sfx.py`.

| File | Source | License | Attribution | Changes | Added |
| --- | --- | --- | --- | --- | --- |
| `project/art/fx/*.png` (effect sheets) | pixelfx by Patch, commit `5294518` (https://github.com/patch-gg/pixelfx). Some effects adapt Sprite Fusion's VFX by Hugo Duprez. | MIT (`project/art/fx/LICENSE.txt`) | Ship `LICENSE.txt` with the game. Credit "Effects: pixelfx by Patch and Hugo Duprez (MIT)". | `task fx` renders them, cuts them, and fades them out. `break`, `spoil`, and the pilot portrait (`pilot_idle`, `pilot_talk`) are new effects in `tools/fx/effects`. | 2026-11-13 |
| `project/audio/music/vintage_menu.ogg` | "Vintage Menu" by iamoneabe, OpenGameArt (https://opengameart.org/content/vintage-menu) | CC0 | None needed. Credit "Music: Vintage Menu by iamoneabe" when possible. | Converted from the 320 kbps MP3 to Ogg Vorbis (quality 1, about 80 kbps). The game plays it as a loop. | 2026-11-13 |
| `project/art/cargo/*.png` (cargo images), `project/art/speakers/*.png` (the portraits of the event speakers) | FreePixel (https://freepixel.art). `tools/art/cargo_art.json` and `tools/art/speaker_art.json` have the source path of each image. | FreePixel Asset License (https://freepixel.art/license/): use in free and commercial games, change them freely. Do not redistribute or resell the raw files. | None needed. Credit "Cargo art: FreePixel" when possible. | `task art` crops each image to its content and scales it to 100 pixels for each cell. It crops each speaker portrait to the figure and scales it to the same head size. The raw downloads stay in `.local/art` and are not in git. | 2026-11-13 |
| `project/icon.png` (the project icon: two P pieces of cargo at the front wall) | Original, drawn by `tools/art/make_icon.py` for this project | Same as the project | None needed. | `task art` draws it at 64×64 pixels and scales it to 512×512 with no smoothing. | 2026-11-20 |
| `project/art/fonts/jf-openhuninn-2.1.ttf` | jf open huninn 2.1 by justfont | SIL OFL 1.1 (`project/art/fonts/OFL.txt`) | Ship `OFL.txt` with the game. | None | 2026-11-12 |
