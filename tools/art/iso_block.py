"""Change the shape and the color of an isometric block image (tools/art/import_art.py).

The image must show one block in isometric view: a top face, a left face, and a right
face. The long axis goes from the left corner down to the right. A FreePixel image
can be changed (docs/assets.md).
"""

import colorsys

from PIL import Image, ImageColor


class Block:
    """The corners and the faces of an isometric block. Only opaque pixels count."""

    def __init__(self, img: Image.Image):
        self.px = img.load()
        self.w, self.h = img.size
        left, top, right, _ = img.getchannel("A").getbbox()
        self.x0, self.x1 = left, right - 1
        # The left corner, the top corner, and the front corner of the top face.
        self.y_left = min(y for y in range(self.h) if self.opaque(self.x0, y))
        self.y_top = top
        self.x_top = min(x for x in range(self.w) if self.opaque(x, top))
        self.slope = (self.y_left - self.y_top) / max(1, self.x_top - self.x0)
        self.x_front = self.x0 + (self.x1 - self.x_top)
        self.y_front = self.y_left + self.slope * (self.x_front - self.x0)

    def opaque(self, x: int, y: int) -> bool:
        return 0 <= x < self.w and 0 <= y < self.h and self.px[x, y][3] > 0

    def face(self, x: int, y: int) -> tuple:
        """Returns the face of a pixel, and its depth below the top edge of a side face."""
        edge = self.y_left + self.slope * (x - self.x0)
        if x < self.x_front and y > edge + 1:
            return "left", y - edge
        edge = self.y_front - self.slope * (x - self.x_front)
        if x >= self.x_front and y > edge + 1:
            return "right", y - edge
        return "top", 0

    def along(self, x: int, y: int) -> float:
        """Returns the place of a pixel on the long axis, in pixels of x."""
        face, _ = self.face(x, y)
        if face == "left":
            return x - self.x0
        if face == "right":
            return self.x_front - self.x0
        return ((x - self.x0) + (y - self.y_left) / self.slope) / 2


def longer(img: Image.Image, extra: int) -> Image.Image:
    """Makes the block longer by extra pixels of x on its long axis.

    The front half moves down to the right. The gap gets copies of the slab behind the
    cut, so the holes and the edges continue.
    """
    b = Block(img)
    extra -= extra % 2
    cut = (b.x_front - b.x0) / 2
    slab = int(cut) - int(cut) % 2
    out = Image.new("RGBA", (b.w + extra, b.h + extra // 2))
    dst = out.load()
    for y in range(out.height):
        for x in range(out.width):
            sx, sy = x - extra, y - extra // 2
            if b.opaque(sx, sy) and b.along(sx, sy) >= cut:
                dst[x, y] = b.px[sx, sy]
                continue
            if b.opaque(x, y) and b.along(x, y) < cut:
                dst[x, y] = b.px[x, y]
                continue
            for k in range(slab, extra + slab + 1, slab):
                sx, sy = x - k, y - k // 2
                if not b.opaque(sx, sy):
                    continue
                a = b.along(sx, sy)
                if cut - slab <= a < cut and a + k < cut + extra:
                    dst[x, y] = b.px[sx, sy]
                    break
    return out


def flatter(img: Image.Image, less: int) -> Image.Image:
    """Makes the block lower by less pixels: it removes a band of the side faces."""
    b = Block(img)
    keep = (b.h - int(b.y_front)) // 4  # The top rim of the side faces stays.
    out = Image.new("RGBA", (b.w, b.h - less))
    dst = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if b.opaque(x, y + less):
                face, depth = b.face(x, y + less)
                if face != "top" and depth >= keep + less:
                    dst[x, y] = b.px[x, y + less]
                    continue
            if b.opaque(x, y):
                face, depth = b.face(x, y)
                if face == "top" or depth < keep:
                    dst[x, y] = b.px[x, y]
    return out


def tint(img: Image.Image, color: str, saturation: float = 0.75) -> Image.Image:
    """Gives each pixel the hue of color ("#rrggbb"). The light and the shadows stay."""
    rgb = [c / 255 for c in ImageColor.getrgb(color)]
    hue = colorsys.rgb_to_hsv(*rgb)[0]
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            _, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            r, g, b = colorsys.hsv_to_rgb(hue, s * saturation, v)
            px[x, y] = (round(r * 255), round(g * 255), round(b * 255), a)
    return img
