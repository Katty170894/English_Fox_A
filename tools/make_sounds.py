"""Generates the small shop sound effects (no external audio needed).
Run from the project root:  python3 tools/make_sounds.py
Writes assets/sounds/{boing,yay,wear,off}.wav  (44.1 kHz, mono, 16 bit).
"""
import wave
import numpy as np

SR = 44100
OUT = 'assets/sounds'


def t_(d):
    return np.arange(int(SR * d)) / SR


def env(n, attack=0.004, decay=6.0):
    t = np.arange(n) / SR
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-t * decay)


def tone(freq, d, decay=6.0, harm=(1, .35, .12)):
    t = t_(d)
    y = sum(h * np.sin(2 * np.pi * freq * (i + 1) * t) for i, h in enumerate(harm))
    return y * env(len(t), decay=decay)


def place(buf, sig, start):
    i = int(start * SR)
    buf[i:i + len(sig)] += sig[:len(buf) - i]


def save(name, y):
    y = y / max(1e-9, np.abs(y).max()) * 0.8
    # tiny fade-out to avoid clicks
    f = int(SR * 0.01)
    y[-f:] *= np.linspace(1, 0, f)
    with wave.open(f'{OUT}/{name}.wav', 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((y * 32767).astype('<i2').tobytes())


def boing():
    t = t_(0.55)
    f = 200 + 360 * (1 - np.exp(-t * 16)) + 40 * np.sin(2 * np.pi * 14 * t) * np.exp(-t * 4)
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = (np.sin(ph) + .3 * np.sin(2 * ph)) * env(len(t), attack=.006, decay=5.5)
    return y


def yay():
    buf = np.zeros(int(SR * 1.15))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        place(buf, tone(f, .5 if i == 3 else .22, decay=4 if i == 3 else 9), i * .1)
    for k, f in enumerate([2093, 2637, 3136, 2637, 3520]):
        place(buf, tone(f, .12, decay=22, harm=(1,)) * .25, .5 + k * .07)
    return buf


def wear():
    rng = np.random.default_rng(7)
    buf = np.zeros(int(SR * .26))
    n = int(SR * .12)
    noise = rng.standard_normal(n)
    k = np.ones(18) / 18  # crude low-pass -> soft "swoosh"
    noise = np.convolve(noise, k, 'same') * np.sin(np.linspace(0, np.pi, n)) ** 2
    place(buf, noise * .5, 0)
    t = t_(.14)
    pop = np.sin(2 * np.pi * (700 - 380 * t / .14) * t) * env(len(t), decay=22)
    place(buf, pop, .11)
    return buf


def off():
    t = t_(.16)
    f = 520 - 260 * t / .16
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), decay=16)


if __name__ == '__main__':
    for n, fn in (('boing', boing), ('yay', yay), ('wear', wear), ('off', off)):
        save(n, fn())
    print('ok')
