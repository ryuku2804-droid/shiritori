"""段階10 (2 作品目「青い火の火口湖」) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 10"
STEP_TITLE = "段階10:2 作品目「青い火の火口湖」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "新規",
     "作品「青い火の火口湖」。火口の湖・青い炎・硫黄の煙・ヘッドランプの灯り・天の川。仕掛けは燃える硫黄の川"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "青い炎の音 (ガスが燃える音) と、部屋の照明を青に染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "「青い火の火口湖」の地形の高さを足した (シェーダーと同じ式)。立つ場所を作品ごとに決められるようにした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "作品が決めた場所 (火口の縁) に立てるようにした"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "変更",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「青い火の火口湖」を作品専用シェーダー BlueFire で描くようにした"),
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
    "title": "シェーダーを 1 つ新しく作ります",
    "body": [
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を選び、名前を `DioramaBlueFire` にして、中身を全部置き換えてください (大噴火のときと同じ作り方です)。",
        "スクリプトは 5 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直すと、火の間の右の台座が仮のジオラマから新しい作品に変わります。",
    ],
}

OVERVIEW = ("火の間の 2 作品目です。モデルはインドネシアのイジェン火山。夜の火口の底に、乳白色のターコイズの酸の湖が広がり、"
            "奥の壁の噴気孔では、硫黄のガスが燃える**青い炎**がゆらめいています。まわりには黄色い硫黄の結晶、立ちのぼる硫黄の煙、"
            "火口の壁のつづら折りの道をゆっくり下りていくヘッドランプの灯り、空には天の川。"
            "Space で**ガスに火が回り**、青い炎が高く燃え上がって、燃える硫黄が青い川になって壁を流れ下り、湖の上に広がります。"
            "そのあいだ、火の間の照明と床の光が青に染まります。クリックで中に入ると、火口の縁に立って湖を見下ろせます。")

FLOW = [
    ("Height (地形)", "中心に湖の底、半径 0.3 に火口の縁、その外はなだらかな山すそ。縁の一か所が低くえぐれていて、そこから道が下りる。同じ式を C# にも書き写して、中で歩く地面にする"),
    ("Flames (青い炎)", "5 つの噴気孔の上に、細く揺れる炎を立体として描く。炎は自分で光るので、色を足していくだけ。火が回ると高さが 4 倍以上になる"),
    ("RiverAt (燃える川)", "噴気孔から湖のほうへ、青く光る筋を描く。火が回ると先端が 4 秒ほどかけて湖まで進み、湖の上で扇のように広がる"),
    ("Fumes (煙ともや)", "噴気孔の上から立ちのぼって風下へたなびく硫黄の煙と、湖の上をはううすいもや。下から青い炎に照らされる。火がつく瞬間、煙の中のガスが青く光る"),
    ("RoomReactor (部屋)", "作品の色 (DioramaWork.Tint) に向けて、部屋のライトの色と床の光の色を寄せる。大噴火は色を変えない (赤いまま)"),
]

SEE = [
    "火の間の右の台座に、夜の火口湖のジオラマ。奥の壁の下のほうで、青い炎がいくつもゆらめいている",
    "湖は白く濁ったターコイズ。青い炎が水面に映り、岸には黄白い泡",
    "噴気孔のまわりが黄色い (硫黄)。そこから煙が立ちのぼって、右へたなびく",
    "火口の右奥の壁を、小さな灯りがジグザグにゆっくり下りていく",
    "Space で炎が高く燃え上がり、青い川が湖へ流れ下る。部屋の照明が青くなり、ゴーッという炎の音",
    "クリックで中に入ると、火口の縁に立って、湖と青い炎を見下ろしている",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "新しいシェーダーを作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaBlueFire` にする。",
                    "開いて中身を全部消し、右のタブの `DioramaBlueFire.shader` を貼る。",
                ],
                "ok": "Project でこのシェーダーを選んだとき、Inspector にエラーが出ていない。",
            },
            {
                "title": "変更のあった 5 つを貼り直す",
                "body": ["右のタブで ● の付いたスクリプトを、上から順に貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "火の間の右の台座が、火口湖のジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "外から見る",
                "body": ["火の間で「青い火の火口湖」に近づき、E で鑑賞する。ドラッグでいろいろな向きから見る。"],
                "ok": "青い炎・ターコイズの湖・黄色い硫黄・煙・ヘッドランプの灯りが見える。",
            },
            {
                "title": "火を回す",
                "body": ["Space を押して、15 秒ほど見る。"],
                "ok": "炎が高くなり、青い川が湖まで流れて広がる。部屋の照明が青くなり、おさまると元の色に戻る。",
            },
            {
                "title": "中に入る",
                "body": ["クリックで中に入る。火口の縁を歩き、クリックで火を回す。E か Esc で戻る。"],
                "ok": "火口の縁に立っていて、足が地面に合っている。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["外から (ふだん・火を回した最中) と、中から (火を回した最中) のスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "火口湖のジオラマが出る (ピンクや仮の箱ではない)",
    "青い炎がゆらめき、湖に映っている",
    "Space で炎が燃え上がり、青い川が湖へ流れ下って広がる",
    "Space の最中、部屋の照明と床が青くなり、おさまると戻る",
    "大噴火のときは、今まで通り部屋が赤く脈打つ (青くならない)",
    "クリックで中に入ると、火口の縁に立つ",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project で DioramaBlueFire.shader を選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("組み立てても、仮の箱のまま",
     "Console に「NightShards/Diorama/BlueFire が見つからない」と出ていないか見てください。シェーダーの 1 行目近くの名前が `NightShards/Diorama/BlueFire` になっているか確認してください。"),
    ("中に入ったら、地面に埋まる・浮く",
     "シェーダーと C# の地形の式がずれている可能性。どのあたりで起きたかを教えてください。"),
]

NEXT = ("スクリーンショットを見て、炎の大きさ・湖の色・煙の濃さを詰めます。火の間が仕上がったら、次の部屋 (月の間か海の間) の 2 作品に進みます。")
