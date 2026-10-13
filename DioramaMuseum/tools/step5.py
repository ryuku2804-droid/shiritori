"""段階5 (ドームと 8 部屋の館) のページの中身。make_source_page.py が読み込む。"""

import math

STEP_LABEL = "STEP 5"
STEP_TITLE = "段階5:ドームと 8 つの展示室の館に作り直す"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/MuseumDome.cs", "新規",
     "ドームの形をメッシュで作る道具 (円の床・出入口つきの円い壁・半球の天井・光の柱)"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "変更",
     "描く距離を 30m に広げた (ドームから通路の奥の作品が見えるように)"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "四角いホールをやめ、ドーム・天窓の光・方位盤・壁と天井の照明を作る。部屋は北向きに組んでから回して置く"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "変更",
     "「設計図を初期設定に戻して組み立てる」を追加。部屋の追加を 8 か所のスロットに対応"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "変更",
     "まだ作っていない作品は仮の箱にする。キャプションの2行目を場所の名前に"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "変更",
     "天窓から見える夜空 (モード 5) と、天窓から落ちる光の柱 (モード 6) を追加"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "変更",
     "ドームの格天井 (種類 7) と、真鍮を象眼した方位盤の床 (種類 8) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "変更",
     "漆喰の壁・砂岩・大理石・ドームの床・格天井の5つを追加"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "変更",
     "部屋が回して置かれても、夕日が正しい向きから差すようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "ドームのまわりの 8 か所 (スロット) に部屋を置く設計図に変更。8 部屋・16 作品の初期設定と、場所の名前"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "そのまま",
     "重さを調べる道具"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "F1〜F5 のキーを読めるようにした"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
     "ガラスケースのジオラマ"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "そのまま",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "鑑賞モード"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

ROOMS = [  # (スロット, 名前, 色クラス)
    (0, "月の間", "m-moon"), (1, "ヨーロッパの間", "m-europe"), (2, "火の間", "m-fire"), (3, "砂漠と塩の間", "m-desert"),
    (4, "海の間", "m-sea"), (5, "アンデスの間", "m-andes"), (6, "夕の間", "m-dusk"), (7, "アジアの間", "m-asia"),
]


def museum_map():
    """初期設定の平面図。1単位 = 1m、上が北。部屋は北向きに描いてから、スロットの角度だけ回す"""
    parts = []
    parts.append('<circle class="m-floor" cx="0" cy="0" r="13"/>')
    for slot, name, cls in ROOMS:
        a = slot * 45
        g = [
            '<rect class="m-floor" x="-1.5" y="-18.2" width="3" height="5.4"/>',
            f'<rect class="m-room {cls}" x="-6" y="-28" width="12" height="10"/>',
            '<rect class="m-wall-thin" x="-6" y="-28" width="12" height="10"/>',
            '<circle class="m-pool" cx="-2" cy="-23.5" r="1.6"/><circle class="m-pool" cx="2" cy="-23.5" r="1.6"/>',
            '<rect class="m-ped" x="-2.45" y="-23.95" width="0.9" height="0.9"/><rect class="m-ped" x="1.55" y="-23.95" width="0.9" height="0.9"/>',
        ]
        parts.append(f'<g transform="rotate({a})">' + "".join(g) + "</g>")
        rad = math.radians(a)
        tx, ty = math.sin(rad) * 20.4, -math.cos(rad) * 20.4
        parts.append(f'<text class="m-sub" x="{tx:.2f}" y="{ty:.2f}">{name}</text>')
    parts.append('<circle class="m-wall" cx="0" cy="0" r="13" fill="none"/>')
    for r in (1.25, 5.6, 10.4):
        parts.append(f'<circle class="m-ring" cx="0" cy="0" r="{r}"/>')
    for k in range(8):
        rad = math.radians(k * 45)
        parts.append(f'<line class="m-ring" x1="{math.sin(rad)*1.4:.2f}" y1="{-math.cos(rad)*1.4:.2f}" x2="{math.sin(rad)*10.4:.2f}" y2="{-math.cos(rad)*10.4:.2f}"/>')
    parts.append('<circle class="m-pool" cx="0" cy="0" r="2.2"/>')
    parts.append('<path class="m-you" d="M 0 -1.2 L 0.8 0.5 L -0.8 0.5 Z"/>')
    parts.append('<text class="m-txt" x="0" y="3.4">ドーム</text>')
    parts.append('<text class="m-sub" x="0" y="5">直径 26 m・高さ 17.4 m</text>')
    svg = ('<svg viewBox="-30 -30 60 60" role="img" aria-label="美術館の平面図。中央の円いドームから、8 方向に通路と展示室がのびる">'
           + "".join(parts) + "</svg>")
    return svg + ("<figcaption>平面図 (初期設定、上が北)。中央の円がドーム、細い線が床の方位盤、中心の丸が天窓の光、三角がスタート位置。"
                  "自然の部屋 (月・火・海・夕) と世界の部屋 (ヨーロッパ・砂漠と塩・アンデス・アジア) が交互に並ぶ</figcaption>")


