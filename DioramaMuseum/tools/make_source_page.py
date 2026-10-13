"""コピペ用のソースページ (左: 手順 / 右: コードだけ) を作る。

使い方:
    python3 DioramaMuseum/tools/make_source_page.py <出力先.html>

段階ごとに STEP_* と FILES を書き換えて使う。
"""
import html
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent  # DioramaMuseum/

STEP_LABEL = "STEP 1"
STEP_TITLE = "段階1:館の骨組みと一人称の歩き"

# (Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "新規",
     "シーンに置くのはこれだけ。再生すると、ホール・通路・展示室・照明・プレイヤー・画面表示を組み立てる"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "新規",
     "部屋と展示の設定。Inspector でこれを変えると、部屋の数や台座の並びが自動で変わる"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "新規",
     "床・壁・天井を Cube で組む道具。出入口の穴あけもここ"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "新規",
     "キーとマウスの読み取り。旧 Input Manager と新 Input System の両方に対応"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "新規",
     "CharacterController で歩く・走る・跳ぶ・見回す"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "新規",
     "照準の点と、起動時の操作説明"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "新規",
     "打ち放しコンクリート・木の床・石・漆喰の質感を、画像なしでノイズから作る"),
]

SEE = [
    "暗い中央ホールに立っている。正面と左右と背後に、通路の入口が4つある",
    "通路の奥から、部屋ごとに違う色の光 (青・橙・茜・青緑) が漏れている",
    "壁は型枠の継ぎ目と丸いセパ穴のある打ち放しコンクリート。床は磨いた黒い石",
    "各展示室には黒い台座が2つあり、上に白い仮の箱 (段階2でジオラマに替わる) が載っている",
    "台座の真上からスポットライトが当たり、床に丸い光だまりができている",
    "画面中央に小さな白い点、画面下に操作説明が6秒ほど出て消える",
]

STEPS = [
    {
        "title": "シーンを用意する",
        "body": [
            "Unity 6 の 3D (Built-In Render Pipeline) プロジェクトを開き、**File > New Scene > Basic (Built-in)** で新しいシーンを作って保存する。",
            "もとからある Main Camera と Directional Light は消さなくてよい (再生時に自動で止める)。",
        ],
        "ok": "Hierarchy に Main Camera と Directional Light だけがある。",
    },
    {
        "title": "フォルダを作る",
        "body": [
            "Project ウィンドウで `Assets/NightShards/Museum/Scripts` と `Assets/NightShards/Museum/Shaders` を作る。",
            "既存の `Assets/NightShards/Diorama` には触らない。",
        ],
        "ok": "Museum の下に Scripts と Shaders の2つのフォルダがある。",
    },
    {
        "title": "スクリプトを6つ作って貼る",
        "body": [
            "Scripts フォルダで右クリック > **Create > MonoBehaviour Script**。名前は右のタブと同じにする (例 `MuseumBuilder`)。",
            "作ったファイルを開いて中身を全部消し、右のコード台で同じ名前のファイルを選んで「コピー」→ 貼り付けて保存。",
            "`MuseumLayout` `MuseumGeometry` `MuseumInput` は MonoBehaviour ではないが、同じ作り方で中身を置き換えればよい。",
        ],
        "ok": "6つ貼り終えて Unity に戻ると、Console に赤いエラーが出ていない。",
    },
    {
        "title": "シェーダーを作って貼る",
        "body": [
            "Shaders フォルダで右クリック > **Create > Shader > Standard Surface Shader**、名前を `MuseumSurface` にする。",
            "中身を全部消して、右の `MuseumSurface.shader` を貼って保存。",
        ],
        "ok": "シェーダーを選ぶと、Inspector の名前が `NightShards/MuseumSurface` になっていて、エラー表示がない。",
    },
    {
        "title": "MuseumBuilder を置く",
        "body": [
            "Hierarchy で右クリック > **Create Empty**、名前を `Museum` にして、Position を (0, 0, 0) にする。",
            "Inspector の **Add Component** で `MuseumBuilder` を付ける。",
            "`Surface Shader` の欄に、Project の `MuseumSurface` をドラッグして入れる (空でも動くが、あとでビルドするときに必要)。",
        ],
        "ok": "Inspector に Layout が出ていて、Rooms を開くと 月の間・火の間・夕の間・海の間 の4つが並んでいる。",
    },
    {
        "title": "再生する",
        "body": [
            "Play を押す。画面をクリックするとマウスで見回せる。",
            "下の「動作の確認」を順に試す。",
        ],
        "ok": "暗いホールに立っていて、4つの入口から色の違う光が見える。Console に赤いエラーがない。",
    },
    {
        "title": "結果を送る",
        "body": [
            "Console に赤いエラーや黄色の警告が出たら、全文をそのまま貼ってください。",
            "見た目が気になるとき (暗すぎる、光だまりが弱いなど) は、Game ビューのスクリーンショットか、言葉で様子を教えてください。",
        ],
    },
]

