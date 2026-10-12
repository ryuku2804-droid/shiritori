"""ステージのレイアウトを Unity を開かずにチェックする。

使い方:
    python3 BlindSpot/tools/check_layout.py [ステージのクラス名]   (省略時 PrototypeStage)

やること:
  1. StageLayout.cs とステージの .cs を、UnityEngine の最小スタブと一緒に mono (mcs) でコンパイルする
  2. Build() を実行して、置かれる箱の一覧を JSON で受け取る
  3. 10cm 四方のマス目でプレイヤー (半径 0.35m・身長 1.8m / しゃがみ 1.0m) が歩ける範囲を BFS で調べ、
     - スタート地点が埋まっていないか
     - 素材の床 (SurfaceMaterial 付き) にすべてたどり着けるか
     - 歩ける場所のとなりに、床の無い穴 (落ちる場所) がないか
     - しゃがまないと通れない場所がどこにあるか
     - 怪物の出発点と巡回ポイントが、立って歩ける場所にあるか
     - ロッカーの出口に立てるか、机の下にしゃがんで入れるか、落ちている物を拾いに行けるか
     を表示する。問題があれば終了コード 1。
"""
import json
import math
import pathlib
import re
import subprocess
import sys
import tempfile
from collections import deque

ROOT = pathlib.Path(__file__).resolve().parent.parent  # BlindSpot/
STAGE_DIR = ROOT / "Assets/BlindSpot/Editor/Stage"
SURFACE_CS = ROOT / "Assets/BlindSpot/Scripts/Noise/SurfaceMaterial.cs"
THROWABLES_CS = ROOT / "Assets/BlindSpot/Scripts/Throwing/Throwables.cs"

RADIUS = 0.35
STAND_HEIGHT = 1.8
CROUCH_HEIGHT = 1.0
STEP_OFFSET = 0.3
CELL = 0.1

UNITY_STUB = r"""
namespace UnityEngine {
  public struct Vector3 {
    public float x, y, z;
    public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
    public static Vector3 up { get { return new Vector3(0, 1, 0); } }
    public static Vector3 zero { get { return new Vector3(0, 0, 0); } }
    public static Vector3 operator +(Vector3 a, Vector3 b) { return new Vector3(a.x + b.x, a.y + b.y, a.z + b.z); }
    public static Vector3 operator -(Vector3 a, Vector3 b) { return new Vector3(a.x - b.x, a.y - b.y, a.z - b.z); }
    public static Vector3 operator *(Vector3 a, float d) { return new Vector3(a.x * d, a.y * d, a.z * d); }
    public static Vector3 operator *(float d, Vector3 a) { return new Vector3(a.x * d, a.y * d, a.z * d); }
    public static Vector3 operator /(Vector3 a, float d) { return new Vector3(a.x / d, a.y / d, a.z / d); }
    public float magnitude { get { return (float)System.Math.Sqrt(x * x + y * y + z * z); } }
  }
  public struct Vector2 {
    public float x, y;
    public Vector2(float x, float y) { this.x = x; this.y = y; }
    public float magnitude { get { return (float)System.Math.Sqrt(x * x + y * y); } }
  }
  public static class Mathf {
    public const float Rad2Deg = 57.29578f;
    public const float Deg2Rad = 0.01745329f;
    public static float Atan2(float y, float x) { return (float)System.Math.Atan2(y, x); }
    public static float Sin(float f) { return (float)System.Math.Sin(f); }
    public static float Cos(float f) { return (float)System.Math.Cos(f); }
    public static float Sqrt(float f) { return (float)System.Math.Sqrt(f); }
    public static float Abs(float f) { return System.Math.Abs(f); }
    public static float Max(float a, float b) { return System.Math.Max(a, b); }
    public static float Min(float a, float b) { return System.Math.Min(a, b); }
  }
}
"""

