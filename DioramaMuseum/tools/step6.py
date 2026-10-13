"""段階6 (品質の基準: 大噴火) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 6"
STEP_TITLE = "段階6:品質の基準になる 1 作品目「大噴火」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "新規",
     "作品「大噴火」。火山島・溶岩の流れ・噴煙・火山雷・噴石・夜の海"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "新規",
     "作品の仕掛け (Space) を動かし、地鳴りの音を作って鳴らす"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "新規",
     "部屋とジオラマの連動。仕掛けが動くと、部屋の照明と床の光が脈打つ"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "新規",
     "画面の仕上げ。ブルーム・トーンマップ・ビネットと、鑑賞モードのミニチュア写真風のぼかし"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "作品専用のマテリアルを作る。部屋に RoomReactor、プレイヤーに MuseumPost を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "変更",
     "作品専用のシェーダーがあればそれで描き、仕掛けの係 (DioramaWork) を付ける"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "作品ごとに専用シェーダーの名前 (work) を持てるようにし、「大噴火」を Eruption にした"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "変更",
     "鑑賞中に Space で仕掛けを動かす。仕掛けの間はカメラが地響きで揺れる"),
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
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "この作品が、残り 15 作品の品質の基準になります",
    "body": [
        "作品の中身だけでなく、全作品で使う土台も一緒に入れました:**作品ごとの専用シェーダー**、**Space の仕掛け**、**部屋との連動**、**鑑賞モードのミニチュア写真風のぼかし**、**音**。",
        "見た目は、あなたの目で見て「圧倒されるか」がすべてです。物足りない所 (噴煙の量・溶岩の明るさ・色・ぼかしの強さ・音) を遠慮なく言ってください。ここで詰めた水準を、残りの作品にそのまま使います。",
    ],
}

OVERVIEW = ("火の間の「大噴火」を、この美術館の品質の基準として作り込みます。夜の海に浮かぶ火山島で、"
            "山肌には雨で削られた谷が放射状に走り、山腹を溶岩がゆっくり流れ下ります。火口からは立体的な噴煙が立ちのぼり、"
            "下から溶岩に赤く照らされ、ときどき中で火山雷が光ります。"
            "鑑賞モードで **Space** を押すと**大噴火**。噴煙が一気に高く傘のように広がり、赤く光る噴石が放物線を描いて飛び、"
            "溶岩の流れが海まで届いて湯気が立ち、雷が増えます。同時に、地鳴りが響き、カメラが揺れ、"
            "**火の間の床の溶岩のひびと赤い照明が一斉に脈打ちます**。")

FLOW = [
    ("DioramaEruption (地形)", "火山の高さ = 円すい + 放射状の谷 + 火口のくぼみ。海は高さ -0.22 の水面。線を少しずつ進めて地面か水面に当たった所を塗る"),
    ("DioramaEruption (溶岩)", "火口から 3 本の流れ。流れの中心線までの距離で「どれだけ流れの上か」を決め、熱いほど黄色く光らせる。冷えた黒い皮の割れ目からだけ光る"),
    ("DioramaEruption (噴煙)", "地面とは別に、火口の上の箱の中を 8〜28 回に分けて進み、3D ノイズの雲の濃さを積み上げる。下ほど溶岩の赤、雷の近くは青白く光る"),
    ("DioramaEruption (仕掛け)", "_Event (0〜1) で、噴煙の高さ・溶岩の届く距離・雷の頻度・噴石・火口の明るさをまとめて強くする"),
    ("DioramaWork", "Space を押すと _Event を 1.5 秒で 1 まで上げ、9 秒保ち、7 秒でおさめる。地鳴りの音もここで波形を作って鳴らす"),
    ("RoomReactor", "仕掛けの強さを受け取り、この部屋の照明と床の光 (溶岩のひび) を強く揺らめかせる"),
    ("MuseumPost", "ブルームで溶岩と雷がにじみ、ACES で映画のような階調に。鑑賞モードでは作品の前後をぼかして、ミニチュア写真のように見せる"),
]

SEE = [
    "火の間に入って左の台座 (大噴火) のガラスケースに、夜の海に浮かぶ火山島",
    "山腹を溶岩がゆっくり流れ、黒い皮の割れ目から赤く光る。火口には溶岩だまり",
    "火口から噴煙が立ちのぼり、下のほうが赤く照らされている。ときどき中が青白く光る (火山雷)",
    "波打ち際に白い泡。水面に噴煙の赤が映る。ケースの横から見ると、地層の断面の真ん中に赤いマグマの通り道",
    "鑑賞モードでは、作品の後ろの部屋がぼけて、作品が小さな世界のように浮かび上がる",
    "Space で大噴火: 噴煙が高く広がり、噴石が飛び、溶岩が海まで届いて湯気。地鳴りとカメラの揺れ。火の間の床と照明が脈打つ",
    "館全体: 明るい所がにじみ (ブルーム)、画面の四隅が少し暗くなる",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "作品のシェーダーを作る",
                "body": ["`Shaders` に **Create > Shader > Unlit Shader** で `DioramaEruption` を作り、中身を置き換える。"],
                "ok": "`DioramaEruption` を選ぶと、Inspector の一番上が `NightShards/Diorama/Eruption` で、赤いエラーがない。",
            },
            {
                "title": "新しいスクリプトを 3 つ足す",
                "body": ["`Scripts` に `DioramaWork`・`RoomReactor`・`MuseumPost` を作り、中身を置き換える。"],
                "ok": "3 つのファイルがある。",
            },
            {
                "title": "変更のあった 4 つを貼り直す",
                "body": ["`MuseumLayout.cs`・`MuseumBuilder.cs`・`ExhibitStand.cs`・`ExhibitViewer.cs` を右の新しいものに置き換える。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ (設計図を初期設定に戻さなくてよい)。"],
                "ok": "Scene ビューで、火の間の「大噴火」の台座に新しいジオラマが載っている。",
            },
        ],
    },
    {
        "title": "鑑賞する",
        "steps": [
            {
                "title": "まず静かな状態を見る",
                "body": [
                    "再生して火の間へ行き、「大噴火」に近づいて E で鑑賞する。",
                    "ぐるっと回し、寄ったり離れたりして、溶岩・噴煙・海・断面を見る。",
                ],
                "ok": "後ろの部屋がぼけて、ケースの中の火山島が浮かび上がって見える。",
            },
            {
                "title": "大噴火させる",
                "body": [
                    "**Space** を押す。音が出るように、スピーカーかヘッドホンをつないでおく。",
                    "鑑賞中なら何度でも押せる。押すたびに、噴火が最初からやり直しになる。",
                ],
                "ok": "噴煙が高く広がり、噴石が飛び、地鳴りが響き、カメラが揺れ、火の間の床と照明が脈打つ。15 秒ほどでおさまる。",
            },
            {
                "title": "感想とスクリーンショットを送る",
                "body": [
                    "静かな状態と大噴火の最中のスクリーンショット、それに鑑賞中の FPS (F1) を送ってください。",
                    "「噴煙をもっと多く」「溶岩をもっと明るく」「ぼかしを弱く」など、思ったことをそのまま書いてください。数値を調整して返します。",
                ],
            },
        ],
    },
]

CHECKS = [
    "大噴火のジオラマがピンク色や真っ黒でなく、火山島に見える",
    "鑑賞モードで後ろがぼける。E で戻ると、ぼけが消える",
    "Space で大噴火が起き、15 秒ほどでおさまる",
    "大噴火のとき、地鳴りの音が作品の方向から聞こえる",
    "大噴火のとき、火の間の床のひびと照明が明るく脈打つ",
    "館のどこでも、明るい所が少しにじんで見える (ブルーム)",
]

TROUBLE = [
    ("ジオラマがピンク色",
     "`DioramaEruption` を選んで、Inspector のエラー文を貼ってください。"),
    ("大噴火の台座が前のジオラマのまま",
     "Console に「NightShards/Diorama/Eruption が見つからない」と出ていないか確認する。シェーダーの 1 行目の名前が合っているか見る。"),
    ("鑑賞モードで、作品までぼけてしまう",
     "`Player` の **Museum Post** の Aperture を 4 → 8 に上げる (ぼけが弱くなる)。Focus Offset を変えても合わせられる。"),
    ("全体が明るすぎる・白っぽい",
     "ブルームが強すぎる。Museum Post の Bloom Intensity を 0.8 → 0.4 に下げる。"),
    ("Space を押しても何も起きない",
     "鑑賞モード中 (カメラが作品の前にあるとき) に押しているか確認する。画面の一番下の案内に「Space 仕掛け」と出ていれば押せる。"),
    ("音が出ない",
     "Game ビューの上の **Mute Audio** (スピーカーのアイコン) がオンになっていないか確認する。"),
]

NEXT = ("基準が決まったら、同じ土台で残りの作品を 1 部屋ずつ作ります。火の間のもう 1 作品「青い火の火口湖」から始めるか、"
        "ほかの部屋から作るかは選べます。")