CHECKS = [
    "WASD で歩ける。Shift を押しながら前に進むと速くなる",
    "Space でジャンプできる。天井に頭をぶつけても止まらない",
    "壁・通路の壁・台座にぶつかると止まり、すり抜けない",
    "4つの通路を通って、4つの展示室すべてに入れる",
    "Esc でカーソルが出る。画面をクリックすると、また見回せるようになる",
    "H を押すと操作説明がもう一度出る",
    "Inspector の Layout > Rooms で、ある部屋の Exhibits を1つ増やして再生し直すと、台座が3つに並び直る",
]

TROUBLE = [
    ("error CS0234: The type or namespace name 'InputSystem' does not exist in the namespace 'UnityEngine'",
     "Active Input Handling が New か Both なのに、Input System パッケージが入っていない。**Window > Package Manager** で Input System を入れるか、**Project Settings > Player > Active Input Handling** を `Input Manager (Old)` にする。"),
    ("同じエラーで、Input System は入っている",
     "`Assets/NightShards` の上のどこかに Assembly Definition (.asmdef) があると、参照の追加が必要。その .asmdef の Assembly Definition References に `Unity.InputSystem` を足す。"),
    ("[Museum] シェーダー NightShards/MuseumSurface が見つかりません",
     "シェーダーの1行目が `Shader \"NightShards/MuseumSurface\"` になっているか確認する。貼り付け前の中身が残っていないかも見る。"),
    ("床や壁がピンク色",
     "シェーダーにエラーがある。シェーダーを選ぶと Inspector にエラー文が出るので、それを貼ってください。"),
    ("操作説明の文字が □ になる",
     "OS に日本語フォントが見つからないとき。お使いの OS を教えてください。フォントを指定する形に直します。"),
    ("暗すぎて何も見えない / 明るすぎる",
     "MuseumBuilder の `Ambient` (環境光) と `Fog Density` (霧の濃さ) で調整できる。気に入った値を教えてもらえれば初期値にします。"),
    ("The class named 'MuseumBuilder' is not derived from MonoBehaviour / スクリプトを付けられない",
     "ファイル名とクラス名が一致していない。ファイル名は `MuseumBuilder.cs` にする。"),
]

NEXT = "段階2では、仮の箱を本物のジオラマ (`DioramaPiece` と `Diorama.shader`) に差し替え、台座の手前に作品名と説明のプレートを付けます。そのために、既存の `Assets/NightShards/Diorama` の6ファイルの中身が必要です。"

TEMPLATE = (pathlib.Path(__file__).parent / "source_page_template.html").read_text(encoding="utf-8")


def main(out_path):
    files = []
    for rel, status, desc in FILES:
        src = (ROOT / rel).read_text(encoding="utf-8")
        p = pathlib.PurePosixPath(rel)
        files.append({
            "name": p.name,
            "folder": str(p.parent) + "/",
            "status": status,
            "desc": desc,
            "lines": src.count("\n") + (0 if src.endswith("\n") else 1),
            "code": src,
        })
    payload = {"files": files, "see": SEE, "steps": STEPS, "checks": CHECKS,
               "trouble": TROUBLE, "next": NEXT}
    data = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    page = (TEMPLATE
            .replace("{{STEP_LABEL}}", html.escape(STEP_LABEL))
            .replace("{{STEP_TITLE}}", html.escape(STEP_TITLE))
            .replace("{{DATA}}", data))
    pathlib.Path(out_path).write_text(page, encoding="utf-8")
    print(f"wrote {out_path} ({len(files)} files)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "source.html")
