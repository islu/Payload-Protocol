# Assets From Outside the Project

This file records each art, font, and sound file that the project did not make. Record it when you add the file. A release must give the attribution that each license asks for.

- Record the source at the original creator or vendor, not at a repost.
- Do not record "free" or "royalty-free" as a license. Find the license name.
- Keep the attribution when you rename, convert, crop, or pack a file.
- Files that a tool of the project makes need no row. The placeholder sounds in `project/audio/sfx` come from `tools/sfx/make_sfx.py`.

| File | Source | License | Attribution | Changes | Added |
| --- | --- | --- | --- | --- | --- |
| `project/art/fx/*.png` (effect sheets) | pixelfx by Patch, commit `5294518` (https://github.com/patch-gg/pixelfx). Some effects adapt Sprite Fusion's VFX by Hugo Duprez. | MIT (`project/art/fx/LICENSE.txt`) | Ship `LICENSE.txt` with the game. Credit "Effects: pixelfx by Patch and Hugo Duprez (MIT)". | `task fx` renders them, cuts them, and fades them out. `break` and `spoil` are new effects in `tools/fx/effects`. | 2026-11-13 |
| `project/art/fonts/jf-openhuninn-2.1.ttf` | jf open huninn 2.1 by justfont | SIL OFL 1.1 (`project/art/fonts/OFL.txt`) | Ship `OFL.txt` with the game. | None | 2026-11-12 |
