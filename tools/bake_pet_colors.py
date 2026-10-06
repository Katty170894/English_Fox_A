"""Bakes the recoloured pictures used by the shop (all four animals).

Run from the project root:   python3 tools/bake_pet_colors.py
Needs: pip install pillow numpy scipy

Reads the first four tiles of assets/animals-atlas.png and writes, for every
animal A and colour C:
  assets/pets/A_fur_C.png   - the whole animal with its fur recoloured
                              (nose, tongue, inner ears, eyes untouched)
  assets/pets/A_eyes_C.png  - a transparent layer holding ONLY the iris,
                              recoloured; drawn on top of the animal.

Two ways of recolouring fur:
  'hue'  - orange fox / brown bear: the warm hue is rotated to the new one.
  'tint' - white rabbit / grey cat (no hue to rotate): the fur is multiplied
           with a colour, which keeps all the soft shading.

Add a colour = one line in FUR / EYES + one ShopItem in lib/game_state.dart
with the same style id.
"""
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ATLAS = 'assets/animals-atlas.png'
OUT = 'assets/pets'

# id: (target hue in degrees, hue-mode sat multiplier, hue-mode value
#      multiplier, tint-mode multiply colour)
FUR = {
    'silver': (212, 0.13, 0.90, (0.80, 0.86, 0.97)),
    'blue': (203, 0.95, 1.00, (0.45, 0.72, 1.00)),
    'purple': (272, 0.80, 0.95, (0.70, 0.52, 1.00)),
    'pink': (336, 0.62, 1.06, (1.00, 0.62, 0.80)),
}
# id: target hue in degrees
EYES = {'sky': 200, 'green': 125, 'purple': 280, 'pink': 330}

# index in the atlas, recolour mode, eye centres (px in the 313px tile),
# iris radius, radius of the whole eye (white + lashes), and extra circles
# (x, y, r) that must never be recoloured (the bear's nose).
PETS = {
    'fox': dict(tile=0, mode='hue', eyes=[(146.5, 138.0), (209.5, 125.0)],
                iris=12.5, socket=16.5,
                socket_at=[(145.0, 139.0), (212.5, 124.5)], keep=[]),
    'rabbit': dict(tile=1, mode='tint', eyes=[(122.5, 144.7), (176.8, 149.8)],
                   iris=10.8, socket=15.5,
                   socket_at=[(118.5, 141.5), (181.0, 148.0)],
                   floor=298, keep=[]),
    'bear': dict(tile=2, mode='hue', eyes=[(140.4, 109.7), (197.5, 113.7)],
                 iris=10.8, socket=13.8,
                 socket_at=[(136.3, 108.0), (201.5, 112.5)],
                 keep=[(167, 129, 13.4)], sat_edge=(0.13, 0.28)),
    'cat': dict(tile=3, mode='tint', eyes=[(118.5, 131.0), (172.8, 141.4)],
                iris=12.3, socket=16.2,
                socket_at=[(115.0, 129.5), (175.5, 140.0)],
                floor=294, keep=[]),
}


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1)
    mn = a.min(-1)
    d = mx - mn
    nz = d > 1e-6
    dd = np.where(nz, d, 1)
    rc, gc, bc = (mx - r) / dd, (mx - g) / dd, (mx - b) / dd
    h = np.where(mx == r, bc - gc, np.where(mx == g, 2.0 + rc - bc, 4.0 + gc - rc))
    h = np.where(nz, (h / 6.0) % 1.0, 0)
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1), 0)
    return np.stack([h, s, mx], -1)


