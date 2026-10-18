"""段階42 (部屋の名前の文字が出ない) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 42"
STEP_TITLE = "段階42:「何の間」の文字が出ないのを直す"

FILES = [
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "変更",
     "再生を始めたとき、すべての文字の絵をフォントに作らせ、文字のマテリアルに入れ直す (「何の間」などの文字が消えるのを直す)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "あふれた明るさ (無限大・非数) の点を取りのぞく (上や下を向くと画面が白い砂嵐になるのを直す)"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "同じく、あふれた点を取りのぞく"),
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "そのまま",
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
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
]

NOTICE = {
    "title": "1 つのファイルを貼り直すだけです",
    "body": ["`CaptionText.cs` を、中身を全部置き換えてください。組み立て直しはいりません (再生を始めると、自動で文字を入れ直します)。"],
}

OVERVIEW = ("入口の上の「アジアの間」などの部屋の名前、床の名前、作品のキャプションの文字が出なくなっていたのを直しました。"
            "**原因**: 文字は、フォントの「文字の絵」(テクスチャ) から切り抜いて描いています。この文字の絵は、シーンに保存されず、再生のたびにフォントが作り直します。"
            "美術館を組み立てたときに、文字のマテリアルにその時の文字の絵を入れていましたが、Android に切りかえたあとなどで作り直されると、マテリアルが古い (空の) 絵を見たままになり、文字が透明になっていました。"
            "**直し方**: 再生を始めたときに、シーンにあるすべての文字を集めて、フォントに文字の絵を作らせ、文字のマテリアルに新しい絵を入れ直し、文字の形も作り直させるようにしました。"
            "そのあとで絵が作り直されたときも、自動で入れ直します。")

FLOW = [("再生のはじめ", "RuntimeInitializeOnLoadMethod で、シーンを読みこんだ直後に、TextMesh を全部さがす。RequestCharactersInTexture で全部の文字の絵を作らせてから、マテリアルの mainTexture を入れ直す")]

SEE = ["入口の上の「○○の間」の文字が見える", "床の部屋の名前と、作品のキャプションも見える"]

PHASES = [
    {"title": "ファイルを入れる", "steps": [{"title": "貼り直す", "body": ["`CaptionText.cs` を貼り直す。"], "ok": "Console に赤いエラーがない。"}]},
    {"title": "確かめる", "steps": [{"title": "文字を見る", "body": ["Play して、ドームから各部屋の入口の上を見る。部屋に入って、作品のキャプションも見る。"], "ok": "文字が見える。"}]},
]

CHECKS = ["部屋の名前の文字が見える"]

TROUBLE = [("まだ見えない", "Hierarchy で、入口の上の Sign の下の Name を選び、Inspector の Mesh Renderer の Material と、TextMesh の Font が入っているかのスクリーンショットを送ってください。")]

NEXT = "直ったら、Quest 2 で動かしてみます。"
