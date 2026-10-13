"""コピペ用のソースページ (左: 説明と手順 / 右: コードだけ) を作る。

使い方:
    python3 DioramaMuseum/tools/make_source_page.py <出力先.html>

段階ごとに STEP_* / FILES / PHASES などを書き換えて使う。
"""
import html
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent  # DioramaMuseum/

STEP_LABEL = "STEP 1"
STEP_TITLE = "段階1:館の骨組みを作って、中を歩く"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
# 状態: "新規" = この回で初めて作るファイル / "変更" = 前回から書き換えたファイル / "そのまま" = 前回から変わっていない (貼り直さなくてよい)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "変更",
     "壁・床・天井の質感 (URP 用)。打ち放しコンクリート・木・石・漆喰を、画像なしでノイズから作る"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "館の設計図 (部屋の数・大きさ・向き・作品)。ここを変えると館の形が変わる"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "変更",
     "館で使うマテリアル7種のまとめと、その初期の色"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具。壁に出入口の穴をあける"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "キーとマウスの読み取り。旧 Input Manager と新 Input System の両方に対応"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く・走る・跳ぶ・見回す。壁はすり抜けない"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面中央の照準の点と、起動時の操作説明"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "設計図を読んで館を組み立てる本体。再生時にプレイヤーと画面表示も作る"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "変更",
     "Tools メニューと Inspector のボタン。編集中のシーンに館を組み立てる。必ず Editor フォルダに置く"),
]

NOTICE = {
    "title": "URP 用に作り替えました (ピンク色の修正)",
    "body": [
        "スクリーンショットの `Global Volume` と影の警告から、このプロジェクトは **URP** でした。最初のシェーダーは Built-In 用だったので、URP では必ずピンク色になっていました。",
        "**変更** の付いた4ファイル (`MuseumSurface.shader`・`MuseumMaterials.cs`・`MuseumBuilder.cs`・`MuseumMenu.cs`) を貼り直してください。シェーダーは URP 用に書き直し、ライトの明るさも URP に合わせて上げています。",
        "貼り直したら **Tools > Diorama Museum > 美術館を組み立てる** をもう一度選びます。前に作ったマテリアルはそのまま使われ、新しいシェーダーで描き直されます。",
        "それでもピンク色なら、`MuseumSurface` を選んだときに Inspector に出るエラー文と、Console の赤いメッセージを貼ってください。",
    ],
}

OVERVIEW = ("中央ホールから東西南北に通路がのび、その先に4つの展示室があります。展示室ごとに色と床の素材が違い、"
            "台座の真上からスポットライトが落ちます。段階1では、まず**建物の骨組み**と、**中を歩く仕組み**を作ります。"
            "台座の上は仮の白い箱で、段階2でジオラマに替わります。")


