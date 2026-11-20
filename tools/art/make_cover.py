"""Draw the images of the itch.io page into docs/itch/.

- cover.png (630x500): a starfield, the icon, the title, and the tagline.
- header.png (960x200, transparent): the icon and the title on one line, and the tagline.
- background.png (512x512): a starfield tile. It repeats with no seam.
- social.png (1200x630): the title above a screenshot of the station, for links on social media.
- wide_cover.png (1260x540, 21:9): the block of the cover at the left, the warp at the right.
- logo.png (transparent): the icon and the title with a dark outline and no glow.

Run it from the repository root: task art. It reads project/icon.png, so run
make_icon.py first. It also reads 2_station.png and 3_warp.png of docs/screenshots.

The title is in the colors of the icon (PAYLOAD in amber, PROTOCOL in blue, SPEC
Section 20.1) with a glow. The font is the font of the game. The colors are the colors
of project/scenes/common/palette.gd.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ICON = ROOT / "project/icon.png"
FONT = ROOT / "project/art/fonts/jf-openhuninn-2.1.ttf"
OUT = ROOT / "docs/itch"
SCREENSHOTS = ROOT / "docs/screenshots"
WARP_SHOT = "3_warp.png"
STATION_SHOT = "2_station.png"
# Palette.BACKGROUND, TITLE_AMBER, ACCENT, TEXT_DIM, and PANEL_LINE.
BACKGROUND = (11, 16, 32)
AMBER = (255, 186, 70)
BLUE = (95, 211, 255)
DIM = (127, 141, 179)
PANEL_LINE = (42, 58, 102)
TAGLINE = "Pack the hold. Survive the warp."


def stars(img: Image.Image, count: int, seed: int) -> None:
    """Small stars at fixed places: the same seed gives the same image.

    Each star is one pixel, so a tile of stars repeats with no seam.
    """
    rng = random.Random(seed)
    draw = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = rng.randrange(img.width), rng.randrange(img.height)
        a = rng.choice((60, 90, 140, 200))
        draw.point((x, y), fill=(255, 255, 255, a))


def glow_text(img: Image.Image, x: int, y: int, text: str, font: ImageFont.FreeTypeFont, color: tuple) -> None:
    """A line of text with its top left at (x, y), with a glow of its color."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((x, y), text, font=font, fill=(*color, 150))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(8)))
    ImageDraw.Draw(img).text((x, y), text, font=font, fill=(*color, 255))


def centered_x(img: Image.Image, text: str, font: ImageFont.FreeTypeFont) -> int:
    left, _top, right, _bottom = font.getbbox(text)
    return (img.width - (right - left)) // 2 - left


def icon(size: int) -> Image.Image:
    """The icon at a whole multiple of its 64x64 art: the pixels stay clean."""
    return Image.open(ICON).convert("RGBA").resize((size, size), Image.Resampling.NEAREST)


