"""Checks that the font of the game has each character of the text (SPEC Section 4.2).

The web build has no system fonts: a character that the font does not have shows as
a box. The tool reads the GDScript code of the scenes and the rules, the data files,
and the .po files. It prints each character that is not ASCII and that the font does
not have, with the places where it is. It fails when it finds one.

Run it from the repository root. task lint runs it.
"""

import sys
import unicodedata

from fontTools.ttLib import TTFont

from i18n import PROJECT, game_files

FONT = PROJECT / "art/fonts/jf-openhuninn-2.1.ttf"


def files():
    for pattern in ("*.gd", "*.json", "*.po"):
        yield from game_files(pattern)


def main():
    cmap = TTFont(FONT).getBestCmap()
    missing = {}
    for path in files():
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for ch in line:
                if ord(ch) > 127 and ord(ch) not in cmap:
                    missing.setdefault(ch, []).append(f"{path}:{n}")
    for ch, places in missing.items():
        name = unicodedata.name(ch, "?")
        print(f"glyphs: the font has no {ch!r} (U+{ord(ch):04X} {name}): {', '.join(places[:5])}")
    sys.exit(1 if missing else 0)


if __name__ == "__main__":
    main()