DUMP_CS = r"""
using System;
using System.Globalization;
using System.Text;
using BlindSpot.EditorTools;
public static class Dump {
  static string F(float v) { return v.ToString("R", CultureInfo.InvariantCulture); }
  static string V(UnityEngine.Vector3 v) { return "[" + F(v.x) + "," + F(v.y) + "," + F(v.z) + "]"; }
  public static void Main() {
    StageLayout L = __STAGE__.Build();
    var sb = new StringBuilder();
    sb.Append("{\"name\":\"" + L.name + "\",\"start\":" + V(L.playerStart) + ",\"blocks\":[");
    for (int i = 0; i < L.blocks.Count; i++) {
      var p = L.blocks[i];
      if (i > 0) sb.Append(",");
      sb.Append("{\"name\":\"" + p.name + "\",\"group\":\"" + p.group + "\",\"pos\":" + V(p.position) +
                ",\"size\":" + V(p.size) + ",\"yaw\":" + F(p.yaw) + ",\"surface\":\"" + p.surface + "\"}");
    }
    sb.Append("],\"monster\":" + V(L.monsterStart) + ",\"patrol\":[");
    for (int i = 0; i < L.patrolPoints.Count; i++) { if (i > 0) sb.Append(","); sb.Append(V(L.patrolPoints[i])); }
    sb.Append("],\"lockers\":[");
    for (int i = 0; i < L.lockers.Count; i++) { if (i > 0) sb.Append(","); var f = L.lockers[i]; sb.Append("{\"name\":\"" + f.name + "\",\"exit\":" + V(f.exit) + "}"); }
    sb.Append("],\"desks\":[");
    for (int i = 0; i < L.desks.Count; i++) { if (i > 0) sb.Append(","); var f = L.desks[i]; sb.Append("{\"name\":\"" + f.name + "\",\"pos\":" + V(f.position) + "}"); }
    sb.Append("],\"items\":[");
    for (int i = 0; i < L.items.Count; i++) { if (i > 0) sb.Append(","); var it = L.items[i]; sb.Append("{\"type\":\"" + it.type + "\",\"pos\":" + V(it.position) + "}"); }
    sb.Append("]}");
    Console.WriteLine(sb.ToString());
  }
}
"""


def surface_enum_stub():
    """レイアウトが使う enum (SurfaceType・ThrowableType) を本物のファイルから抜き出す。"""
    enums = []
    for path, name in ((SURFACE_CS, "SurfaceType"), (THROWABLES_CS, "ThrowableType")):
        src = path.read_text(encoding="utf-8")
        enums.append(re.search(r"public enum " + name + r"\s*\{.*?\}", src, re.S).group(0))
    return "namespace BlindSpot {\n" + "\n".join(enums) + "\n}\n"


def build_layout(stage):
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        (tmp / "UnityStub.cs").write_text(UNITY_STUB, encoding="utf-8")
        (tmp / "SurfaceType.cs").write_text(surface_enum_stub(), encoding="utf-8")
        (tmp / "Dump.cs").write_text(DUMP_CS.replace("__STAGE__", stage), encoding="utf-8")
        sources = [str(p) for p in sorted(STAGE_DIR.glob("*.cs"))] + [str(tmp / n) for n in ("UnityStub.cs", "SurfaceType.cs", "Dump.cs")]
        exe = tmp / "dump.exe"
        r = subprocess.run(["mcs", "-nologo", "-out:" + str(exe)] + sources, capture_output=True, text=True)
        if r.returncode != 0:
            print("コンパイルに失敗しました:\n" + r.stdout + r.stderr)
            sys.exit(2)
        r = subprocess.run(["mono", str(exe)], capture_output=True, text=True, check=True)
        return json.loads(r.stdout)


class Box:
    def __init__(self, b):
        self.name = b["name"]
        self.surface = b["surface"]
        self.cx, self.cy, self.cz = b["pos"]
        self.sx, self.sy, self.sz = b["size"]
        yaw = math.radians(b["yaw"])
        self.cos, self.sin = math.cos(yaw), math.sin(yaw)
        self.bottom = self.cy - self.sy / 2
        self.top = self.cy + self.sy / 2

    def contains_xz(self, x, z, margin=0.0):
        dx, dz = x - self.cx, z - self.cz
        lx = dx * self.cos - dz * self.sin
        lz = dx * self.sin + dz * self.cos
        return abs(lx) <= self.sx / 2 + margin and abs(lz) <= self.sz / 2 + margin


