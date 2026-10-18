"""段階40 (Android に切りかえたら画面がまっ白) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 40"
STEP_TITLE = "段階40:Android に切りかえたら画面がまっ白になるのを直す"

FILES = [
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "変更",
     "いまの画質の URP の設定で HDR が切れていたら、再生中だけ入れて、Console に知らせる (画面がまっ白になるのを防ぐ)"),
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
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
     "VR: 左右どちらの目を描いているかを受け取る 1 行を足した (ふつうの画面では何も変わらない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
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
    "title": "画質の設定を、PC と同じにします",
    "body": [
        "まず左の手順 1 で、Android の画質を PC と同じにしてください。これがいちばんの直し方です。",
        "念のため `AutoQuality.cs` も貼り直してください (HDR が切れていたら、再生中だけ入れて知らせます)。",
    ],
}

OVERVIEW = ("動画では、シーンビューの美術館は形があるのに、ゲーム画面がまっ白で、ほこりの粒だけが黒く見えていました。"
            "**原因 (たぶん)**: Android に切りかえると、Unity は画質を、Android 用の「Mobile」(URP の設定 Mobile_RPAsset) に切りかえます。"
            "Mobile の設定は、軽くするために **HDR (1 より明るい色を扱うこと) と、仕上げの色の整え (ポストプロセス)** が切れていることが多く、"
            "美術館はスポットライトやジオラマがとても明るい色で描かれ、仕上げの ACES トーンマッピングでちょうどよい明るさにしているので、それが切れると、ほとんどの所がまっ白にとびます。"
            "シーンビューの白いもやの球も、同じ理由です。"
            "**直し方**: Android の画質を、パソコンで使っていた「PC」の画質にします。Quest 用の軽量化は、このあと別のやり方 (自動の細かさ・フォービエイテッド・ジオラマの簡略化) で入れるので、ここで Mobile の画質にする必要はありません。")

FLOW = [
    ("画質 (Quality)", "Project Settings > Quality の表で、プラットフォームごとに、どの画質を使うか (緑のチェック) が決まっている。画質ごとに、使う URP の設定ファイルが違う"),
    ("HDR", "HDR が切れていると、色は 0〜1 にけずられてから仕上げをするので、明るい所は全部白になる"),
]

SEE = ["Android のままでも、Play するとパソコンと同じ見た目になる"]

PHASES = [
    {
        "title": "直す",
        "steps": [
            {"title": "1. Android の画質を PC にする", "body": [
                "**Edit > Project Settings > Quality** を開く。",
                "上の表の **Levels** で、いちばん上の行に「PC」(または High Fidelity など、いままで使っていた画質) と「Mobile」がある。",
                "表の右のほうの **Android のロボットの印の列** の下に、Default を選ぶ ▼ がある。それを **PC** にする (緑のチェックが PC の行に付く)。",
                "PC の行をクリックして選び、下の **Render Pipeline Asset** が PC_RPAsset (パソコンで使っていたもの) になっているか見る。"],
              "ok": "Android の列の緑のチェックが PC の行に付いている。"},
            {"title": "2. AutoQuality を貼り直す", "body": ["`AutoQuality.cs` を貼り直す。"], "ok": "Console に赤いエラーがない。"},
            {"title": "3. 確かめる", "body": ["Play して、パソコンの画面でいつもどおりに見えるか確かめる。Console に「HDR が切れていたので」という黄色い文が出たら、手順 1 がまだ効いていない。"], "ok": "まっ白にならない。"},
            {"title": "4. Quest 2 で", "body": ["直ったら、もう一度 Build And Run して、Quest 2 で動くか見る。"]},
        ],
    },
]

CHECKS = ["Play しても画面がまっ白にならない", "Android の画質が PC になっている"]

TROUBLE = [
    ("PC の画質にしても白い", "Console の黄色い文と、Project Settings > Quality の画面のスクリーンショットを送ってください。"),
    ("PC の画質の行がない", "Quality の Levels の画面のスクリーンショットを送ってください。"),
]

NEXT = "Quest 2 で動いたら、Quest 用に軽くします。"
