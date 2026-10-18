"""段階39 (VR の操作) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 39"
STEP_TITLE = "段階39:VR の操作 (Quest 2 で歩く・見る・中に入る)"

FILES = [
    ("Assets/NightShards/Museum/Scripts/VRSupport.cs", "新規",
     "VR のコントローラーの入力 (VRInput) と、頭の動きをカメラに写す VRRig。A ボタンで近くの作品の仕掛け。Quest のフォービエイテッド。再生すると自動で動く"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "変更",
     "左スティックで歩く・押しこみで走る・トリガーでクリック・B ボタンで E と同じ、を足した"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "変更",
     "VR: 右スティックで 30 度ずつ向きを変える・頭の向きへ歩く・視点の揺れとジャンプを止める"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "変更",
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
    "title": "スクリプトを 1 つ新しく作り、3 つ貼り直して、Quest 2 に書き出します",
    "body": [
        "`Scripts` フォルダで **Create > MonoBehaviour Script**。名前を `VRSupport` にして、中身を全部置き換えてください。",
        "`MuseumInput.cs`・`FirstPersonController.cs`・`ExhibitViewer.cs` を貼り直し。組み立て直しはいりません。",
        "パソコンでは、これまでどおりキーボードとマウスで動きます (VR の機器がつながっていないときは、VR の部分は何もしません)。",
    ],
}

OVERVIEW = ("Quest 2 のコントローラーで、美術館を歩いて、作品の中に入れるようにしました。"
            "**頭の動き**: 頭の位置と向きを、そのままカメラに写します。はじめの頭の位置が、美術館の目の高さになるので、立っていても座っていても使えます。"
            "**左スティック**: 頭の向いている方へ歩く (押しこむと走る)。**右スティック**: 左右に倒すと 30 度ずつ向きを変える (なめらかに回ると酔いやすいため)。"
            "**トリガー**: クリックと同じ。美術館では、近くの作品を見て引くと、その作品の中に入る。中では仕掛けを動かす (金閣寺の池なら鯉を呼ぶ)。"
            "**A ボタン**: 美術館で、いちばん近い作品の仕掛けを動かす (鑑賞モードの Space のかわり)。**B ボタン**: 作品の中から美術館に戻る (E と同じ)。"
            "VR では、鑑賞モード (カメラが作品のまわりを回る) は使いません。作品に近づいて、自分の頭でのぞきこんで見ます。"
            "酔わないように、歩くときの視点の揺れと、ジャンプは止めました。"
            "**軽くする**: Quest の画面のまわりを少し粗く描く「フォービエイテッド」を入れ、画面の細かさの自動調整 (AutoQuality) の目標を 72 fps にしました。"
            "**まだできていないこと**: 画面の上に出す文字 (「E で鑑賞」などの案内) と、中に入るときの白い光・暗転は、VR ではまだ見えません。"
            "また、ジオラマはまだ Quest には重すぎるはずです。まず動くことを確かめて、次の段階で Quest 用に軽くします。")

FLOW = [
    ("コントローラー", "Unity の XR の入力 (InputDevices) で、左右のコントローラーのスティックとボタンを 1 フレームに 1 回読み、押した瞬間・離した瞬間を出す"),
    ("MuseumInput への読みかえ", "左スティックは WASD に、トリガーは左クリックに、B は E に足し合わせる。ほかのスクリプトは、キーボードかコントローラーかを知らなくてよい"),
    ("頭", "頭の位置と向きを、目の高さの位置 (cameraPivot) からの動きとしてカメラに入れる。描く直前 (onBeforeRender) にもう一度入れて、遅れを減らす"),
]

SEE = ["Quest 2 で、頭を動かすと見回せる", "左スティックで歩き、右スティックで向きを変えられる", "トリガーで作品の中に入り、B で戻れる"]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {"title": "VRSupport を作る", "body": ["`Scripts` フォルダで **Create > MonoBehaviour Script**。名前を `VRSupport` にして、中身を全部置き換える。"], "ok": "Console に赤いエラーがない。"},
            {"title": "3 つ貼り直す", "body": ["`MuseumInput.cs`・`FirstPersonController.cs`・`ExhibitViewer.cs` を貼り直す。"], "ok": "パソコンで Play して、いつもどおり動く。"},
        ],
    },
    {
        "title": "Quest 2 で動かす",
        "steps": [
            {"title": "書き出す", "body": [
                "Quest 2 を USB-C でつなぎ、**File > Build Profiles** の Android で、Run Device に Quest 2 を選ぶ。",
                "**Scene List** に美術館のシーンが入っているか確かめる (入っていなければ、Add Open Scenes)。",
                "**Build And Run** を押す。はじめは 10〜30 分ほどかかる (シェーダーの準備に時間がかかる)。"],
              "ok": "Quest 2 の中で、美術館が表示される。"},
            {"title": "動かしてみる", "body": ["頭を動かして見回し、左スティックで歩き、作品の前でトリガーを引いて中に入り、B で戻る。"], "ok": "見回し・歩き・入る・戻るができる。"},
            {"title": "知らせる", "body": ["動いたかどうかと、なめらかさ (かくかくするか) を教えてください。エラーで書き出せないときは、Console の赤い文を送ってください。"]},
        ],
    },
]

CHECKS = ["パソコンでは、これまでどおり動く", "Quest 2 で見回せる・歩ける・中に入れる"]

TROUBLE = [
    ("Build で「Gradle」や「SDK」のエラー", "Console の赤い文をそのまま送ってください。"),
    ("Quest 2 の中が真っ黒・ずっと読み込み中", "はじめはシェーダーの準備にとても時間がかかります。数分待っても変わらなければ、教えてください。"),
    ("片目だけ映る・立体に見えない", "XR Plug-in Management > OpenXR の Render Mode が Single Pass Instanced \\ Multi-view になっているか確かめてください。"),
]

NEXT = "動いたら、次は Quest 用に軽くします (ジオラマを Quest のときだけ簡単にする)。あわせて、案内の文字と、入るときの光・暗転を VR でも見えるようにします。"
