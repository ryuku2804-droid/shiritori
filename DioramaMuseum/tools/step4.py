"""段階4のページの中身。make_source_page.py が読み込む。"""

from step1 import museum_map  # 平面図は段階1と同じ

STEP_LABEL = "STEP 4"
STEP_TITLE = "段階4:ジオラマを作り、重さを調整する"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "新規",
     "ガラスケースのジオラマ。Cube の中をレイマーチングして4つのバイオームを描く"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "新規",
     "距離でレイの細かさを変え、画面外と遠くのジオラマを描かない"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "ジオラマのマテリアルを MuseumDiorama で作り、プレイヤーに DioramaLOD を付ける"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "変更",
     "組み立てるとき、MuseumDiorama でマテリアル (Museum Diorama.mat) を作る"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "変更",
     "ジオラマの箱に、種類 (_Biome) と作品名から決めた形 (_Seed) を渡す"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "天井の光のスリット (モード 4) を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "そのまま",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "黒曜石と溶岩のひび・水盤・水の光の3種類を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "水盤・黒曜石・玄武岩の壁・水の光の壁と床の5つのマテリアルを追加"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "夕の間の夕日"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "鑑賞モード"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "館の設計図"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "キーとマウスの読み取り"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "ジオラマを新しく作りました",
    "body": [
        "既存のコードの代わりに、この美術館用のジオラマ (`MuseumDiorama.shader`) を URP で作りました。台座の上の仮の箱が、ガラスケースに入った小さな世界に変わります。",
        "**新規** の2つと **変更** の3つを貼り、**Tools > Diorama Museum > 美術館を組み立てる** を選んでください。",
    ],
}

OVERVIEW = ("台座の上のガラスケースの中に、レイマーチングで小さな世界を描きます。"
            "**アルプス月夜** は月明かりの雪山と針葉樹と湖、**火山島** は海に浮かぶ火山と流れ下る溶岩、"
            "**日本の夕焼け** は川沿いの村と鳥居と夕日、**南国の島** はエメラルドの浅瀬と椰子の木。"
            "ケースの側面からは地層の断面と水槽のような水の断面が見えます。"
            "同じバイオームの2作品は、作品名から決めた数 (Seed) で地形の形が変わります。"
            "あわせて、**近いジオラマほど細かく、遠いものは粗く描き、画面に映っていないものと遠すぎるものは描かない**ようにして、重さを抑えます。")

FLOW = [
    ("MuseumDiorama (しくみ)", "Cube の裏側の面を描き、画素ごとに「カメラ → 画素」の線を Cube の中で作る。線を少しずつ進め、地形や木までの距離 (SDF) が 0 に近づいた所で止まって色を塗る"),
    ("MuseumDiorama (世界)", "Height で地面の高さ、Pines / Village / Palms で木・家・鳥居・椰子を置く。当たらなかった線は、そのバイオームの空を塗る"),
    ("MuseumDiorama (仕上げ)", "影はもう一度光の方向へ線を進めて調べる。外から見ているときだけ、ガラスの映り込みと金属の枠を足す"),
    ("ExhibitStand", "Cube に _Biome (種類) と _Seed (作品名から決めた数) を渡す"),
    ("DioramaLOD", "毎フレーム、カメラからの距離で _Steps (線を進める回数) と _ShadowSteps (影を調べる回数) を決める。画面外と 22m より遠いものは描かない。鑑賞中の作品はいちばん細かく"),
]

SEE = [
    "台座の上が、黒い台と金属の枠のガラスケースになり、中に小さな世界がある",
    "月の間: 月明かりに照らされた雪の山脈と、ふもとの針葉樹、手前の湖。空に星と月",
    "火の間: 暗い海に浮かぶ火山。火口と山腹の筋が橙に光って脈打つ",
    "夕の間: 手前の村の白壁と瓦屋根、朱色の鳥居、川。奥の山の向こうに夕日",
    "海の間: 青緑の浅瀬に囲まれた砂の島と、椰子の木。青空と雲",
    "ケースの横から見ると、地面の断面が地層のしま模様に、水の断面が水槽のように見える",
    "同じ部屋の2つの作品は、地形の形が違う",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "ジオラマのシェーダーを作る",
                "body": [
                    "`Shaders` フォルダを右クリック > **Create > Shader > Unlit Shader**。名前を `MuseumDiorama` にして、中身を右のものに置き換える。",
                ],
                "ok": "`MuseumDiorama` を選ぶと、Inspector に赤いエラーがない。",
            },
            {
                "title": "スクリプトを1つ足し、3つ貼り直す",
                "body": [
                    "`Scripts` に **Create > MonoBehaviour Script** で `DioramaLOD` を作り、中身を置き換える。",
                    "`ExhibitStand.cs`・`MuseumBuilder.cs`・`Editor/MuseumMenu.cs` を右の新しいものに置き換える。",
                ],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "Tools で組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。Generated フォルダに `Museum Diorama` のマテリアルができる。"],
                "ok": "Scene ビューで、台座の上にガラスケースのジオラマが見える。",
            },
        ],
    },
    {
        "title": "再生して見る",
        "steps": [
            {
                "title": "4つの部屋のジオラマを鑑賞する",
                "body": [
                    "再生して、各部屋のジオラマに近づき、E で鑑賞モードに入ってぐるっと回す。横からの断面も見る。",
                    "画面上の **Stats** を押すと、右上に FPS が出る。各部屋の入口と、鑑賞モードで寄ったときの FPS をメモする。",
                ],
                "ok": "4つのバイオームがそれぞれ違う景色に見え、60fps 前後で動く。",
            },
            {
                "title": "結果を送る",
                "body": [
                    "各部屋のジオラマのスクリーンショット (鑑賞モードで寄ったもの) と、FPS の数字を送ってください。",
                    "重すぎるとき・粗すぎるときは、`Player` の **Diorama LOD** の Steps (近い / 遠い) を変えると、どう変わるかも教えてください。",
                ],
            },
        ],
    },
]

CHECKS = [
    "台座の上の仮の箱が、ガラスケースのジオラマに変わった",
    "4つのバイオームの見た目がそれぞれ違う",
    "同じ部屋の2つのジオラマの地形が違う",
    "鑑賞モードでケースの周りを回ると、中の世界が立体的に見える (板に描いた絵ではない)",
    "ケースの横から見ると、地層と水の断面が見える",
    "別の部屋にいるとき、FPS が大きく落ちていない",
]

TROUBLE = [
    ("ジオラマがピンク色",
     "`MuseumDiorama` を選んで、Inspector のエラー文を貼ってください。"),
    ("台座の上が仮の箱のまま",
     "`Museum` の Inspector の **Diorama Material** が空か、別のシェーダーのマテリアルになっている。Tools で組み立て直すと `Museum Diorama` が入る。"),
    ("ジオラマが真っ黒・空だけ",
     "スクリーンショットを送ってください。地形の高さや色の値を調整します。"),
    ("寄ると FPS が大きく落ちる",
     "`Player` の **Diorama LOD** の Steps の x (近いとき) を 110 → 80 などに下げる。Shadow Steps の x を 16 → 8 にしても軽くなる。"),
    ("遠くのジオラマがちらつく・欠ける",
     "Steps の y (遠いとき) を 40 → 60 などに上げる。"),
]

NEXT = ("段階5では、ジオラマに触れるとその世界に入れるようにします。"
        "カメラがガラスケースへ吸い込まれるように寄り、ジオラマが大きくなって、その地面に立って歩けます。")
