# Third-Party Assets

The source code of this repository has the MIT License ([LICENSE](../LICENSE)). The MIT License does not apply to the files in this list. Other creators made them, and each file keeps the license of its creator.

This file records the source and the license of each art, font, and sound file that the project did not make. Record it when you add the file. A release must give the attribution that each license asks for.

- Record the source at the original creator or vendor, not at a repost.
- Do not record "free" or "royalty-free" as a license. Find the license name.
- Keep the attribution when you rename, convert, crop, or pack a file.
- Files that a tool of the project makes need no row, for example the project icon (`tools/art/make_icon.py`) and the placeholder sounds in `project/audio/sfx` (`tools/sfx/make_sfx.py`).

| File | Source | License | Attribution | Changes |
| --- | --- | --- | --- | --- |
| `project/art/cargo/*.png` (cargo images), `project/art/speakers/*.png` (the portraits of the event speakers) | FreePixel (<https://freepixel.art>). `tools/art/cargo_art.json` and `tools/art/speaker_art.json` have the source path of each image. | FreePixel Asset License (<https://freepixel.art/license/>): use in free and commercial games, change them freely. Do not redistribute or resell the raw files. | None needed. Credit "Cargo art: FreePixel" when possible. | `task art` crops each image to its content and scales it to 100 pixels for each cell. The Shock Sponge is a sponge block that `task art` makes longer, flatter, and pink. It crops each speaker portrait to the figure and scales it to the same head size. The raw downloads stay in `.local/art` and are not in git. |
| `project/art/fx/*.png` (effect sheets) | pixelfx by Patch (<https://github.com/patch-gg/pixelfx>). Some effects adapt Sprite Fusion's VFX by Hugo Duprez. | MIT (`project/art/fx/LICENSE.txt`) | Ship `LICENSE.txt` with the game. Credit "Effects: pixelfx by Patch and Hugo Duprez (MIT)". | `task fx` renders them, cuts them, and fades them out. `break`, `spoil`, and the pilot portrait (`pilot_idle`, `pilot_talk`) are new effects in `tools/fx/effects`. |
| `project/audio/music/vintage_menu.ogg` | "Vintage Menu" by iamoneabe, OpenGameArt (<https://opengameart.org/content/vintage-menu>) | CC0 | None needed. Credit "Music: Vintage Menu by iamoneabe" when possible. | Converted from the 320 kbps MP3 to Ogg Vorbis (quality 1, about 80 kbps). The game plays it as a loop. |
| `project/art/fonts/jf-openhuninn-2.1.ttf` | jf open huninn 2.1 by justfont (<https://github.com/justfont/open-huninn-font>) | SIL OFL 1.1 (`project/art/fonts/OFL.txt`) | Ship `OFL.txt` with the game. | None |
| `project/audio/sfx/*.ogg` (the sounds that are not placeholders: `arrive`, `breach`, `clack`, `clamp`, `click`, `deny`, `ion`, `pick_up`, `squelch`, `stamp`) | Kenney (<https://kenney.nl>): Sci-fi Sounds, Impact Sounds, Interface Sounds, and UI Audio. The source file of each sound: `arrive` confirmation_003, `breach` forceField_001, `clack` drop_002, `clamp` switch20, `click` click_004, `deny` error_004, `ion` forceField_004, `pick_up` select_002, `squelch` slime_000, `stamp` impactPunch_heavy_000. | CC0 (`License.txt` of each pack) | None needed. Credit "Sounds: Kenney" when possible. | Renamed. No other change. |
