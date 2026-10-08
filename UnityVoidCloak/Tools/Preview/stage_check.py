"""Top-down map + walkability check (BFS for a capsule over the real colliders)."""
import sys, numpy as np
from collections import deque
from PIL import Image, ImageDraw
prefix = sys.argv[1]
pts = np.fromfile(prefix + '.bin', dtype=np.float32).reshape(-1, 10)
boxes = np.loadtxt(prefix + '_boxes.txt')
meta = [l.split() for l in open(prefix + '_meta.txt')]
spawn = np.array([float(v) for v in meta[0][1:4]]); goal = np.array([float(v) for v in meta[1][1:7]])

RES = 0.25; RADIUS = 0.8; HEIGHT = 4.2; STEP = 0.6
x0, x1 = pts[:, 0].min() - 2, pts[:, 0].max() + 2
z0, z1 = pts[:, 2].min() - 2, pts[:, 2].max() + 2
nx, nz = int((x1 - x0) / RES), int((z1 - z0) / RES)
gx = x0 + (np.arange(nx) + 0.5) * RES; gz = z0 + (np.arange(nz) + 0.5) * RES
X, Z = np.meshgrid(gx, gz, indexing='ij')

def footprint(b):
    cx, cy, cz, sx, sy, sz, yaw = b
    a = np.radians(yaw); c, s = np.cos(a), np.sin(a)
    dx, dz = X - cx, Z - cz
    lx = dx * c - dz * s; lz = dx * s + dz * c          # into the box's local frame
    return (np.abs(lx) <= sx / 2) & (np.abs(lz) <= sz / 2)

foot = [footprint(b) for b in boxes]
bottoms = boxes[:, 1] - boxes[:, 4] / 2; tops = boxes[:, 1] + boxes[:, 4] / 2
levels = sorted(set(np.round(t, 2) for t in tops if -10.0 <= t <= 40.0))   # (wall and ceiling tops are levels too, but never reachable)

# disc offsets for the capsule radius
r = int(np.ceil(RADIUS / RES)); offs = [(i, j) for i in range(-r, r + 1) for j in range(-r, r + 1) if (i * RES) ** 2 + (j * RES) ** 2 <= RADIUS ** 2]
def dilate(m):
    out = np.zeros_like(m)
    for i, j in offs:
        out |= np.roll(np.roll(m, i, 0), j, 1)
    return out

support, blocked = {}, {}
for L in levels:
    sup = np.zeros((nx, nz), bool); blk = np.zeros((nx, nz), bool)
    for k, b in enumerate(boxes):
        if abs(tops[k] - L) < 0.03: sup |= foot[k]
        # anything solid between the knees and the top of the head blocks the capsule
        if bottoms[k] < L + HEIGHT and tops[k] > L + STEP + 0.05: blk |= foot[k]
    support[L] = sup; blocked[L] = dilate(blk)

def cell(p): return int((p[0] - x0) / RES), int((p[2] - z0) / RES)
start = cell(spawn); L0 = min(levels, key=lambda l: abs(l - spawn[1]))
seen = {}; q = deque([(start, L0)]); seen[(start, L0)] = None
reach = np.zeros((nx, nz), bool)
while q:
    (i, j), L = q.popleft(); reach[i, j] = True
    for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ni, nj = i + di, j + dj
        if not (0 <= ni < nx and 0 <= nj < nz): continue
        for L2 in levels:
            if L2 - L > STEP + 1e-3: continue          # too high to step up
            if not support[L2][ni, nj] or blocked[L2][ni, nj]: continue
            # stand on the highest supporting level we can reach here
            higher = [l for l in levels if l > L2 and l - L <= STEP + 1e-3 and support[l][ni, nj] and not blocked[l][ni, nj]]
            if higher: continue
            key = ((ni, nj), L2)
            if key in seen: continue
            seen[key] = ((i, j), L); q.append(key)

gc = cell(goal[:3]); gi0, gi1 = int(goal[3] / 2 / RES), int(goal[5] / 2 / RES)
goal_cells = [k for k in seen if abs(k[0][0] - gc[0]) <= gi0 and abs(k[0][1] - gc[1]) <= gi1 and abs(k[1] - (goal[1] - 2)) < 1.0]
print(f"levels: {levels}")
print(f"reachable cells: {reach.sum()}  goal reached: {bool(goal_cells)}")

