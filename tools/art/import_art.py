"""Make the cargo images in project/art/cargo from FreePixel images (SPEC Section 4.2).

Run it from the repository root: task art.

tools/art/cargo_art.json has an entry for each cargo ID:
  {"source": "<path at the FreePixel CDN>", "crop": [x, y, w, h], "scale": 0.5 or "fit", "offset": [x, y]}
Only "source" is necessary.

For each cargo, the tool:
1. Downloads the image to .local/art (not in git). The license does not let us
   redistribute the raw files (docs/assets.md).
2. Crops it to "crop", or to the pixels that are not transparent.
3. Scales it to fit the cells of the shape at 100 pixels for each cell. The scale is
   1 or 0.5 when the image fits, so that the pixels stay clean.
4. Writes <id>.png (the image over the box of the shape), <id>_scrap.png (the same
   image in dark gray, for scrap), and <id>.json ({"shape": the cells of the shape}).

tools/art/speaker_art.json has an entry for each speaker ID (SPEC Section 20.8):
  {"source": "<path at the FreePixel CDN>", "head": <the height of the head in pixels>,
   "crop": [x, y, w, h]}
"source" and "head" are necessary. "head" is the height from the top of the figure to
the chin in the source image. The tool crops the image to the figure and scales it so
that each head is HEAD_SIZE pixels high: all speakers have the same proportions. It
writes <id>.png to project/art/speakers.
"""

import json
import sys
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps

CDN = "https://pub-8b7609252a6742d7b029292aaede7f7f.r2.dev/"
CELL = 100
ROOT = Path(__file__).resolve().parents[2]
TABLE = ROOT / "tools/art/cargo_art.json"
CARGO = ROOT / "project/data/cargo"
RAW = ROOT / ".local/art"
OUT = ROOT / "project/art/cargo"
SPEAKER_TABLE = ROOT / "tools/art/speaker_art.json"
SPEAKERS = ROOT / "project/data/speakers"
SPEAKER_OUT = ROOT / "project/art/speakers"
# The height of the head of each speaker portrait. The event screen uses the same value.
HEAD_SIZE = 120


def download(source: str) -> Path:
    path = RAW / Path(source).name
    if not path.exists():
        RAW.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(CDN + source, headers={"User-Agent": "payload-protocol-art"})
        with urllib.request.urlopen(req, timeout=60) as r:
            path.write_bytes(r.read())
    return path


def load(entry: dict) -> Image.Image:
    """Opens the image of an entry: its "crop" box, or else the box of its pixels."""
    img = Image.open(download(entry["source"])).convert("RGBA")
    if "crop" in entry:
        x, y, w, h = entry["crop"]
        return img.crop((x, y, x + w, y + h))
    return img.crop(img.getbbox())


def prune(folder: Path, known: set, suffixes: tuple) -> None:
    """Removes the files of a folder that are not in known: their entry left the table."""
    for f in folder.iterdir():
        if f.suffix in suffixes and f.name not in known:
            f.unlink()


def report_missing(defs: Path, table: dict, what: str) -> None:
    """Prints each definition of the data that has no entry in the table."""
    missing = sorted(p.stem for p in defs.glob("*.json") if p.stem not in table)
    if missing:
        print(f"art: no {what} for " + ", ".join(missing))


def make(cargo_id: str, entry: dict) -> None:
    shape = json.loads((CARGO / f"{cargo_id}.json").read_text())["shape"]
    cols = max(c[0] for c in shape) + 1
    rows = max(c[1] for c in shape) + 1
    box_w, box_h = cols * CELL, rows * CELL
    img = load(entry)
    fit = min(box_w / img.width, box_h / img.height)
    scale = entry.get("scale", 1.0 if fit >= 1.0 else 0.5 if fit >= 0.5 else fit)
    if scale == "fit":
        # Fill the box: a scale that is not 1 or 0.5 makes the pixels a little soft.
        scale = fit
    size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
    if scale >= 1.0:
        resample = Image.Resampling.NEAREST
    elif scale == 0.5:
        resample = Image.Resampling.BOX
    else:
        resample = Image.Resampling.LANCZOS
    img = img.resize(size, resample)
    ox, oy = entry.get("offset", [0, 0])
    canvas = Image.new("RGBA", (box_w, box_h), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((box_w - img.width) // 2 + ox, (box_h - img.height) // 2 + oy))
    canvas.save(OUT / f"{cargo_id}.png")
    # Scrap: the same image, gray and dark (SPEC Section 4.2).
    gray = ImageOps.grayscale(canvas).point(lambda v: int(v * 0.6)).convert("RGBA")
    gray.putalpha(canvas.getchannel("A"))
    gray.save(OUT / f"{cargo_id}_scrap.png")
    (OUT / f"{cargo_id}.json").write_text(json.dumps({"shape": shape}) + "\n")
    print(f"art: {cargo_id} {size[0]}x{size[1]} in {box_w}x{box_h}, scale {scale:g}")


def make_portrait(speaker_id: str, entry: dict) -> None:
    """The portrait of a speaker: the figure, scaled to a head of HEAD_SIZE pixels."""
    img = load(entry)
    # A crop box can have empty margins: the figure starts at its first pixel.
    img = img.crop(img.getbbox())
    scale = HEAD_SIZE / entry["head"]
    size = (round(img.width * scale), round(img.height * scale))
    # Nearest keeps the pixels sharp. The scale is 2 or more, so the uneven pixels are small.
    img = img.resize(size, Image.Resampling.NEAREST)
    img.save(SPEAKER_OUT / f"{speaker_id}.png")
    print(f"art: speaker {speaker_id} {img.width}x{img.height}, scale {scale:.2f}")


def make_portraits() -> None:
    table = json.loads(SPEAKER_TABLE.read_text())
    SPEAKER_OUT.mkdir(parents=True, exist_ok=True)
    for speaker_id, entry in table.items():
        make_portrait(speaker_id, entry)
    prune(SPEAKER_OUT, {f"{s}.png" for s in table}, (".png",))
    report_missing(SPEAKERS, table, "portrait")


def main() -> int:
    table = json.loads(TABLE.read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    known = set()
    for cargo_id, entry in table.items():
        make(cargo_id, entry)
        known.update({f"{cargo_id}.png", f"{cargo_id}_scrap.png", f"{cargo_id}.json"})
    prune(OUT, known, (".png", ".json"))
    report_missing(CARGO, table, "image")
    make_portraits()
    return 0


if __name__ == "__main__":
    sys.exit(main())
