"""コードだけを載せたページ (右側のソースコード表示用) を作る。

使い方:
    python3 BlindSpot/tools/make_code_page.py <出力.html>

手順・アタッチ先・解説はチャットで伝える。このページにはコードと最低限の情報だけを載せる。
FILES の状態は "新規" / "変更" / "変更なし"。ステップごとに書き換えて使う。
"""
import html
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent  # BlindSpot/

STEP_TITLE = "ステップ1:プレイヤー操作と足音・音の仕組み"

# (Assets からのパス, 状態, 一言の説明)
FILES = [
    ("Assets/BlindSpot/Scripts/Noise/NoiseSystem.cs", "新規", "音を集めて、聞きたい相手に配る放送局"),
    ("Assets/BlindSpot/Scripts/Noise/SurfaceMaterial.cs", "新規", "床の素材の名札 (足音の倍率)"),
    ("Assets/BlindSpot/Scripts/Player/PlayerController.cs", "新規", "歩く・走る・しゃがむ・視点"),
    ("Assets/BlindSpot/Scripts/Player/FootstepNoise.cs", "新規", "歩いた距離ごとに足音を出して、NoiseSystem に知らせる"),
    ("Assets/BlindSpot/Scripts/Debug/DebugHud.cs", "新規", "試作用の状態表示 (F1 で切替)"),
    ("Assets/BlindSpot/Editor/Stage/StageLayout.cs", "新規", "「どこに何を置くか」のデータと、まとめて置くヘルパー"),
    ("Assets/BlindSpot/Editor/Stage/PrototypeStage.cs", "新規", "テスト部屋の座標"),
    ("Assets/BlindSpot/Editor/GrayboxRoomBuilder.cs", "新規", "Tools メニューで、レイアウトからシーンを丸ごと作る"),
]

BADGE = {"新規": "new", "変更": "chg", "変更なし": "same"}

TEMPLATE = (pathlib.Path(__file__).parent / "code_page_template.html").read_text(encoding="utf-8")


def main(out_path):
    files = []
    for rel, status, desc in FILES:
        src = (ROOT / rel).read_text(encoding="utf-8")
        files.append({
            "name": pathlib.PurePosixPath(rel).name,
            "path": rel,
            "status": status,
            "desc": desc,
            "lines": src.count("\n") + (0 if src.endswith("\n") else 1),
            "code": src,
        })
    counts = "".join(
        f'<span class="badge {BADGE[s]}">{s} {n}</span>'
        for s in ("新規", "変更", "変更なし")
        if (n := sum(f["status"] == s for f in files))
    )
    data = json.dumps(files, ensure_ascii=False).replace("</", "<\\/")
    page = (TEMPLATE
            .replace("{{STEP_TITLE}}", html.escape(STEP_TITLE))
            .replace("{{COUNTS}}", counts)
            .replace("{{DATA}}", data))
    pathlib.Path(out_path).write_text(page, encoding="utf-8")
    print(f"wrote {out_path} ({len(files)} files)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "code.html")
