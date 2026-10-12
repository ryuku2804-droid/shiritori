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

STEP_TITLE = "ステップ3:隠れる・投擲・息止め"

# (Assets からのパス, 状態, 一言の説明)
FILES = [
    ("Assets/BlindSpot/Scripts/Player/BreathHold.cs", "新規", "呼吸の音と息止め。ゲージの減る速さは心拍 (怪物との距離) で変わる"),
    ("Assets/BlindSpot/Scripts/Interaction/IInteractable.cs", "新規", "「E で調べられるもの」の約束ごと"),
    ("Assets/BlindSpot/Scripts/Interaction/PlayerInteractor.cs", "新規", "視線の先を調べる (E キー)"),
    ("Assets/BlindSpot/Scripts/Interaction/HidingSpot.cs", "新規", "ロッカーに隠れる・出る"),
    ("Assets/BlindSpot/Scripts/Interaction/HideZone.cs", "新規", "机の下でしゃがむと隠れられる範囲"),
    ("Assets/BlindSpot/Scripts/Throwing/Throwables.cs", "新規", "投擲物の種類 (石・瓶・缶) と性質"),
    ("Assets/BlindSpot/Scripts/Throwing/ItemPickup.cs", "新規", "床に落ちている物を拾う"),
    ("Assets/BlindSpot/Scripts/Throwing/PlayerThrower.cs", "新規", "持っている物を選んで投げる"),
    ("Assets/BlindSpot/Scripts/Throwing/ThrownObject.cs", "新規", "投げた物がぶつかって音を出し、止まったらまた拾える"),
    ("Assets/BlindSpot/Scripts/Player/PlayerController.cs", "変更", "体の固定 (ロッカー用)・隠れている状態・瞬間移動を追加"),
    ("Assets/BlindSpot/Scripts/Player/FootstepNoise.cs", "変更", "瞬間移動を足音として数えないようにした"),
    ("Assets/BlindSpot/Scripts/Noise/NoiseSystem.cs", "変更", "音の種類に「呼吸」を追加"),
    ("Assets/BlindSpot/Scripts/Monster/MonsterAI.cs", "変更", "「気配」をやめて呼吸の音で見つけるように。隠れている相手は捕まえない"),
    ("Assets/BlindSpot/Scripts/Debug/DebugHud.cs", "変更", "照準・調べる説明・息止めゲージ・持ち物を表示"),
    ("Assets/BlindSpot/Editor/Stage/StageLayout.cs", "変更", "ロッカー・机・落ちている物を書けるようにした"),
    ("Assets/BlindSpot/Editor/Stage/PrototypeStage.cs", "変更", "テスト部屋にロッカー2つ・机1つ・投擲物7個を追加"),
    ("Assets/BlindSpot/Editor/GrayboxRoomBuilder.cs", "変更", "家具の組み立て・物の配置・プレイヤーの新しい部品を追加"),
    ("Assets/BlindSpot/Scripts/Noise/SurfaceMaterial.cs", "変更なし", "床の素材の名札"),
    ("Assets/BlindSpot/Scripts/Monster/MonsterClicker.cs", "変更なし", "怪物のクリック音"),
    ("Assets/BlindSpot/Scripts/Monster/RuntimeNavMesh.cs", "変更なし", "怪物が歩ける範囲を作る"),
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