def museum_map():
    """初期設定 (MuseumLayout.CreateDefault) の平面図。1単位 = 1m、上が北 (+z)"""
    parts = []

    def rect(x0, z0, x1, z1, cls):
        # z を上向きにするため、SVG の y は -z
        parts.append(f'<rect class="{cls}" x="{x0}" y="{-z1}" width="{x1 - x0}" height="{z1 - z0}"/>')

    rooms = [  # (名前, 方向ベクトル, 色クラス)
        ("月の間", (0, 1), "m-moon"),
        ("火の間", (1, 0), "m-fire"),
        ("海の間", (0, -1), "m-sea"),
        ("夕の間", (-1, 0), "m-dusk"),
    ]
    rect(-7, -7, 7, 7, "m-floor")
    for name, (fx, fz), cls in rooms:
        # 通路 (幅3、長さ6) と部屋 (幅12、奥行10)
        if fx == 0:
            z0, z1 = (7, 13) if fz > 0 else (-13, -7)
            rect(-1.5, z0, 1.5, z1, "m-floor")
            rz0, rz1 = (13, 23) if fz > 0 else (-23, -13)
            rect(-6, rz0, 6, rz1, f"m-room {cls}")
            cx, cz = 0, (rz0 + rz1) / 2
        else:
            x0, x1 = (7, 13) if fx > 0 else (-13, -7)
            rect(x0, -1.5, x1, 1.5, "m-floor")
            rx0, rx1 = (13, 23) if fx > 0 else (-23, -13)
            rect(rx0, -6, rx1, 6, f"m-room {cls}")
            cx, cz = (rx0 + rx1) / 2, 0
        # 台座2つ (入口から奥行の55%、幅を3等分した位置) と光だまり
        for k in (-2, 2):
            px, pz = (k, fz * 18.5) if fx == 0 else (fx * 18.5, k)
            parts.append(f'<circle class="m-pool" cx="{px}" cy="{-pz}" r="1.8"/>')
            parts.append(f'<rect class="m-ped" x="{px - 0.45}" y="{-pz - 0.45}" width="0.9" height="0.9"/>')
        # 部屋の名前は、台座の光だまりに重ならない位置 (南北の部屋は入口側、東西の部屋は北側) に置く
        ty = (-cz + (3.6 if fz > 0 else -3.6)) if fx == 0 else -4.6
        parts.append(f'<text class="m-txt" x="{cx}" y="{ty}">{name}</text>')

    # 外壁の線 (ホール・通路・部屋をひとつの輪郭で描く)
    outline = ("M -1.5 -7 L -7 -7 L -7 -1.5 L -13 -1.5 L -13 -6 L -23 -6 L -23 6 L -13 6 L -13 1.5 L -7 1.5 L -7 7 "
               "L -1.5 7 L -1.5 13 L -6 13 L -6 23 L 6 23 L 6 13 L 1.5 13 L 1.5 7 L 7 7 L 7 1.5 L 13 1.5 L 13 6 "
               "L 23 6 L 23 -6 L 13 -6 L 13 -1.5 L 7 -1.5 L 7 -7 L 1.5 -7 L 1.5 -13 L 6 -13 L 6 -23 L -6 -23 "
               "L -6 -13 L -1.5 -13 Z")
    # SVG の y は -z なので、輪郭の z を反転して書く
    pts = outline.replace("M ", "").replace(" Z", "").split(" L ")
    flipped = " L ".join(f"{p.split()[0]} {-float(p.split()[1]):g}" for p in pts)
    parts.append(f'<path class="m-wall" d="M {flipped} Z"/>')

    parts.append('<text class="m-txt" x="0" y="-1.2">中央ホール</text>')
    parts.append('<text class="m-sub" x="0" y="0.6">14 × 14 m・天井 7 m</text>')
    # プレイヤーのスタート位置 (ホールの南、北向き)
    parts.append('<path class="m-you" d="M 0 3.9 L 0.8 5.6 L -0.8 5.6 Z"/>')
    parts.append('<text class="m-sub" x="3.2" y="5.2">スタート</text>')
    parts.append('<text class="m-sub" x="22" y="-24.5">N ↑</text>')

    svg = ('<svg viewBox="-25.5 -26 51 52" role="img" aria-label="美術館の平面図。中央ホールから4方向に通路があり、'
           'その先に月の間・火の間・海の間・夕の間がある">' + "".join(parts) + "</svg>")
    return svg + "<figcaption>平面図 (初期設定、上が北)。黒い四角が台座、薄い丸がスポットライトの光だまり、三角がスタート位置。床は 月の間・火の間 が黒い石、夕の間 が木、海の間 が明るい石</figcaption>"


FLOW = [
    ("MuseumLayout", "館の**設計図**。部屋の向き・広さ・色、台座に置く作品の一覧を持つ。Inspector で書き換えられる"),
    ("MuseumBuilder", "設計図を読み、**組み立てる**係。ホール → 通路 → 展示室 → 台座 → ライト の順に作る"),
    ("MuseumGeometry", "Builder に頼まれて、床・壁・天井を **Cube で組む**。出入口の穴もここであける"),
    ("MuseumMaterials", "壁や床に貼る**マテリアル**7種。中身の模様は MuseumSurface シェーダーが描く"),
    ("MuseumMenu (Tools)", "編集中に Builder を呼ぶ**メニュー**。組み立てた建物はシーンに保存され、Scene ビューで見られる"),
    ("FirstPersonController", "再生すると Builder が作る**プレイヤー**。MuseumInput から入力を受け取って歩く"),
    ("MuseumHUD", "再生中の**画面表示**。照準の点と操作説明"),
]

SEE = [
    "暗い中央ホールに立っている。前後左右に、通路の入口が4つある (ピンク色ではない)",
    "通路の奥から、部屋ごとに違う色の光 (青・橙・茜・青緑) が漏れている",
    "壁は、型枠の継ぎ目と丸い穴 (セパ穴) のある打ち放しコンクリート。床は磨いた黒い石",
    "展示室には黒い台座が2つずつあり、上に白い仮の箱が載っている",
    "台座の真上からスポットライトが当たり、床に丸い光だまりができている",
    "画面中央に小さな白い点。画面の下に操作説明が6秒ほど出て消える",
]

