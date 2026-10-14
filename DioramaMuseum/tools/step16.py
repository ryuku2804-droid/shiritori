"""段階16 (見た目はそのままで、ジオラマを速くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 16"
STEP_TITLE = "段階16:見た目はそのままで、ジオラマを速くする"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "同じ速くする仕組みを入れた"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "地形の高さを表から読む・上へ抜ける線を早く打ち切る・当たった所だけ正確に合わせ直す"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "地形の高さを 512×512 の表に 1 回だけ計算して保存する (BakeHeight)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "再生が始まったら高さの表を作って、シェーダーに渡す"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "作品名を「青い火の焦土」にし、説明文を変えた"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
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
    "title": "貼り直すのは 4 つです",
    "body": [
        "シェーダー 2 つ (`DioramaEruption`・`DioramaBlueFire`) と、スクリプト 2 つ (`DioramaTerrain`・`DioramaWork`)。組み立て直しは要りません。",
        "速くなるのは**再生中だけ**です (高さの表は、再生が始まったときに作るため)。編集中のシーンビューでは今まで通りです。",
    ],
}

OVERVIEW = ("ジオラマの重さのいちばんの原因は、**地形の高さを、ノイズを何枚も重ねて毎回計算していた**ことでした。"
            "線を 1 本進めるたびに計算し、1 ピクセルあたり百回以上、画面全体では何千万回にもなります。"
            "そこで、再生が始まったときに C# で地形の高さを **512×512 の表**に 1 回だけ計算して保存し、"
            "シェーダーは線を進めるときにその表を読むだけにしました (画像ファイルは使わず、その場で作ります)。"
            "ただし、表は細かさに限りがあるので、**見た目に効く所 (地面の向き = 陰影、当たった点の位置) は、今まで通り正確な式で計算**します。"
            "だから見た目は落ちません。さらに、地形より上に出て空へ向かう線は、もう何にも当たらないので、すぐに打ち切るようにしました"
            " (中に入って空を見上げたときに、特によく効きます)。")

FLOW = [
    ("DioramaWork.Start (再生開始)", "DioramaTerrain.BakeHeight で、地形の高さを 512×512 の表に計算 (CPU のコアを全部使って、0.1 秒ほど)。表をシェーダーに渡す。同じ作品の 2 つ目 (中に入ったときの大きな箱) は、保存した表を使い回す"),
    ("HeightFast (速い高さ)", "表があれば表を読むだけ (1 回の読み出し)。なければ今まで通り式で計算"),
    ("線を進める (Frag)", "速い高さで進める。地形の上へ出て上を向いた線は、その場で打ち切る"),
    ("合わせ直し", "当たったら、正確な式で 2 回だけ位置を合わせ直す。地面の向き (SceneNormal) も正確な式で出す"),
]

SEE = [
    "ジオラマを見たときの FPS が上がる (特に、近くで画面いっぱいに見たときと、中に入ったとき)",
    "見た目は今までと同じ",
    "再生を始めた瞬間に、ほんの少し (0.1〜0.3 秒) 止まることがある (表を作っているため)",
]

PHASES = [
    {
        "title": "入れる",
        "steps": [
            {
                "title": "4 つを貼り直す",
                "body": ["右のタブで ● の付いたシェーダー 2 つとスクリプト 2 つを貼り直す。"],
                "ok": "Console に赤いエラーがなく、2 つのシェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "測る",
        "steps": [
            {
                "title": "FPS を比べる",
                "body": [
                    "再生して F1 で FPS を出し、火の間の 2 つのジオラマを、それぞれ E で鑑賞する。",
                    "ふだんと Space の最中の FPS、中に入ったときの FPS を見る。",
                ],
                "ok": "前より FPS が高い。見た目は変わらない。",
            },
            {
                "title": "数字を送る",
                "body": ["大噴火と青い火の焦土それぞれの、鑑賞中 (ふだん・仕掛けの最中) と中に入ったときの FPS を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "鑑賞中の FPS が前より高い",
    "中に入ったときの FPS が前より高い",
    "地面の見た目 (陰影・色・ひび) が変わっていない",
    "大噴火の溶岩・噴石、青い火の焦土の木・炎が、今まで通りの場所にある",
]

TROUBLE = [
    ("地面がギザギザ・段々に見える",
     "表の細かさの影響です。スクリーンショットを送ってください (表を細かくするか、合わせ直しの回数を増やします)。"),
    ("地面に穴が空く・すけて見える",
     "表と正確な式のずれが大きい所です。どの作品のどのあたりか教えてください。"),
    ("あまり速くならない",
     "F4 で解像度を下げたときに FPS が上がるか教えてください。上がるなら画面の大きさに比例する重さ (次は、ジオラマだけ少し低い解像度で描いて拡大する方法を考えます)。"),
]

NEXT = ("FPS の数字を見て、まだ足りなければ、噴煙・煙 (雲の計算) を軽くする工夫や、ジオラマだけを少し低い解像度で描く方法を入れます。")
