"""段階9 (演出の最中は、やり直さない) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 9"
STEP_TITLE = "段階9:演出の最中は、もう一度押しても最初からにしない"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "演出の最中にもう一度押しても、最初からやり直さないようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "厚みのある溶岩が流れ下って海で広がる・湯気の柱・傘のように広がる噴煙・球の噴石と光の尾。空の所は透明に"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "ジオラマの箱を台座から 2mm 浮かせた (台座が透けて見えるちらつきを直す)"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "鑑賞モードのぼかし (被写界深度) をやめた"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "ジオラマの地形の高さを C# でも計算する (世界の中で歩く地面)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "ジオラマの世界に入る・出る"),
        ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "そのまま",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "クリックでジオラマの世界に入る (歩いているときも鑑賞中も)。入る直前の吸い込みとリセット"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "左ボタンを離した瞬間 (クリックとドラッグを見分ける) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "部屋とジオラマの連動"),
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
    "title": "貼り直すのは DioramaWork.cs の 1 つだけです",
    "body": ["組み立て直しは要りません。貼って再生するだけで試せます。"],
}

OVERVIEW = ("大噴火の演出 (盛り上がり 1.5 秒・いちばん強い状態 9 秒・おさまるまで 7 秒、合わせて 17.5 秒) の最中に、"
            "もう一度 Space やクリックをしても何も起きないようにしました。おさまりきってから押すと、また大噴火します。"
            "鑑賞モードの Space も、世界の中のクリックも、同じ「仕掛けを動かす」所を通るので、1 か所直すだけで両方に効きます。")

FLOW = [
    ("ExhibitViewer / DioramaWorld", "Space (鑑賞モード) かクリック (世界の中) で、作品の Trigger() を呼ぶ (ここは今まで通り)"),
    ("DioramaWork.Trigger", "演出の最中 (始まってから 17.5 秒以内) なら、何もしないで戻る。終わっていれば、演出と地鳴りを始める"),
]

SEE = [
    "大噴火の最中に何度クリックしても、噴火は途中から最初に戻らず、そのまま続く",
    "地鳴りの音も重ならない",
    "完全におさまったあとにクリックすると、また大噴火する",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "DioramaWork.cs を貼り直す",
                "body": ["右のタブで ● の付いた `DioramaWork.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
        ],
    },
    {
        "title": "試す",
        "steps": [
            {
                "title": "鑑賞モードで試す",
                "body": ["「大噴火」を E で鑑賞し、Space で大噴火させてから、最中に何度か Space を押す。"],
                "ok": "噴火が最初からやり直されない。おさまったあとの Space で、また噴火する。",
            },
            {
                "title": "世界の中で試す",
                "body": ["クリックで中に入り、クリックで大噴火させてから、最中に何度かクリックする。"],
                "ok": "噴火が最初からやり直されない。",
            },
        ],
    },
]

CHECKS = [
    "最中の Space / クリックで、演出が最初に戻らない",
    "地鳴りが重なって鳴らない",
    "おさまったあとなら、また大噴火できる",
]

TROUBLE = [
    ("おさまったように見えるのに、次の噴火が始まらない",
     "最後の数秒は暗く静かですが、まだ「おさまっている途中」です。合わせて 17.5 秒たつと受け付けます。長すぎると感じたら教えてください (おさまる時間を短くします)。"),
]

NEXT = "段階8 の大噴火 (溶岩・噴煙・噴石) のスクリーンショットと FPS を見て、見た目を詰めます。"
