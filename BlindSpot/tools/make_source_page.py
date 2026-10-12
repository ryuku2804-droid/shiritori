"""ソースコード一覧ページ (コピペ用 HTML) を作る。

使い方:
    python3 BlindSpot/tools/make_source_page.py <出力先.html>

FILES の status は "新規" か "変更"。ステップごとに書き換えて使う。
"""
import html
import json
import pathlib
import sys

import lessons_step1 as lessons

ROOT = pathlib.Path(__file__).resolve().parent.parent  # BlindSpot/

STEP_TITLE = "ステップ1:プレイヤー操作と足音・音の仕組み(Tools メニュー版)"

# (Assets からのパス, 状態, 説明)  状態は "新規" / "変更" / "変更なし"
FILES = [
    ("Assets/BlindSpot/Scripts/Noise/NoiseSystem.cs", "変更なし", "音を発生させて配る仕組み (静的クラス)。怪物 AI はここから音を受け取る"),
    ("Assets/BlindSpot/Scripts/Noise/SurfaceMaterial.cs", "変更なし", "床に付けて素材を指定する。足音の倍率と専用の効果音"),
    ("Assets/BlindSpot/Scripts/Player/PlayerController.cs", "変更なし", "一人称操作。歩く・走る (前進のみ)・しゃがむ・視点"),
    ("Assets/BlindSpot/Scripts/Player/FootstepNoise.cs", "変更なし", "歩いた距離ごとに足音を鳴らし、NoiseSystem に知らせる"),
    ("Assets/BlindSpot/Scripts/Debug/DebugHud.cs", "変更なし", "試作用。画面左上に状態と足音の距離を表示 (F1 で切替)"),
    ("Assets/BlindSpot/Editor/Stage/StageLayout.cs", "新規", "「どこに何を置くか」のデータと、部屋・壁・床をまとめて置くヘルパー"),
    ("Assets/BlindSpot/Editor/Stage/PrototypeStage.cs", "新規", "テスト部屋の座標。配置を変えるときはここを書き換えてメニューを押し直す"),
    ("Assets/BlindSpot/Editor/GrayboxRoomBuilder.cs", "変更", "Tools メニューから、レイアウトを読んで新しいシーンを丸ごと組み立てて保存する。必ず Editor フォルダに置く"),
]

TEMPLATE = (pathlib.Path(__file__).parent / "source_page_template.html").read_text(encoding="utf-8")


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
            "guide": lessons.FILE_LESSONS.get(pathlib.PurePosixPath(rel).name),
        })
    payload = {
        "files": files,
        "guide": lessons.GUIDE,
        "tips": lessons.STUDY_TIPS,
        "basics": lessons.BASICS,
        "flow": lessons.FLOW,
        "explain": lessons.EXPLAIN,
        "hierarchy": lessons.HIERARCHY,
        "manual": lessons.MANUAL_STEPS,
        "attach": lessons.ATTACH,
        "expected": lessons.EXPECTED,
        "trouble": lessons.TROUBLE,
    }
    data = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    page = (TEMPLATE
            .replace("{{STEP_TITLE}}", html.escape(STEP_TITLE))
            .replace("{{NEW_COUNT}}", str(sum(f["status"] == "新規" for f in files)))
            .replace("{{CHANGED_COUNT}}", str(sum(f["status"] == "変更" for f in files)))
            .replace("{{SAME_COUNT}}", str(sum(f["status"] == "変更なし" for f in files)))
            .replace("{{DATA}}", data))
    pathlib.Path(out_path).write_text(page, encoding="utf-8")
    print(f"wrote {out_path} ({len(files)} files)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "source.html")
