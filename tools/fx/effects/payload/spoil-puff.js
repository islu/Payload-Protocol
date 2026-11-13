// Payload Protocol: a Perishable cargo spoils at the arrival (SPEC Section 21.3). Seen from above:
// a green cloud swells out of the cargo, bubbles pop in it, and motes drift up and fade.
import { Particles, Lights, P, Rng, fit, TAU } from "../../core/index.js";

export const meta = {
  name: "Spoil puff",
  desc: "Food goes bad: a sickly green cloud swells and thins, small bubbles rise and pop, and pale motes drift off.",
  tags: ["poison", "cloud", "spoil", "one-shot"],
  size: [128, 112],
  origin: [64, 72],
  duration: 1.4,
  loop: false,
  fps: 30,
  bg: "dark",
  options: { palette: ["#0d1a0c", "#173a14", "#265e18", "#3f8a1e", "#6cb82a", "#a8e04a", "#e0ff8a"], seed: 9 },
};

export function create(o) {
  const C = fit(o.palette, 7), R = new Rng(o.seed);
  const ps = new Particles({ rng: R, haze: C[3] });
  const lights = new Lights();
  lights.add(0, -6, 44, C[4], 0.35, 0.9);
  // the cloud: soft puffs that swell and thin, a little up
  for (let i = 0; i < 14; i++) {
    const a = R.range(0, TAU), v = R.range(10, 45);
    ps.spawn(P.VAPOUR, R.range(-6, 6), R.range(-4, 4), Math.cos(a) * v, Math.sin(a) * v * 0.6 - 18,
      R.range(0.7, 1.2), R.pick([C[3], C[4], C[2]]), R.range(1.6, 2.6), R.range(0, 0.25));
  }
  // motes that drift up
  for (let i = 0; i < 10; i++)
    ps.spawn(P.MOTE, R.range(-14, 14), R.range(-6, 6), R.range(-10, 10), R.range(-50, -25),
      R.range(0.5, 0.9), C[6], 1, R.range(0.1, 0.5));
  // the body of the cloud: lumps that swell, rise a little, and thin out
  const lumps = [];
  for (let i = 0; i < 7; i++) {
    const a = (i / 7) * TAU + R.range(-0.3, 0.3), d = i === 0 ? 0 : R.range(8, 16);
    lumps.push({ x: Math.cos(a) * d, y: Math.sin(a) * d * 0.7, r: R.range(9, 14), t0: R.range(0, 0.15) });
  }
  // bubbles: each rises, swells, and pops
  const bubbles = [];
  for (let i = 0; i < 6; i++)
    bubbles.push({ x: R.range(-14, 14), y: R.range(-4, 6), t0: R.range(0.05, 0.6), life: R.range(0.3, 0.5), r: R.range(2, 4) });
  let t = 0;
  return {
    update(dt) {
      t += dt;
      ps.update(dt);
      lights.update(dt);
    },
    draw(p) {
      ps.draw(p, "back");
      for (const l of lumps) {
        const u = Math.max(0, Math.min(1, (t - l.t0) / 1.1));
        if (u <= 0 || u >= 1) continue;
        const grow = 0.4 + 0.6 * Math.sqrt(u), fade = u < 0.15 ? u / 0.15 : 1 - (u - 0.15) / 0.85;
        const x = l.x * grow * 1.3, y = l.y * grow * 1.3 - u * 10;
        p.disc(x, y, l.r * grow, C[2], 0.55 * fade);
        p.disc(x - 1, y - 2, l.r * grow * 0.7, C[3], 0.45 * fade);
        p.disc(x - 2, y - 3, l.r * grow * 0.35, C[4], 0.35 * fade);
      }
      for (const b of bubbles) {
        const u = (t - b.t0) / b.life;
        if (u < 0 || u > 1.15) continue;
        const y = b.y - u * 14;
        if (u <= 1) {
          p.ring(b.x, y, b.r * (0.5 + u * 0.5), 1, C[5], 0.9);
          p.px(b.x - 1, y - b.r * 0.5, C[6]);
        } else {
          // the pop: four specks
          for (let k = 0; k < 4; k++) p.px(b.x + Math.cos(k * TAU / 4) * b.r * 1.4, y + Math.sin(k * TAU / 4) * b.r * 1.4, C[6]);
        }
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
