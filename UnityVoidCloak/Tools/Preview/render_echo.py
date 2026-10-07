"""Offline preview of the Echo Knight prototype stage (mirrors EchoWorldPoint.shader).

usage:
  dotnet run -c Release -- stage stage.bin
  dotnet run -c Release -- cloak.bin 10          (the knight, for the overlay)
  python3 render_echo.py stage.bin cloak.bin out.png --t 1.0 --waves strike
"""
import sys
import os
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_preview as rp  # noqa: E402

SPAWN = np.array([0.0, 0.05, -18.0])
LISTENER = np.array([4.0, 0.0, 10.0])
SPEED, BAND, HOLD = 26.0, 1.4, 1.5
STONE = np.array([0.9, 0.93, 1.0])
ENEMY = np.array([1.0, 0.16, 0.12])
GOLD = np.array([1.0, 0.78, 0.3])
BELLWAVE = np.array([1.0, 0.8, 0.38])


def reveal(P, waves, t):
    rev = np.zeros(len(P)); front = np.zeros(len(P)); enemy = np.zeros(len(P)); bell = np.zeros(len(P))
    to_sound = np.tile([0.0, 1.0, 0.0], (len(P), 1))
    for (origin, start, radius, source, strength) in waves:
        age = t - start
        if age < 0:
            continue
        d = P - origin
        dist = np.linalg.norm(d, axis=1)
        x = (dist - age * SPEED) / BAND
        band = np.exp(-x * x)
        since = age - dist / SPEED
        glow = np.where(since > 0, np.clip(1 - since / HOLD, 0, 1), 0) ** 2
        fade = 1 - np.clip((dist / radius - 0.7) / 0.3, 0, 1) ** 2 * (3 - 2 * np.clip((dist / radius - 0.7) / 0.3, 0, 1))
        r = np.maximum(band, glow * 0.8) * fade * strength * (dist <= radius)
        better = r > rev
        rev[better] = r[better]
        front[better] = (band * fade * strength)[better]
        enemy[better] = 1.0 if source == 1 else 0.0
        bell[better] = 1.0 if source == 3 else 0.0
        to_sound[better] = (-d / np.maximum(dist, 1e-3)[:, None])[better]
    return rev, front, enemy, bell, to_sound


def shade_world(S, waves, t):
    P, N = S[:, 0:3], S[:, 3:6]
    bright, rnd, cav, typ = S[:, 6], S[:, 7], S[:, 8], S[:, 9]
    rev, front, enemy, bell, to_sound = reveal(P, waves, t)
    base = np.where(typ[:, None] > 1.5, GOLD[None], np.where(typ[:, None] > 0.5, ENEMY[None], STONE[None]))
    base = base * (1 - enemy[:, None] * 0.85) + ENEMY[None] * enemy[:, None] * 0.85
    base = base * (1 - bell[:, None] * 0.6) + BELLWAVE[None] * bell[:, None] * 0.6
    facing = np.clip(np.sum(N * to_sound, 1), 0, 1)
    light = 0.25 + 0.75 * facing
    col = base * (bright * cav * light * 1.0)[:, None] + base * (front * 0.9 * 0.5)[:, None] + (front * 0.9 * 0.25)[:, None]
    col = col * np.clip(rev, 0, 1)[:, None]
    size = 0.085 * (1 + front * 0.9) * (0.6 + 0.4 * np.clip(rev * 1.5, 0, 1))
    keep = rev >= 0.01
    return P[keep], col[keep], size[keep]


def splat(img, zbuf_list, P, col, size, cam, fwd, right, up, f, W, H):
    rel = P - cam
    z = rel @ fwd
    ok = z > 0.3
    P, col, size, rel, z = P[ok], col[ok], size[ok], rel[ok], z[ok]
    px = W / 2 + (rel @ right) / z * f
    py = H / 2 - (rel @ up) / z * f
    rad = np.maximum(size * f / z, 0.5)
    R = int(min(np.ceil(rad.max()), 6))
    for dy in range(-R, R + 1):
        for dx in range(-R, R + 1):
            m = dx * dx + dy * dy <= rad * rad + 0.25
            ix = np.round(px[m] + dx).astype(int)
            iy = np.round(py[m] + dy).astype(int)
            k = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
            zbuf_list.append((iy[k] * W + ix[k], z[m][k], col[m][k]))


def render(stage, cloak, waves, t, W=960, H=600, pitch=12.0, dist=11.0, yaw=0.0, focus_h=2.4):
    focus = SPAWN + np.array([0, focus_h, 0])
    p, y = np.radians(pitch), np.radians(yaw)
    fwd = np.array([np.sin(y) * np.cos(p), -np.sin(p), np.cos(y) * np.cos(p)])
    cam = focus - fwd * dist
    right = np.cross([0, 1, 0], fwd); right /= np.linalg.norm(right)
    up = np.cross(fwd, right)
    f = H / (2 * np.tan(np.radians(30)))
    img = np.zeros((H, W, 3))
    items = []
    P, col, size = shade_world(stage, waves, t)
    splat(img, items, P, col, size, cam, fwd, right, up, f, W, H)
    if cloak is not None:
        C = cloak.copy()
        C[:, 0:3] += SPAWN
        ccol = rp.shade(C, cam, False)
        splat(img, items, C[:, 0:3], ccol, 0.016 * C[:, 14], cam, fwd, right, up, f, W, H)
    idx = np.concatenate([a for a, _, _ in items]); zz = np.concatenate([b for _, b, _ in items]); cc = np.concatenate([c for _, _, c in items])
    order = np.lexsort((zz, idx)); idx, cc = idx[order], cc[order]
    first = np.ones(len(idx), bool); first[1:] = idx[1:] != idx[:-1]
    flat = img.reshape(-1, 3); flat[idx[first]] = cc[first]
    return (np.clip(img, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8)


def main():
    stage = np.fromfile(sys.argv[1], dtype=np.float32).reshape(-1, 10).astype(np.float64)
    cloak = np.fromfile(sys.argv[2], dtype=np.float32).reshape(-1, 20).astype(np.float64) if sys.argv[2] != '-' else None
    out = sys.argv[3]
    t = float(sys.argv[sys.argv.index('--t') + 1]) if '--t' in sys.argv else 1.0
    kind = sys.argv[sys.argv.index('--waves') + 1] if '--waves' in sys.argv else 'strike'
    feet = SPAWN + np.array([0, 0.2, 0])
    waves = []
    if kind == 'strike':
        waves.append((feet, 0.0, 70.0, 2, 1.05))
    elif kind == 'walk':
        waves.append((feet, 0.0, 18.0, 0, 0.75))
    elif kind == 'bell':
        waves.append((np.array([-5.0, 3.6, -15.0]), 0.0, 45.0, 3, 1.2))
    elif kind == 'all':
        waves.append((feet, 0.0, 9999.0, 0, 1.0))
    waves.append((LISTENER + np.array([0, 0.2, 0]), t - 0.25, 7.0, 1, 0.9))   # the Listener's footstep
    Image.fromarray(render(stage, cloak, waves, t)).save(out)


if __name__ == '__main__':
    main()
