"""段階46 (死海のシェーダーがまだ時間切れになる) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 46"
STEP_TITLE = "段階46: Quest 用のシェーダーを新しいコンパイラー (DXC) で変換する"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "変更",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "ファイル全体を #if UNITY_EDITOR 〜 #endif で囲んだ。Editor フォルダの外に置いても、ゲームのビルドでエラーにならない"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "ほかのフォント (エディターの画面の文字など) の絵が、文字のマテリアルに入ってしまうのを直した。毎フレーム、ずれていないか確かめる"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "そのまま",
     "左上の表示 (fps・F2〜F5) を、はじめは出さないようにした (F1 で出せる)"),
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
                                                                        ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
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
    "title": "17 個のシェーダーをもう一度貼り直す。Vulkan だけになっているか確かめる",
    "body": ["「変更」と書いてある 17 個の .shader を、中身を全部置き換えてください。",
             "Player Settings → Android → Other Settings → Graphics APIs が Vulkan だけになっているか確かめてください。OpenGLES3 が残っていると、古いコンパイラーが使われて、また時間切れになります。"],
}

OVERVIEW = ("前の段階の [loop] だけでは、死海のシェーダーがまだ時間切れになっていたのを直しました。"
            "**調べたこと**: Microsoft の新しいシェーダーコンパイラー (DXC) を手元で動かして、16 個のジオラマのシェーダーを全部変換してみました。"
            "どれも 0.2〜5 秒で終わり、死海も 2 秒ほどでした。シェーダーの中身がおかしいのではなく、Unity がふだん Android 用に使う古い変換の道すじ (FXC で変換してから、もう一度 Vulkan 用に書きかえる) が、死海の形の組み合わせを苦手にしていて、何十分も終わらないのだと分かりました。"
            "**直し方**: すべてのジオラマのシェーダーに #pragma use_dxc vulkan を足しました。Vulkan 用に変換するときだけ、新しいコンパイラー (DXC) を使います。"
            "パソコン (Windows・DirectX) の見た目と速さは、今までと同じです。"
            "**大事**: Graphics APIs に OpenGLES3 が残っていると、そちらは古い道すじで変換されるので、また時間切れになります。Vulkan だけにしてください。")

FLOW = [("Vulkan (Quest)", "DXC で直接 Vulkan 用に変換。手元の試しでは 1 個 数秒"),
        ("DirectX (パソコン)", "今までどおりの変換。見た目は変わらない")]

SEE = ["ビルドが時間切れにならずに最後まで進む", "Quest 2 の中で美術館が起動する"]

PHASES = [
    {"title": "ファイルを入れる", "steps": [
        {"title": "貼り直す", "body": ["「変更」の 17 個の .shader を貼り直す。"], "ok": "Console に赤いエラーがない (Clear を押してから確かめる)。"},
        {"title": "Vulkan だけか確かめる", "body": ["Edit → Project Settings → Player → Android のタブ → Other Settings → Graphics APIs。", "Auto Graphics API のチェックが外れていて、一覧が Vulkan だけになっているか見る。"], "ok": "Vulkan だけ。"}]},
    {"title": "Quest で動かす", "steps": [{"title": "Build And Run", "body": ["Build And Run を押す。"], "ok": "Quest 2 の中で美術館が起動する。"}]},
]

CHECKS = ["ビルドが最後まで進む", "Quest 2 で起動する"]

TROUBLE = [("また時間切れになる", "エラーの文の中に「Vulkan」「GLES」など、どの種類の変換かが書いてあれば教えてください。Graphics APIs の画面のスクリーンショットもください。"),
           ("use_dxc についてのエラーが出る", "その赤いエラーの文をそのまま送ってください。"),
           ("ほかの赤いエラーが出る", "Console の赤いエラーの最初の数行のスクリーンショットを送ってください。")]

NEXT = "Quest 2 で起動したら、見えたものと、なめらかさを教えてください。Quest 用に軽くします。"
