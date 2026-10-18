"""段階47 (Quest 用の軽い画質) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 47"
STEP_TITLE = "段階47: Quest のときだけ軽い画質にする"

FILES = [
    ("Assets/NightShards/Museum/Scripts/QuestQuality.cs", "新規",
     "Quest のときだけ: ライトの影・SSAO を切り、1 つの物を照らすライトを 4 つまでにする。パソコンでは何もしない"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "変更",
     "Quest のときだけ、ブルーム (光のにじみ) とビネット (四隅の暗がり) を切る"),
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "変更",
     "Quest では画面の細かさを 70% から始める"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "そのまま",
     "#pragma use_dxc vulkan を足した (Quest 用は新しいコンパイラーで変換する)。ループの [loop] はそのまま"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
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
    "title": "1 つ新しく入れて、2 つ貼り直す",
    "body": ["`QuestQuality.cs` を Scripts フォルダに新しく作り、`MuseumPost.cs` と `AutoQuality.cs` を貼り直してください。組み立て直しはいりません。"],
}

OVERVIEW = ("Quest 2 で動かしたとき、がくがくしていたので、Quest のときだけ軽い画質にしました。パソコンやエディターの再生では、今までと同じです。"
            "**いちばん重かったもの**: 美術館のスポットライトの影です。影は、ライト 1 つごとに、そのライトから見た場面をもう一度描いて作ります。影つきのライトが 7 つ見えていると、場面を 8 回描くのと同じです。"
            "Quest では、さらに左右の目のぶん 2 倍になります。"
            "**切ったもの**: ライトの影、SSAO (すみの暗がり)、ブルーム (光のにじみ)、ビネット (四隅の暗がり)。どれも画面全体をもう一度なぞる処理です。"
            "1 つの物を照らすライトは 4 つまでにしました。"
            "**残したもの**: トーンマップ (明るさの階調)。これを切ると画面が白くとびます。"
            "画面の細かさは 70% から始めて、AutoQuality が 72 fps に合わせて上げ下げします。")

FLOW = [("Quest で再生を始めたとき", "QuestQuality がライトの影・SSAO を切る。Console (adb logcat) に「Quest 用の軽い画質」と出る"),
        ("MuseumPost", "Quest ならブルームとビネットの強さを 0 にする"),
        ("AutoQuality", "Quest なら 70% から始めて、72 fps を目標に上げ下げ")]

SEE = ["美術館の中を歩いたときのがくがくが減る", "影がなくなる (床に落ちるスポットライトの影など)", "パソコンの再生では見た目が変わらない"]

PHASES = [
    {"title": "ファイルを入れる", "steps": [
        {"title": "入れる・貼り直す", "body": ["`QuestQuality.cs` を新しく作り、`MuseumPost.cs` と `AutoQuality.cs` を貼り直す。"], "ok": "Console に赤いエラーがない。"}]},
    {"title": "Quest で動かす", "steps": [{"title": "Build And Run", "body": ["Build And Run を押す (2 回目なので、前よりずっと速く終わるはず)。"], "ok": "前より、なめらかに動く。"}]},
]

CHECKS = ["ドームの中を歩いてもがくがくしにくい", "部屋の中でもがくがくしにくい"]

TROUBLE = [("まだがくがくする", "どこでがくがくするか (ドーム・通路・部屋・作品の世界の中) を教えてください。場所によって、次にやること (ジオラマの計算を減らす・遠くのジオラマを写真にする・世界の中を軽くする) が変わります。")]

NEXT = "まだ重い場所を教えてもらえれば、そこに合わせて ②〜④ の方法で軽くします。"