NOTICE = {
    "title": "館を作り直します:設計図を初期設定に戻してから組み立ててください",
    "body": [
        "部屋の置き方が「東西南北の 4 方向」から「ドームのまわりの 8 か所」に変わったので、シーンに保存されている古い設計図のままでは正しく組み上がりません。",
        "ファイルを貼ったら、**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を選んでください。8 部屋・16 作品の新しい設計図で組み上がります。",
        "世界の部屋 (ヨーロッパ・砂漠と塩・アンデス・アジア) の 8 作品は、まだジオラマを作っていないので、台座の上は白い仮の箱です。自然の部屋の 8 作品も、いまは前のジオラマのままです。どちらもこのあと 1 作品ずつ作り込みます。",
    ],
}

OVERVIEW = ("中央に、直径 26m・高さ 17m の半球のドームを置き、そのまわり 45° ごとに 8 つの展示室を放射状に並べます。"
            "ドームの天井にはパンテオンのような**格天井**、てっぺんの**天窓**からは一本の**光の柱**が床の中心に落ち、"
            "床には真鍮を象眼した**方位盤**が 8 つの部屋へ筋をのばします。スタートは光の柱の真下です。"
            "部屋は自然 (月・火・海・夕) と世界 (ヨーロッパ・砂漠と塩・アンデス・アジア) が交互に並び、隣同士の雰囲気がつながるようにしました。")

FLOW = [
    ("MuseumLayout", "8 つのスロット (0 = 北、45° ずつ時計回り) に部屋を置く設計図。作品ごとに場所の名前と、ジオラマの描き方 (-1 はまだない) を持つ"),
    ("MuseumBuilder (ドーム)", "MuseumDome で床・円い壁 (部屋のある向きに出入口)・半球の天井を作る。天窓の夜空と光の柱、真下へのスポットライト、壁と天井の照明、入口の上と床のサインを置く"),
    ("MuseumBuilder (部屋)", "通路と部屋は、まず北向きに組み、親ごとスロットの角度だけ回す。だから部屋の中の作り方 (台座・アート) は前と同じまま使える"),
    ("MuseumSurface", "格天井は天井のメッシュの uv で、くぼみの段を陰影で描く。方位盤は床の中心からの距離と角度で、真鍮の円と 8 方向の筋と八芒星を描く (真鍮は金属として光を映す)"),
    ("MuseumArt", "天窓の夜空 (星が瞬く) と、光の柱 (縁ほど薄く、ほこりの粒が漂う) を描く"),
]

