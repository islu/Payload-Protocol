// Makes the effect sprite sheets in project/art/fx from tools/fx/fx.json, with pixelfx
// (https://github.com/patch-gg/pixelfx, MIT). The game plays the sheets; it does not run JavaScript.
//
// Run it from the repository root: task fx (the task gets the pixelfx checkout first).
// Usage: node tools/fx/make_fx.mjs <pixelfx checkout> <out dir>
//
// Each effect gives <name>.png (the frames in a grid, transparent) and <name>.json:
// {fps, frames, size: [w, h], columns, pivot: [x, y], scale}. The pivot is the point of the effect.

import { cpSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [checkout, out] = process.argv.slice(2).map((p) => resolve(p));
if (!checkout || !out) {
  console.error("usage: node tools/fx/make_fx.mjs <pixelfx checkout> <out dir>");
  process.exit(1);
}
const here = resolve("tools/fx");
// The effects of this project use the core of pixelfx, so they go into the checkout.
cpSync(join(here, "effects"), join(checkout, "src/fx"), { recursive: true });
const lib = await import(pathToFileURL(join(checkout, "tools/lib/fxlib.mjs")).href);

const list = JSON.parse(readFileSync(join(here, "fx.json"), "utf8"));
mkdirSync(out, { recursive: true });
for (const [name, e] of Object.entries(list)) {
  if (name.startsWith("_")) continue;
  const fx = await lib.loadEffect(e.id);
  const r = lib.renderFrames(fx, { bg: "none", actor: false, options: e.options ?? {} });
  const from = Math.round((e.start ?? 0) * r.fps);
  const to = Math.min(r.n, from + Math.round((e.seconds ?? fx.meta.duration) * r.fps));
  const frames = r.frames.slice(from, to);
  // The last quarter fades out, so that a cut animation does not stop at once. A loop does not fade.
  const fadeFrom = fx.meta.loop ? frames.length : Math.floor(frames.length * 0.75);
  frames.forEach((f, i) => {
    if (i < fadeFrom) return;
    const k = 1 - (i - fadeFrom + 1) / (frames.length - fadeFrom);
    for (let a = 3; a < f.clear.length; a += 4) f.clear[a] = Math.round(f.clear[a] * k);
  });
  const sheet = lib.spriteSheet(fx, { ...r, n: frames.length, frames }, name);
  const meta = sheet.json.meta.pixelfx;
  const info = {
    fps: r.fps,
    frames: frames.length,
    size: meta.frameSize,
    columns: meta.columns,
    pivot: e.pivot ?? meta.pivot,
    scale: e.scale ?? 1,
    loop: fx.meta.loop,
  };
  writeFileSync(join(out, `${name}.png`), sheet.png);
  writeFileSync(join(out, `${name}.json`), JSON.stringify(info, null, "\t") + "\n");
  console.log(`fx: ${name} <- ${e.id}, ${frames.length} frames`);
}
