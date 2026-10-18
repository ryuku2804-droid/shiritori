"""段階41 (白い砂嵐・点滅・文字の消え) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 41"
STEP_TITLE = "段階41:白い砂嵐・赤い部屋の点滅・文字が消えるのを直す"

FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "変更",
     "あふれた明るさ (無限大・非数) の点を取りのぞく (上や下を向くと画面が白い砂嵐になるのを直す)"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "変更",
     "同じく、あふれた点を取りのぞく"),
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "変更",
     "いちばん粗い細かさを 40% → 60% に (文字が消えるのを直す)。1 秒ごとにゆっくり変える。目標を 40 fps に"),
    ("Assets/NightShards/Museum/Scripts/VRSupport.cs", "そのまま",
     "VR のコントローラーの入力 (VRInput) と、頭の動きをカメラに写す VRRig。A ボタンで近くの作品の仕掛け。Quest のフォービエイテッド。再生すると自動で動く"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "左スティックで歩く・押しこみで走る・トリガーでクリック・B ボタンで E と同じ、を足した"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "VR: 右スティックで 30 度ずつ向きを変える・頭の向きへ歩く・視点の揺れとジャンプを止める"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "VR では鑑賞モードを使わず、トリガーで作品の中に入る"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "そのまま",
     "F4 で「自動 → 100% → 75% → 50%」を切りかえ、いまの細かさを表示する"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "中に入ったときのレイの回数を 180 → 140、影を 24 → 16 に減らした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "金閣寺の世界の中で池をクリックすると、その場所へ鯉を呼ぶ (ぱしゃぱしゃの音つき)"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "金閣寺の池の水面の高さと「そこが池か」を、ほかのスクリプトから使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「万里の長城」を GreatWall、「日本の庭」を Kinkaku で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "ジオラマの箱を台座から 2mm 浮かせた (台座が透けて見えるちらつきを直す)"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "鑑賞モードのぼかし (被写界深度) をやめた"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "そのまま",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumDome.cs", "そのまま",
     "ドームの形をメッシュで作る道具 (円の床・出入口つきの円い壁・半球の天井・光の柱)"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "そのまま",
     "描く距離を 30m に広げた (ドームから通路の奥の作品が見えるように)"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "「設計図を初期設定に戻して組み立てる」を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "漆喰の壁・砂岩・大理石・ドームの床・格天井の5つを追加"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "部屋が回して置かれても、夕日が正しい向きから差すようにした"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "そのまま",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
]

NOTICE = {
    "title": "3 つのファイルを貼り直すだけです",
    "body": ["`MuseumSurface.shader`・`MuseumArt.shader`・`AutoQuality.cs` を、中身を全部置き換えてください。組み立て直しはいりません。"],
}

OVERVIEW = ("**白い砂嵐**: 上 (ドームの格天井) や下 (方位盤の床) を向くと、画面がまっ白になり、黒い粒だけが見えていました。"
            "床や天井はつやがあるので、スポットライトの照り返しがとても明るくなります。Android に切りかえると、この光の計算が精度の低い数 (half) で行われ、明るすぎて数があふれ (無限大)、"
            "その 1 点が、光のにじみ (ブルーム) で画面じゅうに広がって、まっ白になっていました。"
            "ジオラマのシェーダーでは前に同じことを直していましたが、美術館の床・壁・天井のシェーダー (MuseumSurface) と部屋のアート (MuseumArt) には入れていなかったので、"
            "出す色を 0〜64 の間に収め、あふれた点を取りのぞくようにしました。"
            "**赤い部屋の点滅**: 火の間の、黒曜石の床の光る割れ目と赤い壁でも、同じあふれが起きて、ときどき白く光っていたのだと思います。同じ直しで消えるはずです。"
            "**文字が消える**: F1 の表示が「細かさ 自動 40%」になっていました。画面を 40% の細かさで描いてから引きのばしていたので、部屋の名前などの細い文字がつぶれて消えていました。"
            "いちばん粗い細かさを 60% にし、細かさを変えるのも 1 秒ごとにゆっくりにしました。パソコンの目標の FPS は 40 にしました (VR では 72)。")

FLOW = [
    ("あふれ", "half (16 ビットの数) は 65504 より大きい数を表せない。つやのある面のハイライトの計算で、それをこえると無限大になる。ブルームは明るい点をぼかして広げるので、無限大が画面じゅうに広がる"),
    ("取りのぞき方", "min(max(色, 0), 64)。無限大は 64 に、非数 (NaN) は 0 になる"),
]

SEE = ["上や下を向いても、白い砂嵐にならない", "赤い部屋が点滅しない", "部屋の名前の文字が見える"]

PHASES = [
    {"title": "ファイルを入れる", "steps": [{"title": "3 つ貼り直す", "body": ["`MuseumSurface.shader`・`MuseumArt.shader`・`AutoQuality.cs` を貼り直す。"], "ok": "Console に赤いエラーがない。"}]},
    {"title": "確かめる", "steps": [
        {"title": "上と下を向く", "body": ["ドームのホールで、天井と床を見る。火の間に入る。"], "ok": "白い砂嵐や点滅が出ない。"},
        {"title": "文字", "body": ["部屋の入口の上の名前が見えるか確かめる。F1 で「細かさ」が 60% 以上になっているか見る。"]},
    ]},
]

CHECKS = ["白い砂嵐が出ない", "赤い部屋が点滅しない", "文字が見える"]

TROUBLE = [
    ("まだ白くなる場所がある", "どこを見たときかがわかる動画かスクリーンショットを送ってください。"),
    ("重くなった", "細かさを 60% より下げないようにしたので、重い所では FPS が少し下がります。F1 の FPS を教えてください。"),
]

NEXT = "直ったら、Quest 2 で動かしてみます。"
