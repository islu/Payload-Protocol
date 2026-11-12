# Makes the placeholder sound effects in project/audio/sfx. All sounds are synthesized,
# so they need no row in docs/assets.md. Run: task sfx
import math, random, struct, sys, wave
RATE = 22050
OUT = sys.argv[1]
rng = random.Random(11)

def write(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(32000 * 0.9 * s / peak)) for s in samples))

def env(i, n, attack=0.005, decay=8.0):
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-decay * t)

def noise():
    return rng.uniform(-1, 1)

def lowpass(samples, k):
    out, y = [], 0.0
    for s in samples:
        y += k * (s - y); out.append(y)
    return out

def sweep(f0, f1, dur, decay, wave_noise=0.0):
    n = int(RATE * dur); out = []; ph = 0.0
    for i in range(n):
        f = f0 + (f1 - f0) * i / n
        ph += 2 * math.pi * f / RATE
        out.append((math.sin(ph) + wave_noise * noise()) * env(i, n, decay=decay))
    return out

def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def delay(samples, sec):
    return [0.0] * int(RATE * sec) + samples

# --- Payload Protocol (SPEC Section 21). Each name is a Sound.play() name. ---
# clack: a short metal click when a drop is valid (SPEC Section 21.1)
write("clack", mix(sweep(1400, 900, 0.05, 60), [0.6 * noise() * env(i, 0, 0.001, 90) for i in range(int(RATE * 0.03))]))
# deny: a low double buzz when an action fails
buzz_low = [0.6 * (1 if math.sin(2 * math.pi * 110 * i / RATE) > 0 else -1) * env(i, 0, 0.002, 18) for i in range(int(RATE * 0.12))]
write("deny", mix(buzz_low, delay(buzz_low, 0.14)))
# alarm: two rising tones, the warning before a shift step
write("alarm", mix(sweep(600, 900, 0.25, 3), delay(sweep(600, 900, 0.25, 3), 0.28)))
# rumble: a low noise while the cargo slides
write("rumble", [1.6 * s for s in lowpass([noise() * env(i, 0, 0.05, 4) for i in range(int(RATE * 0.6))], 0.03)])
# soft_hit: a hit with force 0 (a Cushion)
write("soft_hit", [0.5 * s for s in sweep(180, 120, 0.12, 30)])
# metal_hit: a heavy clang with a ring
clang = mix(*[[0.4 * s for s in sweep(f, f * 0.97, 0.5, 9)] for f in (420, 690, 1130)])
write("metal_hit", mix(sweep(140, 50, 0.2, 20), clang, [0.6 * noise() * env(i, 0, 0.001, 50) for i in range(int(RATE * 0.05))]))
# glass_break: a shatter of high tones and noise
shatter = mix(*[delay([0.5 * s for s in sweep(f, f * 0.8, 0.3, 12)], d) for f, d in ((2200, 0), (3100, 0.02), (1700, 0.05), (3600, 0.08))])
write("glass_break", mix(shatter, [0.8 * noise() * env(i, 0, 0.001, 25) for i in range(int(RATE * 0.15))]))
# explosion: a boom and a crackle
boom = sweep(90, 28, 1.0, 3.5)
crackle = [noise() * (1 if rng.random() < 0.08 else 0.15) * env(i, 0, 0.001, 5) for i in range(int(RATE * 0.8))]
write("explosion", mix([1.4 * s for s in boom], [0.6 * s for s in crackle], [noise() * env(i, 0, 0.001, 40) for i in range(int(RATE * 0.1))]))
# splash: a wet burst of filtered noise
write("splash", [1.5 * s for s in lowpass([noise() * env(i, 0, 0.005, 10) for i in range(int(RATE * 0.4))], 0.15)])
# buzz: an electric short
write("buzz", [0.5 * (1 if math.sin(2 * math.pi * 60 * i / RATE) > 0 else -1) * (0.5 + 0.5 * noise()) * env(i, 0, 0.001, 8) for i in range(int(RATE * 0.35))])
# shield: a soft rising hum
write("shield", mix(sweep(300, 600, 0.4, 5), [0.5 * s for s in sweep(450, 900, 0.4, 5)]))
# squelch: a low wet pop for a spoil
write("squelch", [1.2 * s for s in lowpass(sweep(220, 80, 0.3, 10, 0.6), 0.2)])
# coin: two bright tones for credits
write("coin", mix(sweep(1320, 1320, 0.12, 20), delay(sweep(1760, 1760, 0.3, 10), 0.08)))
print("ok")
