// Payload Protocol: MAGELLAN, the AI of the ship (SPEC Section 22). A small robot head seen from
// the front: a screen face with a rim light, one round eye that blinks, an antenna with a light that
// pulses, and a mouth line. With talk: true, the mouth moves.
import { fit, TAU, WHITE } from "../../core/index.js";

export const meta = {
  name: "Magellan",
  desc: "The pilot portrait: a screen-faced robot head with one blinking eye, a pulsing antenna light, and a mouth that moves when it talks.",
  tags: ["portrait", "robot", "ui", "loop"],
  size: [40, 40],
  origin: [20, 22],
  duration: 3,
  loop: true,
  fps: 30,
  bg: "dark",
  options: {
    palette: ["#0b1020", "#16223f", "#24365f", "#2f7fcc", "#5fd3ff", "#bff2ff", "#ffffff"],
    talk: false,
  },
};

// The eye is closed in this part of the loop (seconds).
const BLINK = [2.55, 2.7];

export function draw(p, t, o) {
  const C = fit(o.palette, 7);
  // The antenna: a stalk and a light that pulses two times in a loop.
  p.line(0, -12, 0, -17, C[3]);
  const pulse = 0.5 + 0.5 * Math.sin((t / meta.duration) * TAU * 2);
  p.circle(0, -18, 2, pulse > 0.5 ? C[5] : C[4]);
  p.glow(0, -18, 6, C[4], 0.25 + 0.35 * pulse);
  // The head: a dark plate, a lighter rim, and a screen face.
  p.rect(-15, -12, 30, 26, C[1]);
  p.rect(-14, -11, 28, 24, C[2]);
  p.rect(-12, -9, 24, 19, C[0]);
  p.line(-12, -10, 11, -10, C[3]);
  p.line(-15, -12, 14, -12, C[3]);
  // Ears: two bolts at the sides.
  p.rect(-17, -3, 2, 5, C[3]);
  p.rect(15, -3, 2, 5, C[3]);
  // The eye: a ring and a bright core, a flat line when it blinks.
  const closed = !o.talk && t >= BLINK[0] && t < BLINK[1];
  if (closed) p.line(-4, -3, 4, -3, C[4]);
  else {
    p.circle(0, -3, 5, C[3]);
    p.circle(0, -3, 3.5, C[4]);
    p.circle(-1, -4, 1.5, WHITE);
    p.glow(0, -3, 9, C[4], 0.35);
  }
  // The mouth: a line, or a box that opens and closes six times each second.
  if (o.talk) {
    const open = Math.round(1 + 2 * (0.5 + 0.5 * Math.sin(t * TAU * 6)));
    p.rect(-4, 5, 8, open, C[5]);
  } else {
    // A dry smirk: one end of the mouth goes up.
    p.line(-4, 6, 1, 6, C[4]);
    p.line(2, 5, 3, 5, C[4]);
  }
}