# leaks: a reachable spot next to a spot with nothing to stand on and nothing blocking -> the knight could walk off the edge
leaks = []
for ((i, j), L) in seen:
    for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ni, nj = i + di, j + dj
        if not (0 <= ni < nx and 0 <= nj < nz): leaks.append((i, j)); continue
        if any(support[l][ni, nj] for l in levels if l <= L + STEP + 1e-3): continue
        if blocked[L][ni, nj]: continue
        leaks.append((i, j))
print(f"edge leaks: {len(leaks)}" + ("" if not leaks else "  e.g. " + ", ".join(f"({gx[i]:.1f}, {gz[j]:.1f})" for i, j in leaks[:8])))

# path back from the goal
path = []
if goal_cells:
    k = goal_cells[0]
    while k is not None: path.append(k[0]); k = seen[k]
    print(f"path length: {len(path) * RES:.1f} units")

# ---- map image
S = 4  # pixels per cell
img = Image.new('RGB', (nx * S // 2, nz * S // 2), (8, 8, 10)); d = ImageDraw.Draw(img)
sc = S / 2 / RES
def px(x, z): return ((x - x0) * sc, (z1 - z) * sc)
cols = {0: (150, 155, 165), 1: (230, 50, 40), 2: (240, 190, 80)}
sel = pts[np.random.default_rng(0).choice(len(pts), min(len(pts), 250000), replace=False)]
for t in (0, 2, 1):
    m = sel[:, 9] == t
    for x, z, y in zip(sel[m, 0], sel[m, 2], sel[m, 1]):
        c = cols[t] if t else tuple(int(v * (0.45 + 0.55 * min(1, y / 6))) for v in cols[0])
        X_, Y_ = px(x, z); d.point((X_, Y_), fill=c)
ri, rj = np.nonzero(reach)
for i, j in zip(ri[::3], rj[::3]):
    X_, Y_ = px(gx[i], gz[j]); d.point((X_, Y_), fill=(40, 90, 60))
for (i, j) in path[::2]:
    X_, Y_ = px(gx[i], gz[j]); d.ellipse((X_ - 1.5, Y_ - 1.5, X_ + 1.5, Y_ + 1.5), fill=(90, 220, 255))
for l in meta[2:]:
    kind = l[0]; v = [float(a) for a in l[1:]]
    if kind == 'hint':
        a, b = px(v[0] - v[3] / 2, v[2] + v[5] / 2), px(v[0] + v[3] / 2, v[2] - v[5] / 2); d.rectangle((a, b), outline=(80, 160, 255))
    else:
        X_, Y_ = px(v[0], v[2]); col = {'ghost': (255, 220, 120), 'shrine': (255, 200, 60), 'listener': (255, 60, 50), 'armor': (255, 120, 90), 'bell': (255, 230, 90)}[kind]
        d.ellipse((X_ - 6, Y_ - 6, X_ + 6, Y_ + 6), outline=col, width=2)
        if kind == 'listener':
            rr = v[3] * sc; d.ellipse((X_ - rr, Y_ - rr, X_ + rr, Y_ + rr), outline=(120, 40, 40))
a, b = px(goal[0] - goal[3] / 2, goal[2] + goal[5] / 2), px(goal[0] + goal[3] / 2, goal[2] - goal[5] / 2); d.rectangle((a, b), outline=(255, 230, 120), width=2)
X_, Y_ = px(spawn[0], spawn[2]); d.ellipse((X_ - 7, Y_ - 7, X_ + 7, Y_ + 7), fill=(90, 220, 255))
img.save(prefix + '_map.png')
print('map', img.size)

if '--debug' in sys.argv:
    ri, rj = np.nonzero(reach)
    print("reach x range", gx[ri].min(), gx[ri].max(), " z range", gz[rj].min(), gz[rj].max())
    # what blocks the cells just north of the reachable area, on the corridor centreline
    for z in np.arange(gz[rj].max() - 0.5, gz[rj].max() + 3, 0.5):
        i, j = cell(np.array([0.0, 0, z]))
        hits = [k for k in range(len(boxes)) if foot[k][i, j]]
        print(f"z={z:6.2f} support0={support[0.0][i, j]} blocked0={blocked[0.0][i, j]} boxes={[tuple(np.round(boxes[k][[0, 1, 2, 3, 4, 5]], 2)) for k in hits]}")
