// Payload Protocol: a Fragile cargo breaks (SPEC Section 21.3). The hold is seen from above, so
// there is no floor: the shards fly out in all directions, tumble, slow down, and fade.
import { Particles, Bits, Lights, P, B, Rng, fit, sparkle, WHITE, TAU } from "../../core/index.js";

export const meta = {
  name: "Shard burst",
  desc: "Glass breaks from above: a white crack flash, a ring of tumbling lit shards that fly out and slow down, glints, and fine dust.",
  tags: ["impact", "glass", "break", "one-shot"],
  size: [128, 128],
  origin: [64, 64],
  duration: 0.9,
  loop: false,
  fps: 30,
  bg: "dark",
  options: { palette: ["#0c1430", "#162c5c", "#1f4f94", "#2f7fcc", "#58b4ec", "#9bdcff", "#d8f4ff", "#ffffff"], seed: 5 },
};

export function create(o) {
  const C = fit(o.palette, 8), R = new Rng(o.seed);
  const ps = new Particles({ rng: R, sparks: [C[7], C[6], C[5], C[3]] });
  const bits = new Bits();
  const lights = new Lights();
  lights.add(0, 0, 40, C[5], 0.6, 0.25);
  lights.add(0, 0, 16, C[7], 0.8, 0.1);
  // the shards: large ones first and slow, small ones fast; each tumbles and slows with drag
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * TAU + R.range(-0.2, 0.2), v = R.range(90, 220);
    bits.add({
      kind: B.SHARD, x: R.range(-3, 3), y: R.range(-3, 3), vx: Math.cos(a) * v, vy: Math.sin(a) * v,
      a: R.range(0, TAU), va: R.range(-14, 14), s: R.range(1.2, 2.6), c: R.pick([C[4], C[5], C[6]]),
      g: 0, drag: 4.2, life: R.range(0.5, 0.85),
    });
  }
  // glints and dust
  for (let i = 0; i < 12; i++) {
    const a = R.range(0, TAU), v = R.range(140, 300);
    ps.spawn(P.SPARK, 0, 0, Math.cos(a) * v, Math.sin(a) * v, R.range(0.15, 0.3), WHITE);
  }
  for (let i = 0; i < 8; i++) {
    const a = R.range(0, TAU), v = R.range(20, 60);
    ps.spawn(P.VAPOUR, 0, 0, Math.cos(a) * v, Math.sin(a) * v, R.range(0.4, 0.7), C[3], R.range(0.8, 1.4));
  }
  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
      bits.update(dt);
      lights.update(dt);
    },
    draw(p) {
      // the crack flash: a short star, then cracks that run out and fade
      if (t < 0.1) sparkle(p, 0, 0, 12 * (1 - t / 0.1), WHITE, C[6]);
      if (t < 0.3) {
        const k = 1 - t / 0.3;
        for (let i = 0; i < 6; i++) {
          const a = (i / 6) * TAU + 0.4, L = 10 + 14 * (1 - k);
          p.line(0, 0, Math.cos(a) * L, Math.sin(a) * L, C[6], k);
        }
      }
      ps.draw(p, "back");
      bits.draw(p);
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