def hsv_to_rgb(a):
    h, s, v = a[..., 0], a[..., 1], a[..., 2]
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    out = np.zeros(a.shape)
    for k, (rr, gg, bb) in enumerate(
            [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        m = i == k
        out[..., 0] = np.where(m, rr, out[..., 0])
        out[..., 1] = np.where(m, gg, out[..., 1])
        out[..., 2] = np.where(m, bb, out[..., 2])
    return out


def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def circles(shape, centres, r, feather=1.5):
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    m = np.zeros(shape)
    for cx, cy in centres:
        d = np.hypot(xx - cx, yy - cy)
        m = np.maximum(m, 1 - smooth(d, r - feather, r + 1.0))
    return m


def foreground(rgb):
    """1 where the animal is, 0 on the white background (soft edge)."""
    mn = rgb.min(-1)
    bg = ndimage.binary_opening(mn >= 0.975, iterations=1)
    lab, _ = ndimage.label(bg)
    border = set(np.unique(np.concatenate(
        [lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    is_bg = np.isin(lab, list(border))
    fg = ndimage.binary_fill_holes(~is_bg)
    # the faint ground shadow is a thin horizontal sliver: opening with a
    # tall, 1px-wide element removes it from the lower part of the picture
    opened = ndimage.binary_opening(fg, structure=np.ones((11, 1)))
    low = np.arange(fg.shape[0])[:, None] > 262
    fg = np.where(low, opened, fg)
    soft = ndimage.gaussian_filter(fg.astype(float), 1.0)
    # near the silhouette also fade with how far from white the pixel is
    edge = smooth(1 - mn, 0.01, 0.07)
    inner = ndimage.binary_erosion(fg, iterations=4)
    return np.where(inner, 1.0, soft * np.maximum(edge, .35)) * fg


def main():
    atlas = Image.open(ATLAS).convert('RGB')
    t = atlas.size[0] // 4
    os.makedirs(OUT, exist_ok=True)
    for name, cfg in PETS.items():
        tile = atlas.crop((cfg['tile'] * t, 0, (cfg['tile'] + 1) * t, t))
        rgb = np.asarray(tile).astype(float) / 255
        hsv = rgb_to_hsv(rgb)
        hue, sat, val = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
        shape = val.shape

        not_eyes = 1 - circles(shape, cfg['socket_at'], cfg['socket'])
        not_keep = 1 - (circles(shape, [(x, y) for x, y, _ in cfg['keep']],
                                cfg['keep'][0][2]) if cfg['keep'] else 0)
        # pink / red parts (tongue, nose, inner ears) are left alone
        pink = smooth(hue, 318, 335) + (1 - smooth(hue, 12, 24))
        pink = np.clip(pink, 0, 1) * smooth(sat, 0.10, 0.22)
        not_pink = 1 - pink

        if cfg['mode'] == 'hue':
            warm = smooth(hue, 4, 14) * (1 - smooth(hue, 46, 60))
            lo, hi = cfg.get('sat_edge', (0.28, 0.5))
            w = warm * smooth(sat, lo, hi) * not_eyes * not_keep
        else:
            w = foreground(rgb) * not_eyes * not_keep * not_pink
            # the dark pupils/nose/mouth line stay as they are
            w = w * smooth(val, 0.16, 0.30)
            if 'floor' in cfg:  # nothing below the paws (shadow)
                ys = np.arange(shape[0])[:, None]
                w = w * (1 - smooth(ys, cfg['floor'] - 1, cfg['floor'] + 2))

        # --- iris layer weight (same for every animal) ---
        sclera = smooth(val, 0.78, 0.9) * (1 - smooth(sat, 0.12, 0.28))
        iris_w = (circles(shape, cfg['eyes'], cfg['iris']) *
                  (1 - sclera) * smooth(val, 0.12, 0.24))

        for cid, (h, sm, vm, tint) in FUR.items():
            if cfg['mode'] == 'hue':
                new = hsv.copy()
                new[..., 0] = h / 360
                new[..., 1] = np.clip(sat * sm, 0, 1)
                new[..., 2] = np.clip(val * vm, 0, 1)
                rec = hsv_to_rgb(new)
            else:
                base = rgb
                if cid == 'silver':  # lift greys so a grey cat visibly changes
                    base = 1 - (1 - rgb) * 0.55
                rec = np.clip(base * np.array(tint), 0, 1)
            out = rgb * (1 - w[..., None]) + rec * w[..., None]
            Image.fromarray((out * 255 + .5).astype(np.uint8)).save(
                f'{OUT}/{name}_fur_{cid}.png', optimize=True)

        for cid, h in EYES.items():
            new = hsv.copy()
            new[..., 0] = h / 360
            new[..., 1] = np.clip(np.maximum(sat, 0.72), 0, 1)
            new[..., 2] = np.clip(np.maximum(val * 1.1, 0.5), 0, 1)
            rec = hsv_to_rgb(new)
            a = np.clip(iris_w, 0, 1)
            rec = rec * (a[..., None] > 0.003)
            img = np.dstack([rec, a])
            Image.fromarray((img * 255 + .5).astype(np.uint8), 'RGBA').save(
                f'{OUT}/{name}_eyes_{cid}.png', optimize=True)
    print('done')


if __name__ == '__main__':
    main()
