"""Draw the cover image of the itch.io page: docs/itch/cover.png (630x500).

Run it from the repository root: task art. It reads project/icon.png, so run
make_icon.py first.

The cover has a starfield, the icon, the title in the colors of the icon (PAYLOAD in
amber, PROTOCOL in blue, SPEC Section 20.1) with a glow, and the tagline. The font is
the font of the game. The colors are the colors of project/scenes/common/palette.gd.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ICON = ROOT / "project/icon.png"
FONT = ROOT / "project/art/fonts/jf-openhuninn-2.1.ttf"
COVER = ROOT / "docs/itch/cover.png"
W, H = 630, 500
# Palette.BACKGROUND, TITLE_AMBER, ACCENT, and TEXT_DIM.
BACKGROUND = (11, 16, 32)
AMBER = (255, 186, 70)
BLUE = (95, 211, 255)
DIM = (127, 141, 179)
TAGLINE = "Pack the hold. Survive the warp."


def starfield(img: Image.Image) -> None:
    """Small stars at fixed places: the same seed gives the same cover."""
    rng = random.Random(7)
    draw = ImageDraw.Draw(img)
    for _ in range(140):
        x, y = rng.randrange(W), rng.randrange(H)
        a = rng.choice((60, 90, 140, 200))
        draw.point((x, y), fill=(255, 255, 255, a))
    # A soft blue light behind the icon.
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W // 2 - 170, 10, W // 2 + 170, 300), fill=(*BLUE, 40))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))


def glow_text(img: Image.Image, y: int, text: str, size: int, color: tuple) -> None:
    """A line of text at the center, with a glow of its color."""
    font = ImageFont.truetype(str(FONT), size)
    left, top, right, bottom = font.getbbox(text)
    x = (W - (right - left)) // 2 - left
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((x, y), text, font=font, fill=(*color, 150))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(8)))
    ImageDraw.Draw(img).text((x, y), text, font=font, fill=(*color, 255))


def main() -> None:
    img = Image.new("RGBA", (W, H), (*BACKGROUND, 255))
    starfield(img)
    # The icon at 3 screen pixels for each pixel of its 64x64 art: the pixels stay clean.
    icon = Image.open(ICON).convert("RGBA").resize((192, 192), Image.Resampling.NEAREST)
    img.alpha_composite(icon, ((W - 192) // 2, 34))
    glow_text(img, 240, "PAYLOAD", 74, AMBER)
    glow_text(img, 318, "PROTOCOL", 74, BLUE)
    glow_text(img, 420, TAGLINE, 26, DIM)
    COVER.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(COVER)
    print(f"art: cover {W}x{H}")


if __name__ == "__main__":
    main()
