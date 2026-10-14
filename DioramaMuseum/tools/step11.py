"""段階11 (「青い火の火口湖」を青い炎の滝に作り直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 11"
STEP_TITLE = "段階11:「青い火の火口湖」を、青い炎の滝に作り直す"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "作り直し: 黒い崖から流れ落ちる青い炎の滝と、ターコイズの滝つぼ。仕掛けは湖に燃え広がる炎"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "新しい地形 (崖・台地・滝つぼ) に合わせて、歩く地面と立つ場所 (手前の岸) を直した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「青い火の火口湖」の説明文と場所の名前を、滝の作品に合わせた"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "青い炎の音 (ガスが燃える音) と、部屋の照明を青に染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた場所 (火口の縁) に立てるようにした"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "厚みのある溶岩が流れ下って海で広がる・湯気の柱・傘のように広がる噴煙・球の噴石と光の尾。空の所は透明に"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "ジオラマの箱を台座から 2mm 浮かせた (台座が透けて見えるちらつきを直す)"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "鑑賞モードのぼかし (被写界深度) をやめた"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "そのまま",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "クリックでジオラマの世界に入る (歩いているときも鑑賞中も)。入る直前の吸い込みとリセット"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "左ボタンを離した瞬間 (クリックとドラッグを見分ける) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumDome.cs", "そのまま",
     "ドームの形をメッシュで作る道具 (円の床・出入口つきの円い壁・半球の天井・光の柱)"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "そのまま",
     "描く距離を 30m に広げた (ドームから通路の奥の作品が見えるように)"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "「設計図を初期設定に戻して組み立てる」を追加"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "天窓から見える夜空 (モード 5) と、天窓から落ちる光の柱 (モード 6) を追加"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "ドームの格天井 (種類 7) と、真鍮を象眼した方位盤の床 (種類 8) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "漆喰の壁・砂岩・大理石・ドームの床・格天井の5つを追加"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "部屋が回して置かれても、夕日が正しい向きから差すようにした"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "そのまま",
     "重さを調べる道具"),
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
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "貼り直すのは 3 つです",
    "body": [
        "シェーダー `DioramaBlueFire` と、スクリプト `DioramaTerrain`・`MuseumLayout`。シェーダーは段階10で作ったファイルの中身を、全部置き換えてください。",
        "キャプションの説明文も新しくしたい場合は **Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を使ってください (ふつうの「組み立てる」だと、説明文は前のまま残ります)。",
    ],
}

OVERVIEW = ("「青い火の火口湖」を、案 1 の**青い炎の滝**に作り直しました。円形劇場のように滝つぼを囲む黒い玄武岩の崖。"
            "そのてっぺんの切れ込みから、燃える硫黄が青く光る滝になって流れ落ち、白く濁ったターコイズの滝つぼへ。"
            "崖の上の台地には滝へ向かう青い炎の川、崖の割れ目からは小さな青い炎が噴き出し、まわりは黄色い硫黄の結晶。"
            "滝つぼからは湯気が立ちのぼり、湖面には青い滝が映ります。Space で滝が太く明るくなり、"
            "滝つぼから湖の表面へ青い炎が燃え広がって、湖全体が燃えるように光ります。")

FLOW = [
    ("Map (形)", "崖の下の岸と湖の底 (Lowland) と、崖と台地のかたまり (Cliff) を重ねる。崖の面は、柱状節理の縦の筋でごつごつさせる"),
    ("Waterfall (滝)", "崖の落ち口から滝つぼまでの薄い板の中を進み、縦に流れる筋の光を足す。縁はちぎれてしずくになる。上は白っぽく、下ほど深い青"),
    ("LakeFire / LakeFlames (湖の炎)", "仕掛けの最中、滝つぼから円く燃え広がる。湖面そのものの光と、湖面の上でゆらめく炎の舌の 2 つで描く"),
    ("Jets (割れ目の炎)", "崖の面の 5 か所から、小さな青い炎が噴き出す。線と炎の柱の一番近い距離から、ぼんやり光る舌として描く"),
    ("Reflection (映り込み)", "湖面で反射した線が、崖に当たるか、滝の面を通るかを調べて、崖の暗さと滝の青を映す"),
]

SEE = [
    "正面の黒い崖の真ん中から、青く光る滝が流れ落ちている。滝は縦に筋が流れ、縁はしずくになって散る",
    "滝つぼはターコイズで、青い滝が映り、滝の落ちる所は白く泡立つ。湯気が立ちのぼる",
    "崖の上には、滝へ流れ込む青い炎の川。崖の割れ目のあちこちで、小さな青い炎がゆらめく",
    "Space で滝が太く明るくなり、青い炎が滝つぼから湖いっぱいに燃え広がる。部屋の照明が青くなる",
    "クリックで中に入ると、手前の岸に立ち、崖と青い滝を見上げている",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "3 つを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaBlueFire.shader`・`DioramaTerrain.cs`・`MuseumLayout.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、シェーダーを選んだ Inspector にもエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": [
                    "**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。",
                    "キャプションの説明文も新しくしたいときは、代わりに **設計図を初期設定に戻して組み立てる** を選ぶ。",
                ],
                "ok": "火の間の右の台座が、崖と青い滝のジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "外から見る",
                "body": ["E で鑑賞し、正面・斜め・上からなど、いろいろな向きから見る。"],
                "ok": "青い滝・滝つぼの映り込み・割れ目の炎・台地の青い川が見える。",
            },
            {
                "title": "仕掛けを動かす",
                "body": ["Space を押して、15 秒ほど見る。"],
                "ok": "滝が太く明るくなり、湖に青い炎が燃え広がる。おさまると元に戻る。",
            },
            {
                "title": "中に入る",
                "body": ["クリックで中に入り、岸を歩いて滝に近づく。クリックで仕掛けを動かす。"],
                "ok": "手前の岸に立って、崖と滝を見上げている。足が地面に合っている。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["外から (ふだん・仕掛けの最中) と、中から見た滝のスクリーンショット、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "青い炎の滝が、崖の真ん中から流れ落ちている",
    "滝つぼに滝が映り、白く泡立ち、湯気が立つ",
    "Space で滝が太くなり、湖に炎が燃え広がる",
    "中に入ると、手前の岸から滝を見上げられる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project で DioramaBlueFire.shader を選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("崖に穴が空いたように見える・崖の面がちらつく",
     "崖を描く計算の細かさの問題です。スクリーンショットを送ってください。"),
    ("中で、崖の近くで足が埋まる・浮く",
     "崖の面の細かい凹凸は、歩く地面では省いているので、崖のすぐそばでは少しずれます。岸の真ん中でもずれるなら教えてください。"),
]

NEXT = ("スクリーンショットを見て、滝の太さ・明るさ、崖の形を詰めます。火の間が仕上がったら、次の部屋に進みます。")
