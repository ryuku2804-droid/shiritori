"""段階48 (作品の世界の中を Quest で軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 48"
STEP_TITLE = "段階48: 作品の世界の中を Quest で軽くする"

FILES = [
    ("Assets/NightShards/Museum/Scripts/QuestQuality.cs", "変更",
     "Quest のとき、シェーダーの _DioramaLite を 1 にする。世界の中の光をたどる回数 (72) と、いちばん粗い細かさ (45%) を決める"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "Quest では、世界の中の光をたどる回数を 140 → 72 に。世界の中にいる間だけ、画面を 45% まで粗くしてよいことにする"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "Quest のときだけ、ブルーム (光のにじみ) とビネット (四隅の暗がり) を切る"),
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "変更",
     "いちばん粗い細かさ (MinScale) を、ほかのスクリプトから変えられるようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "変更",
     "_DioramaLite の入れ物だけ足した (ウユニは影と陰の計算がもともとない)"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "変更",
     "_DioramaLite が 1 (Quest) のとき、影と陰 (AO) を計算しない"),
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
    "title": "スクリプト 3 つと、シェーダー 17 個を貼り直す",
    "body": ["「変更」と書いてある QuestQuality.cs・DioramaWorld.cs・AutoQuality.cs と、17 個の .shader を、中身を全部置き換えてください。組み立て直しはいりません。"],
}

OVERVIEW = ("作品の世界に入るとがくがくするのを、Quest のときだけ軽くしました。パソコンでは今までと同じです。"
            "**なぜ世界の中が重いか**: 世界の中では、ジオラマの箱が自分のまわり全部をおおうので、画面のすべての点で、光をたどる計算 (1 点で最大 140 回) をします。"
            "さらに、当たった所ごとに、影を調べる計算 (十数回) と、すみの暗がり (AO) を調べる計算 (数回) をします。Quest では左右の目のぶん、これが 2 倍です。"
            "**直し方 (Quest のときだけ)**: "
            "① ジオラマの影と陰 (AO) の計算を省く (美術館の中で見るジオラマにも効く)。"
            "② 世界の中で、光をたどる回数を 140 → 72 にする。"
            "③ 世界の中にいる間だけ、画面の細かさを 45% まで下げてよいことにする (美術館では、文字が消えないように 60% まで)。"
            "**見た目の変わり方**: ジオラマに影がなくなり、少し平らに見えます。世界の中では、遠くの景色が少し早めに切れたり、画面が少しぼやけたりすることがあります。")

FLOW = [("再生のはじめ (Quest)", "QuestQuality が Shader.SetGlobalFloat(\"_DioramaLite\", 1)。シェーダーの SoftShadow と AmbientOcclusion は、すぐ 1 (影なし) を返す"),
        ("世界に入る", "DioramaWorld が _Steps を 72 に。AutoQuality.MinScale を 0.45 に"),
        ("世界から出る", "AutoQuality.MinScale を 0.6 にもどす")]

SEE = ["作品の世界の中のがくがくが減る", "ジオラマの影がなくなる (Quest だけ)", "パソコンの再生では見た目が変わらない"]

PHASES = [
    {"title": "ファイルを入れる", "steps": [
        {"title": "貼り直す", "body": ["「変更」のスクリプト 3 つと、17 個の .shader を貼り直す。"], "ok": "Console に赤いエラーがない。"}]},
    {"title": "Quest で動かす", "steps": [{"title": "Build And Run", "body": ["Build And Run を押して、いくつかの作品の世界に入ってみる。"], "ok": "前より、なめらかに動く。"}]},
]

CHECKS = ["世界の中でがくがくしにくい", "遠くの景色がおかしくなっていない"]

TROUBLE = [("まだがくがくする", "どの作品の世界で特に重いかを教えてください。その作品だけ、もっと軽くします。"),
           ("遠くの景色が欠ける・空が見える", "どの作品かを教えてください。その作品だけ、光をたどる回数をもどします。")]

NEXT = "どの作品がまだ重いかを教えてもらえれば、作品ごとに軽くします。"