def cover() -> None:
    img = Image.new("RGBA", (630, 500), (*BACKGROUND, 255))
    stars(img, 140, 7)
    # A soft blue light behind the icon.
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((img.width // 2 - 170, 10, img.width // 2 + 170, 300), fill=(*BLUE, 40))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))
    img.alpha_composite(icon(192), ((img.width - 192) // 2, 34))
    title = ImageFont.truetype(str(FONT), 74)
    small = ImageFont.truetype(str(FONT), 26)
    glow_text(img, centered_x(img, "PAYLOAD", title), 240, "PAYLOAD", title, AMBER)
    glow_text(img, centered_x(img, "PROTOCOL", title), 318, "PROTOCOL", title, BLUE)
    glow_text(img, centered_x(img, TAGLINE, small), 420, TAGLINE, small, DIM)
    img.convert("RGB").save(OUT / "cover.png")


def title_row(img: Image.Image, center_x: int, top: int, scale: float, glow: bool = True, tagline: bool = True) -> None:
    """The icon and the title on one line, and the tagline under the title.

    At scale 1 the icon is 128 pixels and the title is 64 pixels. Without the glow, the
    text has a dark outline: it stays legible on a white and on a black background.
    """
    icon_size = 64 * max(1, round(2 * scale))
    title = ImageFont.truetype(str(FONT), round(64 * scale))
    small = ImageFont.truetype(str(FONT), round(24 * scale))
    gap = round(24 * scale)
    first, second = "PAYLOAD ", "PROTOCOL"
    first_w = title.getlength(first)
    x = int(center_x - (icon_size + gap + first_w + title.getlength(second)) // 2)
    img.alpha_composite(icon(icon_size), (x, top))
    text_x = x + icon_size + gap
    # The text block is about 112 pixels high with the tagline, and 80 without it.
    text_y = top + (icon_size - round((112 if tagline else 80) * scale)) // 2
    parts = [(text_x, text_y, first, title, AMBER), (int(text_x + first_w), text_y, second, title, BLUE)]
    if tagline:
        parts.append((text_x, text_y + round(84 * scale), TAGLINE, small, DIM))
    for x, y, text, font, color in parts:
        if glow:
            glow_text(img, x, y, text, font, color)
        else:
            stroke = max(2, round(4 * scale))
            ImageDraw.Draw(img).text((x, y), text, font=font, fill=(*color, 255), stroke_width=stroke, stroke_fill=(*BACKGROUND, 255))


def screenshot(name: str, size: tuple, darken: int) -> Image.Image:
    """A screenshot of docs/screenshots, cut to the size at its center, and darker."""
    shot = Image.open(SCREENSHOTS / name).convert("RGBA")
    scale = max(size[0] / shot.width, size[1] / shot.height)
    shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.Resampling.LANCZOS)
    left, top = (shot.width - size[0]) // 2, (shot.height - size[1]) // 2
    shot = shot.crop((left, top, left + size[0], top + size[1]))
    shot.alpha_composite(Image.new("RGBA", size, (*BACKGROUND, darken)))
    return shot


def header() -> None:
    """Transparent, so the theme colors of the page show behind it."""
    img = Image.new("RGBA", (960, 200), (0, 0, 0, 0))
    title_row(img, img.width // 2, 36, 1.0)
    img.save(OUT / "header.png")


def social() -> None:
    """The image of a link on social media: the title above a screenshot of the station."""
    img = Image.new("RGBA", (1200, 630), (*BACKGROUND, 255))
    stars(img, 200, 3)
    title_row(img, img.width // 2, 40, 1.1)
    shot = screenshot(STATION_SHOT, (720, 405), 0)
    x, y = (img.width - shot.width) // 2, 196
    ImageDraw.Draw(img).rectangle((x - 2, y - 2, x + shot.width + 1, y + shot.height + 1), fill=(*PANEL_LINE, 255))
    img.alpha_composite(shot, (x, y))
    img.convert("RGB").save(OUT / "social.png")


def wide_cover() -> None:
    """The cover of the home page (21:9): the title at the left, the warp at the right."""
    img = Image.new("RGBA", (1260, 540), (*BACKGROUND, 255))
    stars(img, 160, 5)
    shot = screenshot(WARP_SHOT, (700, 540), 60)
    # The screenshot fades into the starfield at its left edge.
    fade = Image.linear_gradient("L").rotate(90).resize(shot.size)
    shot.putalpha(Image.eval(fade, lambda a: 255 - a))
    img.alpha_composite(shot, (img.width - shot.width, 0))
    # The block of the cover: the icon above the title in two lines.
    center_x = 330
    img.alpha_composite(icon(128), (center_x - 64, 60))
    title = ImageFont.truetype(str(FONT), 72)
    small = ImageFont.truetype(str(FONT), 24)
    glow_text(img, center_x - int(title.getlength("PAYLOAD")) // 2, 200, "PAYLOAD", title, AMBER)
    glow_text(img, center_x - int(title.getlength("PROTOCOL")) // 2, 278, "PROTOCOL", title, BLUE)
    glow_text(img, center_x - int(small.getlength(TAGLINE)) // 2, 390, TAGLINE, small, DIM)
    img.convert("RGB").save(OUT / "wide_cover.png")


def logo() -> None:
    """Transparent, with no glow and no tagline. It is legible on white and on black."""
    img = Image.new("RGBA", (1600, 240), (0, 0, 0, 0))
    title_row(img, img.width // 2, 24, 1.5, glow=False, tagline=False)
    left, top, right, bottom = img.getbbox()
    img = img.crop((left - 8, top - 8, right + 8, bottom + 8))
    img.save(OUT / "logo.png")


def background() -> None:
    img = Image.new("RGBA", (512, 512), (*BACKGROUND, 255))
    stars(img, 96, 11)
    img.convert("RGB").save(OUT / "background.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cover()
    header()
    background()
    social()
    wide_cover()
    logo()
    print("art: itch.io cover, header, background, social, wide_cover, logo")


if __name__ == "__main__":
    main()
