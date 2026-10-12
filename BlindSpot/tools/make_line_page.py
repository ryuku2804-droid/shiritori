"""コードを1行ずつ解説するページを作る。

使い方:
    python3 BlindSpot/tools/make_line_page.py <出力.html>

解説は tools/annotations/<クラス名>.py の NOTES = {行番号: "説明"} に書く。
中かっこ・コメント・using・namespace・[Header]・[Tooltip] の行は自動で説明を付ける。
説明の無いコード行や、空行・かっこの行を指している説明があればエラーにする (コードを変えたら必ず作り直す)。
"""
import html
import importlib.util
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent  # BlindSpot/
NOTES_DIR = pathlib.Path(__file__).parent / "annotations"

# 読む順 (仕組みの土台 → プレイヤー → 怪物 → ステージを作る道具)
FILES = [
    ("Assets/BlindSpot/Scripts/Noise/NoiseSystem.cs", "音を集めて、聞きたい相手に配る放送局"),
    ("Assets/BlindSpot/Scripts/Noise/SurfaceMaterial.cs", "床の素材の名札"),
    ("Assets/BlindSpot/Scripts/Player/PlayerController.cs", "歩く・走る・しゃがむ・視点"),
    ("Assets/BlindSpot/Scripts/Player/FootstepNoise.cs", "歩いた距離ごとに足音を出す"),
    ("Assets/BlindSpot/Scripts/Player/BreathHold.cs", "呼吸の音と息止め・心拍"),
    ("Assets/BlindSpot/Scripts/Interaction/IInteractable.cs", "「調べられるもの」の約束ごと"),
    ("Assets/BlindSpot/Scripts/Interaction/PlayerInteractor.cs", "視線の先を調べる (E キー)"),
    ("Assets/BlindSpot/Scripts/Interaction/HidingSpot.cs", "ロッカーに隠れる"),
    ("Assets/BlindSpot/Scripts/Interaction/HideZone.cs", "机の下にしゃがんで隠れる"),
    ("Assets/BlindSpot/Scripts/Throwing/Throwables.cs", "投擲物の種類と性質"),
    ("Assets/BlindSpot/Scripts/Throwing/ItemPickup.cs", "床に落ちている物を拾う"),
    ("Assets/BlindSpot/Scripts/Throwing/PlayerThrower.cs", "持っている物を投げる"),
    ("Assets/BlindSpot/Scripts/Throwing/ThrownObject.cs", "投げた物がぶつかって音を出す"),
    ("Assets/BlindSpot/Scripts/Debug/DebugHud.cs", "試作用の画面表示"),
    ("Assets/BlindSpot/Scripts/Monster/RuntimeNavMesh.cs", "怪物が歩ける範囲を作る"),
    ("Assets/BlindSpot/Scripts/Monster/MonsterAI.cs", "音だけを頼りに動く怪物の頭脳"),
    ("Assets/BlindSpot/Scripts/Monster/MonsterClicker.cs", "怪物のクリック音"),
    ("Assets/BlindSpot/Editor/Stage/StageLayout.cs", "「どこに何を置くか」のデータ"),
    ("Assets/BlindSpot/Editor/Stage/PrototypeStage.cs", "テスト部屋の設計図"),
    ("Assets/BlindSpot/Editor/GrayboxRoomBuilder.cs", "レイアウトからシーンを丸ごと作る道具"),
]

USING = {
    "System": "C# の基本機能 (Action など)",
    "System.Collections.Generic": "List (リスト) や Dictionary (表) などの入れ物",
    "UnityEngine": "Unity の基本機能 (GameObject・Vector3・MonoBehaviour など)",
    "UnityEngine.InputSystem": "新しい Input System (キーボード・マウス・ゲームパッドの入力)",
    "UnityEngine.AI": "NavMesh (AI が歩ける範囲) と NavMeshAgent",
    "UnityEngine.SceneManagement": "シーンの読み込みや切り替え",
    "UnityEditor": "Unity エディタ専用の機能 (メニュー・アセットの保存など)",
    "UnityEditor.SceneManagement": "エディタでのシーンの作成・保存",
}


def auto_note(line):
    s = line.strip()
    if s in ("{",):
        return "かっこの始まり。上の行の中身がここから始まる。"
    if s in ("}", "};", "});"):
        return "かっこの終わり。ここで中身が終わる。"
    m = re.fullmatch(r"using ([\w.]+);", s)
    if m:
        what = USING.get(m.group(1), m.group(1))
        return f"{what}を、このファイルで使えるようにする。"
    m = re.fullmatch(r"namespace ([\w.]+)", s)
    if m:
        return f"ここから下を `{m.group(1)}` という名前の箱 (名前空間) に入れる。ほかのアセットと名前がぶつからないようにするため。"
    if s.startswith("/// <summary>") or s == "/// </summary>":
        return "説明文 (ドキュメントコメント) の始まりと終わりの印。実行はされない。"
    if s.startswith("/// <param"):
        return "引数の説明 (ドキュメントコメント)。実行はされない。"
    if s.startswith("///"):
        return "すぐ下のクラスや関数の説明文 (ドキュメントコメント)。エディタでマウスを乗せると表示される。実行はされない。"
    if s.startswith("//"):
        return "コメント (人のためのメモ)。実行はされない。"
    m = re.fullmatch(r'\[Header\("(.*)"\)\]', s)
    if m:
        return f"Inspector に「{m.group(1)}」という見出しを表示する。"
    m = re.fullmatch(r'\[Tooltip\("(.*)"\)\]', s)
    if m:
        return "Inspector で、すぐ下の項目にマウスを乗せたときの説明。"
    return None


def load_notes(name):
    path = NOTES_DIR / f"{name}.py"
    if not path.exists():
        return {}
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.NOTES


def main(out_path):
    files, problems = [], []
    for rel, role in FILES:
        name = pathlib.PurePosixPath(rel).stem
        lines = (ROOT / rel).read_text(encoding="utf-8").split("\n")
        if lines and lines[-1] == "":
            lines.pop()
        notes = load_notes(name)
        rows = []
        for no, text in enumerate(lines, start=1):
            if not text.strip():
                if no in notes:
                    problems.append(f"{name}:{no} は空行なのに説明がある")
                continue
            auto = auto_note(text)
            if no in notes:
                if auto and text.strip() in ("{", "}", "};", "});"):
                    problems.append(f"{name}:{no} はかっこの行なのに説明がある (行番号ずれ?)")
                rows.append([no, text, notes[no], 0])
            elif auto:
                rows.append([no, text, auto, 1])
            else:
                problems.append(f"{name}:{no} に説明が無い: {text.strip()}")
        files.append({"name": name + ".cs", "path": rel, "role": role, "rows": rows})
    if problems:
        print("\n".join(problems))
        sys.exit(1)

    template = (pathlib.Path(__file__).parent / "line_page_template.html").read_text(encoding="utf-8")
    data = json.dumps(files, ensure_ascii=False).replace("</", "<\\/")
    pathlib.Path(out_path).write_text(template.replace("{{DATA}}", data), encoding="utf-8")
    total = sum(len(f["rows"]) for f in files)
    manual = sum(1 for f in files for r in f["rows"] if not r[3])
    print(f"wrote {out_path} ({len(files)} files, {total} lines, 手書きの説明 {manual})")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "lines.html")
