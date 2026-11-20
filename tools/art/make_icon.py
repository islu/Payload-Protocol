"""Draw the project icon project/icon.png: two P pentominoes as cargo, at the front wall.

Run it from the repository root: task art.

The icon is original pixel art at 64x64 pixels, scaled up with no smoothing to
SIZE x SIZE. The two P cells are the initials of Payload Protocol. The amber P has
just slid down (the motion lines), and the blue P hits the front wall (the spark).
The colors are the colors of project/scenes/common/palette.gd.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ICON = ROOT / "project/icon.png"
SIZE = 512

N = 64
BG = (11, 16, 32, 255)
GRID = (26, 36, 66, 255)
FRAME = (42, 58, 102, 255)
FRAME_HI = (78, 100, 160, 255)
RIVET = (130, 150, 200, 255)
WARN = (255, 200, 77, 255)
DARK = (16, 16, 24, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
BLUE = [(150, 232, 255, 255), (95, 211, 255, 255), (40, 130, 190, 255), (12, 40, 70, 255)]
AMBER = [(255, 236, 170, 255), (255, 186, 70, 255), (190, 110, 30, 255), (70, 35, 10, 255)]

img = Image.new("RGBA", (N, N), CLEAR)
px = img.load()

for y in range(N):
    for x in range(N):
        if min(x, N - 1 - x) + min(y, N - 1 - y) < 4:
            continue
        edge = min(x, y, N - 1 - x, N - 1 - y)
        px[x, y] = FRAME_HI if edge == 0 else FRAME if edge < 4 else BG
C = 9  # the size of a cell
O = 5  # the first cell line
for y in range(4, N - 4):
    for x in range(4, N - 4):
        if (x - O) % C == 0 or (y - O) % C == 0:
            px[x, y] = GRID
for k in (10, 22, 41, 53):
    for x, y in ((k, 1), (k, N - 2), (1, k), (N - 2, k)):
        px[x, y] = RIVET
# The front wall: stripes at the bottom.
for y in range(51, 56):
    for x in range(4, N - 4):
        px[x, y] = WARN if ((x + y) // 3) % 2 == 0 else DARK

def piece(cells, ox, oy, col):
    """Draws a cargo of cells: a fill, a light top left, a dark bottom right, and an outline."""
    hi, base, lo, line = col
    own = {(cx, cy) for cx, cy in cells}
    for cx, cy in cells:
        x0, y0 = ox + cx * C, oy + cy * C
        for y in range(y0, y0 + C):
            for x in range(x0, x0 + C):
                px[x, y] = base
    # The outline and the bevel: only at the edges of the shape.
    for cx, cy in cells:
        x0, y0 = ox + cx * C, oy + cy * C
        for i in range(C):
            if (cx, cy - 1) not in own:
                px[x0 + i, y0] = line
                px[x0 + i, y0 + 1] = hi
            if (cx, cy + 1) not in own:
                px[x0 + i, y0 + C - 1] = line
                px[x0 + i, y0 + C - 2] = lo
            if (cx - 1, cy) not in own:
                px[x0, y0 + i] = line
                px[x0 + 1, y0 + i] = hi
            if (cx + 1, cy) not in own:
                px[x0 + C - 1, y0 + i] = line
                px[x0 + C - 2, y0 + i] = lo
    return own

P = [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]
# The blue P rests at the wall; the amber P lands next to it.
piece(P, O + 0 * C + 6, O + 2 * C, AMBER)
piece(P, O + 3 * C + 0, O + 2 * C, BLUE)
# The bowl marks: a small square in each bowl, as the hole of a P.
for ox, col in ((O + 6, AMBER), (O + 3 * C, BLUE)):
    for y in range(O + 2 * C + 7, O + 2 * C + 11):
        for x in range(ox + 7, ox + 11):
            px[x, y] = col[3]
# Motion lines above the amber P: it just slid down.
for x, top, ln in ((O + 9, 6, 6), (O + 14, 4, 9), (O + 19, 7, 5)):
    for y in range(top, top + ln):
        px[x, y] = (255, 200, 77, 150)
# A spark where the blue P hits the wall.
sx, sy = O + 3 * C + 14, 50
for dx, dy in ((0, 0), (-1, -1), (1, -1), (-2, -2), (2, -2), (0, -2), (0, -3)):
    px[sx + dx, sy + dy] = WHITE

img.resize((SIZE, SIZE), Image.Resampling.NEAREST).save(ICON)
print(f"art: icon {SIZE}x{SIZE}")
