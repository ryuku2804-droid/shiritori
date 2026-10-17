"""段階37 (全体を軽くする: 画面の細かさの自動調整) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 37"
STEP_TITLE = "段階37:画面の細かさを FPS に合わせて自動で調整する"

FILES = [
    ("Assets/NightShards/Museum/Scripts/AutoQuality.cs", "新規",
     "画面の細かさを FPS に合わせて自動で上げ下げし、FSR でくっきり引きのばす。MSAA を切る。再生を始めると自動で動く"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "変更",
     "F4 で「自動 → 100% → 75% → 50%」を切りかえ、いまの細かさを表示する"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "中に入ったときのレイの回数を 180 → 140、影を 24 → 16 に減らした"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "そのまま",
     "クリックした所の近く (約 20 m 以内) の鯉だけが、気づいて、秒速 1 m ほどで泳いで近づいてくるようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "そのまま",
     "軽くした: 地面の向きを高さの表から測る・山の木々の陰の計算を省く・歩数を減らす"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "金閣寺の世界の中で池をクリックすると、その場所へ鯉を呼ぶ (ぱしゃぱしゃの音つき)"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "金閣寺の池の水面の高さと「そこが池か」を、ほかのスクリプトから使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「万里の長城」を GreatWall、「日本の庭」を Kinkaku で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "そのまま",
     "写真の眺めを再現: 青空、すきまなく並ぶ石の家、段になった住居の地区、手前の段々畑と石垣、とがったワイナピチュとウチュイピチュ、左右の高い山並み、谷底の川。軽くした"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "そのまま",
     "軽くした: 雲は線が通る塊の範囲だけ調べ、2 回目の計算をやめた。映り込みは少ない歩数。山と人は、近くにいないときは計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "そのまま",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "そのまま",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "エッフェル塔と凱旋門だけを大きく (塔は 2.2 倍・門は 3 倍)。まわりはエトワール広場の石畳を回る車のライトと、シャン・ド・マルスの芝生"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "斜塔だけを大きく (5.5 倍)。正面から見て右へ傾く。足元は大理石の敷石と芝生、鳩"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "そのまま",
     "軽くした: 影は近くだけ細かく・遠くは山の高さの表で、参道の位置の計算を使い回し、霧の計算を半分に"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "つやのある質感・景色を映す水鏡と風のさざ波・夕もやと光の筋・かまどの煙・石垣"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "そのまま",
     "水を透き通らせ、光の筋をやわらかく、粒を控えめに。崖の面をなめらかな岩の層に"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "水の屈折と色の吸収・3 重の波・砂の波紋と海草・くっきりした光の網目・白い砕け波・魚の影・砂浜の質感"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一歩ごとに速さが波打ち、視点が上下・左右に揺れる歩き。足元がすべりやすいと、つるつる滑る"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "そのまま",
     "作品「月下の氷河」。雪の峰・氷河とクレバス・青い氷の崖・月の光の道。仕掛けは氷河の崩落"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "そのまま",
     "作品「オーロラの夜」。凍った湖・雪の森・オーロラのカーテン。仕掛けはオーロラ嵐"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "同じ速くする仕組みを入れた"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "地形の高さを表から読む・上へ抜ける線を早く打ち切る・当たった所だけ正確に合わせ直す"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
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
]

NOTICE = {
    "title": "スクリプトを 1 つ新しく作ります",
    "body": [
        "`Scripts` フォルダで右クリック → **Create > MonoBehaviour Script** (または C# Script)。名前を `AutoQuality` にして、中身を全部置き換えてください。",
        "`PerfDebug.cs` と `DioramaWorld.cs` も貼り直し。組み立て直しはいりません (AutoQuality は再生を始めると自動で動きます)。",
    ],
}

OVERVIEW = ("VR に進む前の準備として、美術館全体を軽くする仕組みを入れました。"
            "ジオラマは、画面の点 1 つずつで計算するので、**描く点の数を減らすのがいちばん効きます**。"
            "そこで、**画面の細かさ (URP の Render Scale) を、FPS に合わせて自動で上げ下げする** ようにしました。"
            "0.5 秒ごとに FPS を見て、目標 (50 fps) より 1 割遅ければ 5% ずつ粗く、2 割以上速ければ 5% ずつ細かくもどします (40%〜100%)。"
            "重い部屋や、ジオラマの中に入ったときだけ粗くなり、軽い所では細かく描きます。"
            "粗く描いた画面は、**FSR** (AMD の、ふちをくっきりさせながら引きのばす方法) で画面の大きさに広げるので、ぼやけにくくなっています。"
            "あわせて、ジオラマには効かず重いだけの **MSAA (ふちのギザギザ取り) を切り**、ジオラマの中に入ったときのレイの回数を 180 → 140、影を 24 → 16 に減らしました。"
            "F4 で「自動 → 100% → 75% → 50%」を切りかえられ、F1 の表示に、いまの細かさが出ます。"
            "URP の設定はファイルそのものなので、再生をやめると元の値にもどします。"
            "この仕組みは、次の Quest 2 単体アプリでも、そのまま使います (VR では目標を 72 fps にします)。")

FLOW = [
    ("自動で始まる", "RuntimeInitializeOnLoadMethod で、再生を始めたときに Auto Quality という見えない物を作る。シーンに置いたり、組み立て直したりしなくてよい"),
    ("細かさの調整", "0.5 秒ごとの平均 FPS で、目標の 0.9 倍より遅ければ 5% 粗く、1.2 倍より速ければ 5% 細かく。間をあけて、行ったり来たりしないようにする"),
    ("引きのばし", "URP の Upscaling Filter を FSR にする。Render Scale が 100% 未満のときだけ働く"),
]

SEE = ["F1 の表示の「F4 細かさ」が、重い所で下がり、軽い所で上がる", "前より FPS が上がっている"]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {"title": "AutoQuality を作る", "body": ["`Scripts` フォルダで右クリック → **Create > MonoBehaviour Script**。名前を `AutoQuality` にして、中身を全部置き換える。"], "ok": "Console に赤いエラーがない。"},
            {"title": "2 つ貼り直す", "body": ["`PerfDebug.cs` と `DioramaWorld.cs` を貼り直す。"], "ok": "Console に赤いエラーがない。"},
        ],
    },
    {
        "title": "確かめる",
        "steps": [
            {"title": "FPS を見る", "body": ["再生して F1 で表示を出し、いろいろな部屋とジオラマの中で、FPS と「F4 細かさ」の数字を見る。"], "ok": "FPS が 45〜50 くらいになり、細かさが自動で変わる。"},
            {"title": "見た目を見る", "body": ["粗くなったときの見た目が気にならないか見る。気になるときは F4 で 100% / 75% にして比べる。"]},
            {"title": "数字を送る", "body": ["重い作品で、細かさが何 % まで下がったかと、そのときの FPS を送ってください。"]},
        ],
    },
]

CHECKS = ["再生すると、F1 の表示に「F4 細かさ 自動」が出る", "重い所で FPS が上がった"]

TROUBLE = [
    ("画面がぼやけすぎる", "F4 で 75% か 100% に切りかえてください。目標の FPS を下げる (例: 40) こともできます。"),
    ("「UpscalingFilterSelection」などのエラー", "その文を送ってください。Unity のバージョンに合わせて直します。"),
]

NEXT = "数字を見て、目標の FPS や下げ幅を合わせます。そのあと、Quest 2 単体アプリ (VR) に進みます。"
