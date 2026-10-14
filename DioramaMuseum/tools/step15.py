"""段階15 (「青い火の焦土」を軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 15"
STEP_TITLE = "段階15:「青い火の焦土」を軽くする"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "軽くした: 炎の輪・木の根元・細かいひび・煙の計算を減らした"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "同じ守りを、大噴火にも入れた"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "焦土の地形に合わせて、歩く地面と立つ場所を直した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "作品名を「青い火の焦土」にし、説明文を変えた"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "青い炎の音 (ガスが燃える音) と、部屋の照明を青に染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた場所 (火口の縁) に立てるようにした"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
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
    "title": "貼り直すのは DioramaBlueFire.shader の 1 つだけです",
    "body": ["組み立て直しは要りません。貼って再生するだけで試せます。"],
}

OVERVIEW = ("青い炎 (仕掛けの最中) で FPS が 10 まで落ちる原因は、**広がる炎の輪**の計算でした。"
            "輪を描くとき、画面のほぼ全部のピクセルで 36 回ずつ進みながら、そのたびに細かい地形の高さを計算していました。"
            "地形の高さは、細かい起伏を省いた軽い版で十分なので、それに置き換え、進む回数も 22 回に減らしました。"
            "ほかにも、ふだんから重かった所を軽くしました: 枯れ木の根元の高さ (軽い版に)、細かいひび (2 枚目のボロノイをやめて軽いノイズの線に)、"
            "煙 (進む回数を約 3 分の 2 に)。見た目はほとんど変わりません。")

FLOW = [
    ("FrontFlames (炎の輪)", "進む回数 36 → 22。地面の高さは軽い版 (HeightCoarse)。炎の輪から離れた所では、高さも計算しない"),
    ("Trees (枯れ木)", "根元の高さを軽い版に。そのぶん根元を少し深く地面に埋めて、浮いて見えないようにした"),
    ("Shade (ひび割れ)", "大きな割れ目はボロノイのまま、細かいひびは軽いノイズの線で描く"),
    ("Smoke (煙)", "進む回数を、最大 32 → 20 に"),
]

SEE = [
    "Space で青い炎の輪が広がっている間も、FPS が大きく落ちない",
    "ふだんの FPS も少し上がる",
    "見た目はほとんど変わらない (細かいひびの形が少し変わる)",
]

PHASES = [
    {
        "title": "直す",
        "steps": [
            {
                "title": "DioramaBlueFire.shader を貼り直す",
                "body": ["右のタブで ● の付いた `DioramaBlueFire.shader` を貼り直す。"],
                "ok": "Console にエラーがなく、シェーダーを選んだ Inspector にもエラーがない。",
            },
            {
                "title": "FPS を測る",
                "body": [
                    "F1 で FPS を出し、「青い火の焦土」を E で鑑賞する。",
                    "ふだんの FPS と、Space を押したあとの一番低い FPS を見る。",
                ],
                "ok": "前より FPS が高い。",
            },
            {
                "title": "数字を送る",
                "body": ["ふだんの FPS と、仕掛けの最中の一番低い FPS を送ってください。まだ低ければ、さらに削ります。"],
            },
        ],
    },
]

CHECKS = [
    "仕掛けの最中の FPS が、前 (10) より上がっている",
    "枯れ木が地面から浮いていない",
    "見た目がほとんど変わっていない",
]

TROUBLE = [
    ("まだ重い",
     "ふだんと仕掛けの最中の FPS を送ってください。F4 で解像度を下げると FPS が上がるかどうかも教えてください (上がるなら、画面の大きさに比例する重さです)。"),
    ("枯れ木が浮いている・埋まりすぎている",
     "どのあたりの木か、スクリーンショットを送ってください。"),
]

NEXT = "FPS の数字を見て、まだ足りなければ、さらに軽くします。そのあと見た目を詰めます。"
