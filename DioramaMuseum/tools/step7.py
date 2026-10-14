"""段階7 (大噴火の質を上げる・ジオラマの世界に入る) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 7"
STEP_TITLE = "段階7:ジオラマの世界に入る (と、大噴火の質を上げる)"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "新規",
     "ジオラマの地形の高さを C# でも計算する。シェーダーと同じ式。世界の中で歩く地面になる"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "新規",
     "ジオラマの世界に入る・出る。120 倍に拡大したジオラマと、歩ける地面と、世界の端の壁を作る"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "水面に島と溶岩が映る・遠くほど霞む・岩肌の細かい尾根・噴煙の自分の影・空の月"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "世界の中では音を場所に関係なく鳴らせるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "変更",
     "作品名から決めた数 (Seed) と作品専用シェーダーの名前を、外から読めるようにした"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "変更",
     "クリックでジオラマの世界に入る (歩いているときも鑑賞中も)。入る直前の吸い込みとリセット"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "変更",
     "左ボタンを離した瞬間 (クリックとドラッグを見分ける) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "変更",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "部屋とジオラマの連動"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "画面の仕上げ"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "作品ごとに専用シェーダーの名前 (work) を持てるようにし、「大噴火」を Eruption にした"),
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
    "title": "クリックで、ジオラマの中に入れます",
    "body": [
        "「大噴火」をクリックすると、画角が狭まりながら白く吸い込まれ、**120 倍に拡大した火山島の浜辺**に立ちます。目の前に高さ 70m ほどの火山、まわりは夜の海、空には月と噴煙。歩いて山を登れます。",
        "中でクリックすると大噴火。E か Esc で美術館の元の場所に戻ります。いまは「大噴火」だけが入れる作品です (ほかの作品も、作り込むときに同じように入れるようにします)。",
    ],
}

OVERVIEW = ("2 つのことをしました。1 つ目は、**ジオラマの世界に入れる**ようにしたこと。同じシェーダーで描いた大きな箱の中にカメラを入れると、"
            "シェーダーは「箱の中から見た景色」を描くので、ジオラマがそのまま世界になります。歩く地面は、シェーダーの地形の式を C# に書き写して作った当たり判定です。"
            "2 つ目は、**大噴火の質を上げた**こと。水面に島の影と溶岩の光が映り、遠くほど霞んで奥行きが出て、岩肌がごつごつし、噴煙には自分の影が落ち、空に月が浮かびます。")

FLOW = [
    ("ExhibitViewer", "歩いているときは作品を見てクリック、鑑賞中は「押してすぐ離す」クリックで DioramaWorld.Enter を呼ぶ (ドラッグとは動かした量で見分ける)"),
    ("DioramaWorld (入る)", "画角を 70° → 22° に狭めながら白くする。そのあいだに、地下 3000m に作品と同じマテリアルの 120m の箱を作る"),
    ("DioramaTerrain", "シェーダーの Height() と同じ式で地形の高さを計算し、160×160 のます目の当たり判定 (目に見えない地面) を作る。海は水面のすぐ下を地面にして、浅瀬を歩けるようにする"),
    ("DioramaWorld (中)", "島の中心から手前へ進んで、海の手前の浜辺に立たせ、火山のほうを向かせる。クリックで大噴火、E / Esc で暗転して美術館の元の場所へ"),
    ("DioramaEruption", "カメラが箱の中にいると、線は箱の中から出発する。ガラスや台は描かず、ケースの壁より外は空になる (世界の端)"),
]

SEE = [
    "火の間の「大噴火」に近づくと「E で鑑賞　クリックで中に入る」と出る",
    "クリックすると、作品へ吸い込まれるように白くなり、火山島の浜辺に立っている。足元は黒い砂、目の前に火山、溶岩が流れ、噴煙が上がる",
    "歩いて山を登れる。海に入ると、浅瀬を歩くように進める。世界の端は見えない壁",
    "中でクリックすると大噴火 (噴煙・噴石・雷・地鳴り)",
    "E か Esc で暗転して、美術館の元の場所に戻る",
    "外から見る大噴火も変わる: 水面に島の黒い影と溶岩の光が映る、奥ほど霞む、空に月",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "新しいスクリプトを 2 つ足す",
                "body": ["`Scripts` に `DioramaTerrain` と `DioramaWorld` を作り、中身を置き換える。"],
                "ok": "2 つのファイルがある。",
            },
            {
                "title": "変更のあった 7 つを貼り直す",
                "body": ["右のタブで ● の付いたものを、上から順に貼り直す (シェーダー 1 つとスクリプト 6 つ)。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "エラーなく組み上がる。",
            },
        ],
    },
    {
        "title": "中に入る",
        "steps": [
            {
                "title": "外から見て、クリックで入る",
                "body": [
                    "再生して火の間へ行き、「大噴火」を見て、プロンプトに「クリックで中に入る」と出たらクリックする。",
                    "鑑賞モード (E) の中からでも、ドラッグせずに 1 回クリックすれば入れる。",
                ],
                "ok": "白く吸い込まれて、火山島の浜辺に立っている。",
            },
            {
                "title": "中を歩く",
                "body": [
                    "火山へ向かって歩き、斜面を登る。振り返って海を見る。海へ入ってみる。",
                    "クリックで大噴火させる。",
                ],
                "ok": "地面の見た目と、足が着く高さが合っている (浮いたり、埋まったりしていない)。",
            },
            {
                "title": "戻る",
                "body": ["E か Esc を押す。"],
                "ok": "暗転して、入る前にいた美術館の場所に戻る。",
            },
            {
                "title": "スクリーンショットと感想を送る",
                "body": [
                    "中で見た景色 (浜辺から火山・山の上から海・大噴火の最中) と、外から見た大噴火のスクリーンショットを送ってください。",
                    "中の FPS (F1) もお願いします。中は画面いっぱいがレイマーチングになるので、外から見るより重くなります。",
                ],
            },
        ],
    },
]

CHECKS = [
    "クリックで中に入れて、浜辺に立つ",
    "足が地面の上にあり、坂を登れる。地面の見た目とずれていない",
    "中でクリックすると大噴火が起き、地鳴りが聞こえる",
    "E / Esc で、入る前の場所に戻れる",
    "戻ったあと、鑑賞モードや歩きが今まで通りに使える",
    "外から見た大噴火の水面に、島の影と溶岩の光が映っている",
]

TROUBLE = [
    ("クリックしても入れない (プロンプトに「クリックで中に入る」が出ない)",
     "「大噴火」が作品専用のシェーダーで描かれていないと入れない。Console に Eruption が見つからないという警告が出ていないか見る。"),
    ("中が真っ黒・真っ白",
     "スクリーンショットを送ってください。中では霞や明るさの効き方が外と違うので、値を調整します。"),
    ("足が地面に埋まる・浮いている",
     "シェーダーと C# の地形の式がずれている可能性。どのあたりで起きたか (浜辺・山の上など) を教えてください。"),
    ("中がとても重い (FPS が 10 を切る)",
     "`Player` の **Diorama World** で、Scale を変えずに `Ground Resolution` はそのまま、まずは F4 (解像度を下げる) で変わるか試して、数字を送ってください。"),
    ("戻ったあとカーソルが出たままになる",
     "画面を 1 回クリックすると戻る。毎回起きるなら教えてください。"),
]

NEXT = ("中から見た景色と FPS を見て、世界の中での明るさ・霞・遠景を詰めます。そのあと、同じ水準で残りの作品を 1 部屋ずつ作り、"
        "それぞれ中に入れるようにします。")