PHASES = [
    {
        "title": "準備",
        "steps": [
            {
                "title": "プロジェクトを開く",
                "body": [
                    "既存のジオラマ (`Assets/NightShards/Diorama`) が入っている Unity 6 のプロジェクトを開く。",
                    "このコードは **URP (Universal 3D)** 用。**Edit > Project Settings > Graphics** の一番上 (Default Render Pipeline) に URP のファイルが入っていれば URP。",
                ],
                "ok": "Graphics の Default Render Pipeline に、名前に URP や Universal の入ったファイルが入っている。",
            },
            {
                "title": "入力の設定を確かめる",
                "body": [
                    "**Edit > Project Settings > Player > Other Settings > Active Input Handling** を見る。",
                    "`Input Manager (Old)`・`Input System Package (New)`・`Both` のどれでも動く。New か Both のときは、**Window > Package Manager** で Input System が入っていることも確かめる。",
                ],
                "ok": "どの設定になっているかがわかった (変えなくてよい)。",
            },
        ],
    },
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "フォルダを3つ作る",
                "body": [
                    "Project ウィンドウで `Assets/NightShards` を右クリック > **Create > Folder** で `Museum` を作る。",
                    "その中に `Scripts`、`Shaders`、`Editor` の3つを作る。",
                ],
                "ok": "`Assets/NightShards/Museum` の下に Editor・Scripts・Shaders が並んでいる。",
            },
            {
                "title": "シェーダーを貼る",
                "body": [
                    "`Shaders` を右クリック > **Create > Shader > Unlit Shader** (どの種類でもよい)。名前を `MuseumSurface` にする。",
                    "ダブルクリックで開き、中身を全部消す。右のコード台で `MuseumSurface.shader` を選んで「コピー」→ 貼り付けて保存。",
                ],
                "ok": "シェーダーを選ぶと、Inspector の一番上に `NightShards/MuseumSurface` と出て、赤いエラーがない (SRP Batcher が compatible になっている)。",
            },
            {
                "title": "スクリプトを7つ貼る",
                "body": [
                    "`Scripts` を右クリック > **Create > MonoBehaviour Script**。名前を右のタブと**まったく同じ**にする (例 `MuseumLayout`)。",
                    "開いて中身を全部消し、右のコード台から同じ名前のファイルをコピーして貼り、保存。これを7つくり返す。",
                    "貼る順は右のタブの順 (Layout → Materials → Geometry → Input → FirstPersonController → HUD → Builder)。途中で赤いエラーが出ても、7つ貼り終えるまでは気にしなくてよい。",
                ],
                "ok": "7つ貼り終えて Unity に戻ると、Console に赤いエラーがない。",
            },
            {
                "title": "メニュー用のスクリプトを貼る",
                "body": [
                    "`Editor` フォルダの中に、同じやり方で `MuseumMenu` を作って貼る。",
                    "**Editor という名前のフォルダに置くこと**が大事。ここ以外に置くと、ゲームをビルドするときにエラーになる。",
                ],
                "ok": "画面上のメニューバーに **Tools > Diorama Museum** が増えている。",
            },
        ],
    },
    {
        "title": "Tools で組み立てる",
        "steps": [
            {
                "title": "新しいシーンに組み立てる",
                "body": [
                    "メニューの **Tools > Diorama Museum > 新しいシーンに組み立てる** を選ぶ。今のシーンに保存していない変更があれば、保存するか聞かれる。",
                    "いま開いているシーンに作りたいときは **美術館を組み立てる** を選ぶ。",
                ],
                "ok": "Scene ビューに、十字の形をした館が上から見える。Console に「[Museum] 組み立てました。展示室 4 室、台座 8 台。」と出る。",
            },
            {
                "title": "中身を見てみる",
                "body": [
                    "Hierarchy の `Museum > Museum (Generated)` を開くと、`Hall`、`Wing_月の間` などが並んでいる。",
                    "Scene ビューで館の中にカメラを入れると、暗い館内とスポットライトの光だまりが見える。",
                    "シェーダーを置いたフォルダの隣 (例 `Assets/NightShards/Museum/Generated`) にマテリアルが7つできている。選んで Color A / Color B を変えると、壁や床の色をその場で調整できる。",
                ],
                "ok": "Hierarchy に建物の部品が並び、Generated フォルダにマテリアルが7つある。",
            },
            {
                "title": "シーンを保存する",
                "body": ["**File > Save** で、名前を `Museum` などにして保存する。"],
                "ok": "Project ウィンドウにシーンのファイルができている。",
            },
        ],
    },
    {
        "title": "再生して歩く",
        "steps": [
            {
                "title": "再生する",
                "body": [
                    "Play を押す。最初からマウスで見回せる (見回せないときは Game ビューを1回クリック)。",
                    "下の「動作の確認」を順に試す。",
                ],
                "ok": "暗いホールに立っていて、4つの入口から色の違う光が見える。Console に赤いエラーがない。",
            },
        ],
    },
    {
        "title": "館の形を変えてみる",
        "steps": [
            {
                "title": "作品を1つ増やす",
                "body": [
                    "Hierarchy で `Museum` を選ぶ。Inspector の **Layout > Rooms > 月の間 > Exhibits** の + を押して1つ増やす。",
                    "Inspector の一番上の **組み立て直す** を押す。",
                ],
                "ok": "月の間の台座が3つになり、等間隔に並び直っている。",
            },
            {
                "title": "部屋を足す・消す",
                "body": [
                    "Rooms から1つ消して **組み立て直す** を押すと、その方向の通路と部屋がなくなる。",
                    "そのあと **Tools > Diorama Museum > 展示室を1つ追加する** を選ぶと、空いた方向に新しい部屋ができる。",
                    "間違えたときは **Ctrl+Z** (Mac は Cmd+Z) で元に戻せる。",
                ],
                "ok": "部屋の数が変わり、ホールの出入口の穴も部屋がある面だけにあいている。",
            },
        ],
    },
    {
        "title": "結果を送る",
        "steps": [
            {
                "title": "エラーと見た目を教える",
                "body": [
                    "Console に赤いエラーや黄色の警告が出たら、全文をそのまま貼ってください。",
                    "見た目が気になるとき (暗すぎる、光だまりが弱いなど) は、Game ビューのスクリーンショットか、言葉で様子を教えてください。",
                ],
            },
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
    "Tools で組み立てずに、`MuseumBuilder` だけを付けた空の GameObject で再生しても、同じ館ができる",
]

TROUBLE = [
    ("error CS0234: The type or namespace name 'InputSystem' does not exist in the namespace 'UnityEngine'",
     "Active Input Handling が New か Both なのに、Input System パッケージが入っていない。**Window > Package Manager** で Input System を入れるか、Active Input Handling を `Input Manager (Old)` にする。"),
    ("同じエラーで、Input System は入っている",
     "`Assets/NightShards` やその上に Assembly Definition (.asmdef) があると、参照の追加が必要。その .asmdef の Assembly Definition References に `Unity.InputSystem` を足す。"),
    ("Tools メニューに Diorama Museum が出ない",
     "`MuseumMenu.cs` が Editor フォルダにないか、Console にエラーが残っている。エラーが1つでもあると、メニューは増えない。"),
    ("error CS0246: The type or namespace name 'UnityEditor' could not be found (ビルド時)",
     "`MuseumMenu.cs` が Editor フォルダの外にある。`Assets/NightShards/Museum/Editor` に移す。"),
    ("Reduced additional punctual light shadows resolution by 2 to make 8 shadow maps fit in the 2048x2048 shadow atlas",
     "エラーではなく、影の数が多いという URP のお知らせ。気になるときは、URP のアセット (Settings フォルダの PC_RPAsset など) の Lighting > Additional Lights > Shadow Atlas Resolution を 4096 にするか、`Museum` の Layout > Spot Shadows を外す。"),
    ("光だまりが暗い / 明るすぎる",
     "`Museum` の Inspector の **明るさ** にある Spot Intensity などを変えて、**組み立て直す** を押す。"),
    ("[Museum] シェーダー NightShards/MuseumSurface が見つかりません",
     "シェーダーの1行目が `Shader \"NightShards/MuseumSurface\"` になっているか確認する。貼る前の中身が残っていないかも見る。"),
    ("床や壁がピンク色",
     "シェーダーを選んで Inspector のエラー文を見る。Console に「URP ではなく」と出ていれば、プロジェクトが URP ではない。どちらも、その文を貼ってください。"),
    ("操作説明の文字が □ になる",
     "OS に日本語フォントが見つからないとき。お使いの OS を教えてください。フォントを指定する形に直します。"),
    ("暗すぎて何も見えない / 明るすぎる",
     "`Museum` の Inspector の `Ambient` (環境光) と `Fog Density` (霧の濃さ) で調整して、組み立て直す。気に入った値を教えてもらえれば初期値にします。"),
    ("The class named 'MuseumBuilder' is not derived from MonoBehaviour / スクリプトを付けられない",
     "ファイル名とクラス名が一致していない。ファイル名は `MuseumBuilder.cs` にする。"),
]

NEXT = ("段階2では、仮の白い箱を本物のジオラマ (`DioramaPiece` と `Diorama.shader`) に差し替え、台座の手前に作品名と説明のプレートを付けます。"
        "そのために、既存の `Assets/NightShards/Diorama` の6ファイルの中身を貼るか、リポジトリに push してください。")

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
    payload = {"notice": NOTICE, "files": files, "overview": OVERVIEW, "map": museum_map(), "flow": FLOW, "see": SEE,
               "phases": PHASES, "checks": CHECKS, "trouble": TROUBLE, "next": NEXT}
    data = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    page = (TEMPLATE
            .replace("{{STEP_LABEL}}", html.escape(STEP_LABEL))
            .replace("{{STEP_TITLE}}", html.escape(STEP_TITLE))
            .replace("{{DATA}}", data))
    pathlib.Path(out_path).write_text(page, encoding="utf-8")
    print(f"wrote {out_path} ({len(files)} files)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "source.html")
