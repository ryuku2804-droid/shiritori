"""Offline point-splat preview of the generated cloak (mirrors VoidCloakPointShader lighting).

usage: python3 render_preview.py cloak.bin out.png [--debug] [--size 900]
Renders front / three-quarter / side / back views side by side.
"""
import sys
import numpy as np
from PIL import Image

PART_COLORS = np.array([
    [1, .2, .2], [1, .6, .2], [1, 1, .2], [.9, .9, .9], [.2, .2, .2],
    [.2, .6, 1], [.2, 1, 1], [.3, .8, .3], [.5, 1, .5], [.1, .5, .1], [.2, .7, .2],
    [.8, .4, 1], [1, .3, .7], [1, .6, .8], [.6, .3, .1], [.4, .4, 1], [.6, .6, 1],
    [.7, .5, .2], [.8, .6, .3], [.9, .7, .4], [.5, .7, .2], [.6, .8, .3], [.7, .9, .4],
    [1, 1, 1], [1, 0, 1],
    [.85, .9, 1], [1, 1, .6], [1, .85, .3], [.6, .35, .15], [.9, .9, .6], [.3, .3, .9], [.1, .1, .1]])


def normalize(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-8)


def shade(d, cam, debug):
    P, N, T = d[:, 0:3], d[:, 3:6], d[:, 6:9]
    col = d[:, 10:14]
    uv0, uv1 = d[:, 14:16], d[:, 16:18]
    part = np.floor(col[:, 0] * 32).astype(int).clip(0, len(PART_COLORS) - 1)
    if debug:
        return PART_COLORS[part] * (0.35 + 0.65 * np.clip(N @ normalize(np.array([-.4, .7, .6])), 0, 1))[:, None]

    ridge = col[:, 1] * 2 - 1
    void = col[:, 2]
    ao = uv1[:, 1]
    V = normalize(cam[None, :] - P)
    ndv = np.sum(N * V, 1)
    back = ndv < 0
    N = np.where(back[:, None], -N, N)
    ndv = np.abs(ndv)
    L = normalize(np.array([-0.45, 0.75, 0.6]))
    ndl = N @ L
    diffuse = (ndl * 0.5 + 0.5) ** 2
    H = normalize(L[None, :] + V)
    B = normalize(np.cross(N, T))
    ht, hb, hn = np.sum(H * T, 1), np.sum(H * B, 1), np.sum(H * N, 1)
    ax, ay = 0.55, 0.16
    e = ((ht / ax) ** 2 + (hb / ay) ** 2) / np.maximum(hn * hn, 1e-3)
    spec = np.exp(-e) * np.sqrt(np.clip(ndl, 0, 1))
    crest = np.clip(ridge, 0, 1)
    base = np.array([0.022, 0.022, 0.025])
    sheen = np.array([0.62, 0.64, 0.68])
    c = base[None] * (0.35 + 1.5 * diffuse[:, None]) * ao[:, None]
    c += sheen[None] * (0.42 * spec * (0.55 + 0.9 * crest) * ao)[:, None]
    c += np.array([0.3, 0.32, 0.36])[None] * (0.25 * (1 - ndv) ** 4 * ao)[:, None]
    mat = np.round(d[:, 18]).astype(int)
    grip = mat == 2
    c[grip] = (np.array([0.07, 0.045, 0.03])[None] * (0.35 + 1.5 * diffuse[grip, None]) * ao[grip, None]
               + sheen[None] * (0.42 * 0.35 * spec[grip] * ao[grip])[:, None])
    steel = mat == 1
    back = back & ~steel
    if steel.any():
        Ns, Vs = N[steel], V[steel]
        R = 2 * np.sum(Ns * Vs, 1)[:, None] * Ns - Vs
        horizon = np.exp(-R[:, 1] ** 2 * 30) * 0.35
        t = np.clip((R[:, 1] + 0.15) / 0.5, 0, 1); t = t * t * (3 - 2 * t)
        lo, hi = np.array([0.03, 0.03, 0.035]), np.array([0.58, 0.6, 0.64])
        env = lo[None] * (1 - t[:, None]) + hi[None] * t[:, None] + hi[None] * horizon[:, None]
        fres = 0.6 + 0.4 * (1 - ndv[steel]) ** 3
        sp = np.clip(np.sum(Ns * H[steel], 1), 0, 1) ** 90 * 1.6
        wrap = np.clip((ndl[steel] + 0.5) / 1.5, 0, 1)
        edge = 1 + 0.6 * np.clip(ridge[steel], 0, 1)
        c[steel] = (np.array([0.42, 0.43, 0.45])[None] * (0.15 + 0.35 * wrap)[:, None]
                    + env * (0.55 * fres * edge)[:, None] + sp[:, None])
    c = np.where(back[:, None], c * 0.12, c)
    c = c * (1 - void[:, None]) + 0.004 * void[:, None]
    return c


