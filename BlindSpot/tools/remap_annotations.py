"""コードを変えたあと、変わっていない行の説明を新しい行番号に移す。

使い方:
    python3 BlindSpot/tools/remap_annotations.py <クラス名> <古いコードのファイル>

古いコードは git から取り出して渡す (例: git show HEAD:BlindSpot/Assets/.../X.cs > /tmp/X.cs)。
移せなかった説明 (変わった行・消えた行の説明) は表示するだけで、捨てる。
"""
import difflib
import pathlib
import pprint
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
NOTES_DIR = pathlib.Path(__file__).parent / "annotations"


def main(name, old_path):
    new_path = next(ROOT.glob(f"Assets/**/{name}.cs"))
    old = pathlib.Path(old_path).read_text(encoding="utf-8").split("\n")
    new = new_path.read_text(encoding="utf-8").split("\n")
    ns = {}
    exec((NOTES_DIR / f"{name}.py").read_text(encoding="utf-8"), ns)
    notes = ns["NOTES"]

    mapping = {}
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(a=old, b=new, autojunk=False).get_opcodes():
        if tag == "equal":
            for k in range(i2 - i1):
                mapping[i1 + k + 1] = j1 + k + 1
    moved = {mapping[k]: v for k, v in notes.items() if k in mapping}
    dropped = {k: v for k, v in notes.items() if k not in mapping}
    for k, v in sorted(dropped.items()):
        print(f"  消えた説明 (古い {k} 行目): {v}")
    body = "NOTES = " + pprint.pformat(dict(sorted(moved.items())), width=200, sort_dicts=False) + "\n"
    (NOTES_DIR / f"{name}.py").write_text(body, encoding="utf-8")
    print(f"{name}: {len(moved)} 件を移した / {len(dropped)} 件を捨てた")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