SEE = [
    "スタートすると、ドームの中心で、頭上の天窓から落ちる光の柱の中に立っている",
    "見上げると、半球の天井一面に四角いくぼみ (格天井) が並び、壁の上から当たる光で陰影が浮かぶ。てっぺんの穴から星空が見える",
    "足元は黒い石の床に真鍮の円と 8 方向の筋、中央に八芒星。床の円の外側に 8 つの部屋の名前",
    "まわりの壁に 8 つの入口があり、それぞれの奥から部屋の色の光が漏れている。入口の上に部屋の名前と作品名",
    "自然の 4 部屋は前と同じアート (月・火の粉・障子・水の光) のまま、ドームのまわりの新しい位置にある",
    "世界の 4 部屋は、漆喰の壁と、それぞれの床 (ヨーロッパは大理石、砂漠と塩は砂岩、アジアは木、アンデスは黒い石) で、台座の上は白い仮の箱",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "新しいスクリプトを 1 つ足す",
                "body": ["`Scripts` に **Create > MonoBehaviour Script** で `MuseumDome` を作り、中身を置き換える。"],
                "ok": "Scripts フォルダに MuseumDome がある。",
            },
            {
                "title": "変更のあったファイルを貼り直す",
                "body": [
                    "右のタブで ● の付いたファイルを、上から順にすべて貼り直す (シェーダー 2 つ・スクリプト 6 つ・Editor の MuseumMenu)。",
                    "途中で赤いエラーが出ても、全部貼り終えるまでは気にしなくてよい。",
                ],
                "ok": "全部貼り終えると、Console に赤いエラーがない。",
            },
        ],
    },
    {
        "title": "組み立てる",
        "steps": [
            {
                "title": "設計図を初期設定に戻して組み立てる",
                "body": [
                    "**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を選び、確認で **戻して組み立てる** を押す。",
                    "Generated フォルダに、`Plaster Wall`・`Sandstone`・`Marble`・`Dome Floor`・`Dome Coffer` が増える。",
                ],
                "ok": "Scene ビューで、真ん中の円いドームから 8 方向に部屋がのびた形が見える。Console に「展示室 8 室、台座 16 台」と出る。",
            },
        ],
    },
    {
        "title": "再生して見る",
        "steps": [
            {
                "title": "ドームを見上げる",
                "body": [
                    "再生して、まずその場で真上を見上げる。次にゆっくり一周見回す。",
                    "暗すぎる・明るすぎるときは、`Museum` の **Hall Intensity** (天窓の光)・**Wash Intensity** (壁)・**Dome Up Intensity** (天井) を変える。再生中でもその場で変わる。",
                ],
                "ok": "光の柱、格天井、方位盤、8 つの入口が見える。",
            },
            {
                "title": "部屋を回る",
                "body": ["8 つの部屋に入ってみる。自然の部屋の鑑賞モード (E) も前と同じように使えるか確かめる。"],
                "ok": "8 部屋すべてに入れて、壁をすり抜けない。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["ドームの中心から見上げた 1 枚と、入口のほうを見た 1 枚を送ってください。光と陰影の強さを詰めます。"],
            },
        ],
    },
]

CHECKS = [
    "ドームの床・壁にぶつかると止まる。8 つの入口から通路に入れる",
    "見上げると格天井と天窓の星空が見え、光の柱が床の中心に落ちている",
    "床の方位盤の筋が、8 つの入口の方向を指している",
    "入口の上のサインと、床の部屋の名前が、左右反転せずに読める",
    "斜めの向き (45°) の部屋も、壁や台座がゆがまずに組み上がっている",
    "夕の間の格子の影が、障子のほうから床へ落ちている",
]

TROUBLE = [
    ("部屋が 1 つしかできない・部屋が重なっている",
     "古い設計図のまま組み立てている。**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を選ぶ。"),
    ("ドームの天井や壁が見えない (外が透けて見える)",
     "面の向きが逆になっている可能性。スクリーンショットを送ってください。"),
    ("天井が真っ暗で格天井が見えない",
     "`Museum` の **Dome Up Intensity** を上げる (90 → 200 など)。"),
    ("光の柱が白く強すぎる",
     "Generated ではなく実行時に作るマテリアルなので、今は値を送ってもらえればこちらで調整します。"),
    ("床の方位盤の線がちらつく",
     "遠くの細い線のちらつき。スクリーンショットを送ってください。"),
]

NEXT = ("次は、品質の基準になる 1 作品目「大噴火」を作ります。噴煙・火山雷・溶岩・海・湯気と、"
        "噴火したときに火の間の床のひびと照明が一斉に脈打つ「部屋との連動」まで入れます。")