def render(d, yaw, size, debug, point_size=0.02):
    target = np.array([0.0, 2.15, 0.0])
    dist = 11.0
    cam = target + dist * np.array([np.sin(yaw), 0.08, np.cos(yaw)])
    fwd = normalize(target - cam)
    right = normalize(np.cross(fwd, [0, 1, 0]))  # math cross; we flip x later
    up = np.cross(right, fwd)
    P = d[:, 0:3]
    rel = P - cam
    z = rel @ fwd
    x = rel @ right
    y = rel @ up
    f = size / (2 * np.tan(np.radians(26) / 2))
    W = H = size
    px = W / 2 - x / z * f   # Unity is left handed: +X appears on screen right when looking down +Z... keep viewer convention
    px = W / 2 + x / z * f
    py = H / 2 - y / z * f
    col = shade(d, cam, debug)
    rad = np.maximum(point_size * d[:, 14] * f / z, 0.5)

    img = np.ones((H, W, 3)) * np.array([0.93, 0.93, 0.92])
    zbuf = np.full(H * W, np.inf)
    R = int(np.ceil(rad.max()))
    idx_all, z_all, c_all = [], [], []
    for dy in range(-R, R + 1):
        for dx in range(-R, R + 1):
            m = dx * dx + dy * dy <= rad * rad + 0.25
            ix = np.round(px[m] + dx).astype(int)
            iy = np.round(py[m] + dy).astype(int)
            ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
            idx_all.append(iy[ok] * W + ix[ok])
            z_all.append(z[m][ok])
            c_all.append(col[m][ok])
    idx = np.concatenate(idx_all); zz = np.concatenate(z_all); cc = np.concatenate(c_all)
    order = np.lexsort((zz, idx))
    idx, cc = idx[order], cc[order]
    first = np.ones(len(idx), bool)
    first[1:] = idx[1:] != idx[:-1]
    flat = img.reshape(-1, 3)
    flat[idx[first]] = cc[first]
    img = flat.reshape(H, W, 3)
    img = np.clip(img, 0, 1) ** (1 / 2.2)
    return (img * 255).astype(np.uint8)


def main():
    path, out = sys.argv[1], sys.argv[2]
    debug = '--debug' in sys.argv
    size = 700
    if '--size' in sys.argv:
        size = int(sys.argv[sys.argv.index('--size') + 1])
    views = [0.0, 0.6, np.pi / 2, np.pi]
    if '--views' in sys.argv:
        views = [float(v) for v in sys.argv[sys.argv.index('--views') + 1].split(',')]
    d = np.fromfile(path, dtype=np.float32).reshape(-1, 20).astype(np.float64)
    if '--motion' in sys.argv:
        # mirrors MotionOffset() in the shader: --motion lagZ,stepPhase,stepPush,bob,billow,time
        vals = [float(v) for v in sys.argv[sys.argv.index('--motion') + 1].split(',')]
        lag_z, phase, push, bob = vals[:4]
        billow = vals[4] if len(vals) > 4 else 0.0
        t = vals[5] if len(vals) > 5 else 0.0
        p, w, floor = d[:, 0:3].copy(), d[:, 15], d[:, 19]
        if '--no-floor' not in sys.argv:
            w = np.maximum(w, floor * 0.85)
        w2 = w * w
        lag_len = abs(lag_z)
        trail = np.array([0.0, -np.sign(lag_z)]) if lag_len > 1e-4 else np.zeros(2)
        radial = p[:, [0, 2]] / np.maximum(np.linalg.norm(p[:, [0, 2]], axis=1, keepdims=True), 1e-3)
        behind = np.clip(radial @ trail, 0, 1)
        puff = 0.65 + 0.7 * behind * (0.5 + 0.5 * min(billow, 1.0))
        off = np.zeros_like(p)
        off[:, 0] = trail[0] * lag_len * w2 * puff
        off[:, 2] = trail[1] * lag_len * w2 * puff
        off[:, 1] = lag_len * w2 * (0.12 + 0.3 * behind * min(billow, 1.0))
        wave = np.sin(t * 8 - p[:, 1] * 2.3 + p[:, 0] * 1.7) + 0.5 * np.sin(t * 13 - p[:, 1] * 3.9 - p[:, 2] * 2.3)
        k = wave * billow * w * 0.1 * (0.4 + behind)
        off[:, 0] += trail[0] * k
        off[:, 2] += trail[1] * k
        off[:, 1] += wave * billow * w2 * 0.05
        off[:, 0] += np.sin(t * 6.5 + p[:, 1] * 1.3 + p[:, 2] * 1.1) * billow * w2 * 0.07
        if '--no-floor' not in sys.argv:
            floor_wave = 0.75 + 0.25 * np.sin(t * 9 - np.linalg.norm(p[:, [0, 2]], axis=1) * 3 + p[:, 0] * 1.3)
            off[:, 1] += floor * billow * 0.3 * (0.35 + 0.65 * behind) * floor_wave
        side = np.clip(p[:, 0] / 0.5, -1, 1)
        front = np.clip(p[:, 2] / 0.8 + 0.4, 0, 1)
        off[:, 2] += np.sin(phase) * side * front * push * w
        off[:, 1] += bob * np.clip(p[:, 1] / 1.5, 0, 1)
        d[:, 0:3] = p + off
        if '--no-floor' not in sys.argv:
            d[floor > 0.01, 1] = np.maximum(d[floor > 0.01, 1], 0.003)
    imgs = [render(d, yaw, size, debug) for yaw in views]
    Image.fromarray(np.concatenate(imgs, axis=1)).save(out)


if __name__ == '__main__':
    main()
