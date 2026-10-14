"""段階12 (画面の白い点滅を直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 12"
STEP_TITLE = "段階12:火の間で画面が白く点滅するのを直す"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "変更",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "作り直し: 黒い崖から流れ落ちる青い炎の滝と、ターコイズの滝つぼ。仕掛けは湖に燃え広がる炎"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "新しい地形 (崖・台地・滝つぼ) に合わせて、歩く地面と立つ場所 (手前の岸) を直した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
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
    "title": "貼り直すのは MuseumArt.shader の 1 つだけです",
    "body": ["組み立て直しは要りません。貼って再生するだけで直ります。"],
}

OVERVIEW = ("動画を 1 コマずつ調べると、1〜2 秒おきに 2 コマだけ、画面全体が真っ白になっていました。原因は**火の間の火の粉**です。"
            "火の粉は床から部屋じゅうに舞い上がるので、ときどきカメラ (目) のすぐ前を通ります。そのとき、小さな火の粉が画面いっぱいの大きな光になり、"
            "ブルーム (明るい所がにじむ仕上げ) で画面全体が白く飛んでいました。"
            "火の粉はカメラに近いほど薄くして、0.5m より近いと見えないようにしました。離れた所の火の粉は今まで通りです。")

FLOW = [
    ("火の粉 (パーティクル)", "床から舞い上がり、部屋じゅうを漂う。目の高さも通る"),
    ("MuseumArt (火の粉の描き方)", "火の粉の 1 つずつについて、カメラからの距離を測る。1.5m より近いと薄くなり始め、0.5m より近いと消える"),
]

SEE = [
    "火の間で立ち止まっていても、歩いても、画面が白く光らない",
    "少し離れた所の火の粉は、今まで通り舞っている",
]

PHASES = [
    {
        "title": "直す",
        "steps": [
            {
                "title": "MuseumArt.shader を貼り直す",
                "body": ["右のタブで ● の付いた `MuseumArt.shader` を貼り直す。"],
                "ok": "Console にエラーがない。",
            },
            {
                "title": "火の間で確かめる",
                "body": ["再生して火の間に入り、30 秒ほど歩いたり立ち止まったりする。"],
                "ok": "画面が白く点滅しない。",
            },
        ],
    },
]

CHECKS = [
    "火の間で画面が白く点滅しない",
    "火の粉は離れた所で、今まで通り舞っている",
]

TROUBLE = [
    ("まだ白く点滅する",
     "点滅するときの動画か、白くなった瞬間のスクリーンショットを送ってください。火の粉以外の原因を調べます。"),
]

NEXT = "段階11 の青い炎の滝のスクリーンショットと FPS を見て、見た目を詰めます。"