def main(stage):
    layout = build_layout(stage)
    boxes = [Box(b) for b in layout["blocks"]]
    sx, sy, sz = layout["start"]

    # 調べる範囲 (箱全体を囲む四角)
    xs = [b.cx + s * max(b.sx, b.sz) for b in boxes for s in (-1, 1)]
    zs = [b.cz + s * max(b.sx, b.sz) for b in boxes for s in (-1, 1)]
    x0, z0 = min(xs), min(zs)
    nx, nz = int((max(xs) - x0) / CELL) + 1, int((max(zs) - z0) / CELL) + 1

    def center(i, j):
        return x0 + (i + 0.5) * CELL, z0 + (j + 0.5) * CELL

    def ground(x, z):
        """足元の床の高さ (段差で乗れる高さまで)。無ければ None。"""
        tops = [b.top for b in boxes if b.top <= STEP_OFFSET + 0.05 and b.contains_xz(x, z)]
        return max(tops) if tops else None

    def blocked(x, z, g, height):
        lo, hi = g + STEP_OFFSET, g + height
        return any(b.bottom < hi and b.top > lo and b.contains_xz(x, z, RADIUS) for b in boxes)

    floor = {}
    for i in range(nx):
        for j in range(nz):
            x, z = center(i, j)
            g = ground(x, z)
            if g is None:
                continue
            if not blocked(x, z, g, CROUCH_HEIGHT):
                floor[(i, j)] = ("stand" if not blocked(x, z, g, STAND_HEIGHT) else "crouch", g)

    start = (int((sx - x0) / CELL), int((sz - z0) / CELL))
    problems = []
    if start not in floor:
        problems.append(f"スタート地点 ({sx}, {sz}) が壁や物に埋まっているか、床がありません。")
        reached = set()
    else:
        reached = {start}
        q = deque([start])
        while q:
            i, j = q.popleft()
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (i + di, j + dj)
                if n in floor and n not in reached and abs(floor[n][1] - floor[(i, j)][1]) <= STEP_OFFSET:
                    reached.add(n)
                    q.append(n)

    # 素材の床にたどり着けるか
    surfaces = [b for b in boxes if b.surface != "Default"]
    print(f"ステージ: {layout['name']}  (箱 {len(boxes)} 個)")
    print(f"歩ける範囲: {len(reached) * CELL * CELL:.1f} m²")
    for b in surfaces:
        ok = any(b.contains_xz(*center(i, j)) for (i, j) in reached)
        print(f"  {'OK ' if ok else 'NG '} {b.name} ({b.surface}) に{'たどり着ける' if ok else 'たどり着けない'}")
        if not ok:
            problems.append(f"{b.name} にたどり着けません。")

    # 怪物の出発点と巡回ポイント: プレイヤーが立って行ける場所にあるか (怪物はしゃがめない)
    for label, (px, py, pz) in ([("怪物の出発点", layout["monster"])] if layout["patrol"] else []) + \
            [(f"巡回ポイント {k}", p) for k, p in enumerate(layout["patrol"])]:
        c = (int((px - x0) / CELL), int((pz - z0) / CELL))
        ok = c in reached and floor[c][0] == "stand"
        print(f"  {'OK ' if ok else 'NG '} {label} ({px:g}, {pz:g})")
        if not ok:
            problems.append(f"{label} ({px:g}, {pz:g}) が、立って歩ける場所にありません。")
    if layout["patrol"]:
        d = min(math.dist((sx, sz), (p[0], p[2])) for p in layout["patrol"])
        print(f"  プレイヤーの出発点から一番近い巡回ポイントまで: {d:.1f} m")

    # ロッカーの出口・机の下・落ちている物: 行ける場所にあるか
    def cell_of(x, z):
        return (int((x - x0) / CELL), int((z - z0) / CELL))

    for lk in layout["lockers"]:
        ex, _, ez = lk["exit"]
        ok = cell_of(ex, ez) in reached and floor[cell_of(ex, ez)][0] == "stand"
        print(f"  {'OK ' if ok else 'NG '} {lk['name']} の出口 ({ex:.1f}, {ez:.1f})")
        if not ok:
            problems.append(f"{lk['name']} から出た場所が、立って歩ける場所にありません。")
    for dk in layout["desks"]:
        dx, _, dz = dk["pos"]
        c = cell_of(dx, dz)
        ok = c in reached and floor[c][0] == "crouch"
        print(f"  {'OK ' if ok else 'NG '} {dk['name']} の下に、しゃがんで入れる")
        if not ok:
            problems.append(f"{dk['name']} の下に、しゃがんで入れません。")
    for it in layout["items"]:
        ix, _, iz = it["pos"]
        # 物の上には立てないので、まわり 0.5m 以内に行ける場所があれば拾える
        ok = any(cell_of(ix + ox, iz + oz) in reached for ox in (-0.5, 0, 0.5) for oz in (-0.5, 0, 0.5))
        print(f"  {'OK ' if ok else 'NG '} {it['type']} ({ix:g}, {iz:g}) を拾いに行ける")
        if not ok:
            problems.append(f"{it['type']} ({ix:g}, {iz:g}) を拾いに行けません。")

    # 落ちる穴: 歩ける場所のとなりに、床の無いマスがある
    holes = set()
    for (i, j) in reached:
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (i + di, j + dj)
            x, z = center(*n)
            if n not in floor and ground(x, z) is None:
                holes.add(n)
    if holes:
        (i, j) = min(holes)
        x, z = center(i, j)
        problems.append(f"床の無い穴が {len(holes)} マスあります (例: x={x:.1f}, z={z:.1f})。")

    crouch = [c for c in reached if floor[c][0] == "crouch"]
    if crouch:
        cx = sum(center(*c)[0] for c in crouch) / len(crouch)
        cz = sum(center(*c)[1] for c in crouch) / len(crouch)
        print(f"しゃがみが必要な場所: {len(crouch) * CELL * CELL:.1f} m² (中心 x={cx:.1f}, z={cz:.1f} あたり)")
    else:
        print("しゃがみが必要な場所: なし")

    if problems:
        print("\n問題:")
        for p in problems:
            print("  - " + p)
        sys.exit(1)
    print("\n問題は見つかりませんでした。")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "PrototypeStage")
