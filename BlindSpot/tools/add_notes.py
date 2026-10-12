"""説明を足す (同じ行番号があれば上書き)。

使い方:
    python3 BlindSpot/tools/add_notes.py <クラス名> <<'END'
    {12: "説明", 13: "説明"}
    END
"""
import ast
import pathlib
import pprint
import sys

NOTES_DIR = pathlib.Path(__file__).parent / "annotations"


def main(name):
    path = NOTES_DIR / f"{name}.py"
    notes = {}
    if path.exists():
        ns = {}
        exec(path.read_text(encoding="utf-8"), ns)
        notes = ns["NOTES"]
    notes.update(ast.literal_eval(sys.stdin.read()))
    body = "NOTES = " + pprint.pformat(dict(sorted(notes.items())), width=200, sort_dicts=False) + "\n"
    path.write_text(body, encoding="utf-8")
    print(f"{name}: {len(notes)} 件")


if __name__ == "__main__":
    main(sys.argv[1])
