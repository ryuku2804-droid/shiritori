"""段階38 (VR の準備) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 38"
STEP_TITLE = "段階38:VR (Quest 2 単体アプリ) の準備"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "変更",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "そのまま",
     "画面の細かさを FPS に合わせて自動で上げ下げし、FSR でくっきり引きのばす。MSAA を切る。再生を始めると自動で動く"),
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
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一歩ごとに速さが波打ち、視点が上下・左右に揺れる歩き。足元がすべりやすいと、つるつる滑る"),
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
    "title": "シェーダーを 20 本貼り直し、Unity に VR の部品を入れます",
    "body": [
        "右のタブで ● の付いたシェーダー (20 本) を、中身を全部置き換えてください。中身は、各シェーダーのフラグメントの最初に 1 行足しただけです。",
        "そのあと、左の手順で Unity に Android と VR の部品を入れます。**まだ Build (Quest への書き出し) はしません**。操作のスクリプトは次の段階です。",
    ],
}

OVERVIEW = ("Quest 2 単体のアプリにするための準備です。"
            "**シェーダー**: VR では、左右の目の 2 枚を 1 回でまとめて描きます (Single Pass Instanced / Multiview)。"
            "ジオラマはカメラ (目) の位置から線を飛ばして描くので、いま左右どちらの目を描いているかを知らないと、両目とも同じ位置から描いてしまい、立体に見えません。"
            "そこで、すべてのシェーダーのフラグメントの最初に `UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);` を足しました。これで、カメラの位置 (GetCameraPositionWS) が、描いている目の位置になります。ふつうの画面では、この行は何もしません。"
            "**Unity の準備**: Quest 2 は Android で動くので、Android のビルドの部品と、VR の部品 (XR Plugin Management と OpenXR) を入れ、Quest 用の設定をします。"
            "Quest 2 は開発者モードにして、パソコンと USB-C ケーブルでつなぎます (書き出したアプリを入れるため)。")

FLOW = [
    ("左右の目", "VR では、1 回の描画で 2 枚を描き、頂点の段階で「どちらの目か」が決まる。フラグメントでそれを受け取ると、_WorldSpaceCameraPos がその目の位置に切りかわる"),
    ("OpenXR", "VR 機器の共通の決まり。Meta Quest Support を入れると、Quest 用のアプリとして書き出せる。コントローラーの入力は、Unity の XR の入力 (InputDevices) で読む"),
]

SEE = ["シェーダーを貼り直しても、ふつうの画面の見た目は変わらない", "Project Settings に XR Plug-in Management が出ている"]

PHASES = [
    {
        "title": "シェーダーを貼り直す",
        "steps": [
            {"title": "20 本貼り直す", "body": ["右のタブで ● の付いたシェーダーを、全部貼り直す。"], "ok": "Play して、見た目が前と変わらない。エラーが出ていない。"},
        ],
    },
    {
        "title": "Unity に部品を入れる",
        "steps": [
            {"title": "Android の部品", "body": [
                "Unity を閉じて、**Unity Hub → インストール → 6000.3.6f1 の歯車 → モジュールを加える**。",
                "**Android Build Support** に、その下の **OpenJDK** と **Android SDK & NDK Tools** も含めてチェックを入れて、インストールする (数 GB あり、時間がかかる)。"],
              "ok": "インストールが終わり、Unity をもう一度開ける。"},
            {"title": "VR の部品", "body": [
                "**Edit > Project Settings > XR Plug-in Management** を開き、**Install XR Plugin Management** を押す。",
                "Android のタブ (ロボットの印) で **OpenXR** にチェックを入れる (OpenXR の部品が入る)。",
                "左の **XR Plug-in Management > OpenXR** の Android のタブで、Enabled Interaction Profiles の + から **Oculus Touch Controller Profile** を足し、OpenXR Feature Groups の **Meta Quest Support** にチェックを入れる。",
                "同じ画面の **Render Mode** を **Single Pass Instanced \\ Multi-view** にする。",
                "黄色い ⚠ が出ていたら、押して **Fix All** で直す。"],
              "ok": "Android のタブで OpenXR と Meta Quest Support にチェックが付いている。"},
            {"title": "Android に切りかえる", "body": [
                "**File > Build Profiles** (または Build Settings) で **Android** を選び、**Switch Platform** を押す (全部の作り直しで、かなり時間がかかる)。",
                "**Player Settings > Other Settings** で、Scripting Backend を **IL2CPP**、Target Architectures を **ARM64** だけ、Graphics APIs を **Vulkan** だけ (OpenGLES3 は消す) にする。"],
              "ok": "切りかえ後も Play で、パソコンの画面でいつもどおり動く。"},
        ],
    },
    {
        "title": "Quest 2 の準備",
        "steps": [
            {"title": "開発者モード", "body": [
                "スマホの **Meta Horizon** アプリで、Quest 2 の **開発者モード** をオンにする (はじめてなら、開発者の登録が必要)。",
                "Quest 2 をパソコンと USB-C ケーブルでつなぎ、Quest の中に出る「USB デバッグを許可しますか」で **許可** を押す。"],
              "ok": "Build Profiles の Android で、Run Device に Quest 2 が出る。"},
            {"title": "知らせる", "body": ["ここまでできたら、「できた」と送ってください。エラーや ⚠ が残っていたら、その文を送ってください。"]},
        ],
    },
]

CHECKS = ["シェーダーを貼り直しても見た目が変わらない", "OpenXR と Meta Quest Support が入っている", "Android に切りかえても Play できる", "Run Device に Quest 2 が出る"]

TROUBLE = [
    ("Switch Platform のあと、ジオラマがピンク", "そのシェーダーを選んだときの Inspector のエラーの文を送ってください。Android (Vulkan) 向けに直します。"),
    ("Run Device に Quest 2 が出ない", "ケーブルが充電だけのものでないか、Quest の中で USB デバッグを許可したか確かめてください。"),
]

NEXT = "次は操作です。頭の動きで見回し、左スティックで歩く・右スティックで向きを変える・トリガーで中に入る、などを作り、Quest 2 で動かします。"
