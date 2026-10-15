"""段階23 (夕の間のクオリティを上げる) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 23"
STEP_TITLE = "段階23:夕の間のクオリティを上げる (つやのある質感・水鏡・光の筋・当たり判定)"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "変更",
     "つやのある質感・景色を映す水鏡と風のさざ波・夕もやと光の筋・かまどの煙・石垣"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "変更",
     "つやのある朱塗りと石の質感・くっきりした影 (鳥居の縞)・霧の輝き・すり減った石段と苔"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "鳥居の柱・灯籠・杉・社・家の当たり判定の場所を、シェーダーと同じ置き方で作る"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "世界の中に、当たり判定 (柱・木・建物) を置く"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "里の夜の音 (鐘・カエル・コオロギ)・神社の音 (風と鈴) と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「黄昏の棚田」を Terraces、「千本鳥居の山」を Torii で描くようにした"),
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
]

NOTICE = {
    "title": "貼り直すのは 4 つです",
    "body": ["シェーダー 2 つ (`DioramaTerraces`・`DioramaTorii`) と、スクリプト 2 つ (`DioramaTerrain`・`DioramaWorld`)。組み立て直しは要りません。"],
}

OVERVIEW = ("**質感**: これまでは「光が当たる向きか」だけで明るさを決めていたので、どれも粉っぽいマットな見た目でした。"
            "今回から、材質ごとに「つるつる〜ざらざら」と「映り込みの強さ」を決め、本物の物の光り方に近い式 (光の照り返しの広がり方と、ななめから見るほど強く映る性質) で塗ります。"
            "朱塗りの鳥居はつやつやで夕日と空がつやに映り、石灯籠は少しざらっと、わらの屋根は粗く光らず、木の壁はしっとり。"
            "杉の葉や草や障子は、逆光で光が透けて明るく見えます。表面には細かい凹凸の陰影も入ります。"
            "**黄昏の棚田**: 田んぼの水面に、空だけでなく山・あぜ・森が逆さに映ります。風が通るたび、さざ波が田んぼから田んぼへ渡っていきます。"
            "斜面をただよう夕もやに、山と森のすき間を抜けた夕日が光の筋になって差し、家からはかまどの煙が立ちのぼります。段の急な所は苔むした石垣になりました。"
            "**千本鳥居の山**: 影をくっきりさせたので、鳥居のすき間から差す夕日が、石段に光と影の縞を作ります。霧は夕日のほうを向くと輝き、石段は真ん中がすり減ってなめらかに、端に苔。"
            "**当たり判定**: 中に入ったとき、鳥居の柱 (約 1100 本)・石灯籠・杉・山頂の社・里の家にぶつかります。")

FLOW = [
    ("Surface (質感の式)", "日の光の照り返し (つるつるほど小さく強い)、ななめから見るほど強くなる映り込み、空の上と地平線の色で照らすまわりの光、逆光で透ける光、の 4 つを足す"),
    ("BumpNormal (細かい凹凸)", "ノイズの坂の向きで、面の向きを少しゆらす。石・わら・葉・草の手ざわりの陰影になる"),
    ("ReflectTerrain (水鏡)", "田んぼの水面で反射した線を、地形と森の高さを相手に進める。当たれば山や森の色、当たらなければ空"),
    ("Mist (夕もや)", "地面のすぐ上のもやと、家の屋根からの煙。夕日が届くかを地形で調べ、届く所だけ明るくして、光の筋にする"),
    ("ぶつかる物 (C#)", "シェーダーと同じ式で、鳥居の位置 (道の長さから逆算)・杉の位置 (同じ乱数)・家と社の位置を計算し、世界に入るときに見えない柱や箱を置く"),
]

SEE = [
    "朱の鳥居がつやつやして、夕日と空の色がつやに映る",
    "杉や草が逆光で透けて光る。石やわらは、ざらっとした手ざわりに見える",
    "棚田の水面に、山や森が逆さに映り、風のさざ波が渡っていく",
    "棚田の上に夕もやがただよい、光の筋が差し、家から煙が立つ",
    "鳥居のトンネルの石段に、光と影の縞ができる",
    "中に入ると、鳥居の柱や木や家にぶつかる",
]

PHASES = [
    {
        "title": "入れて見る",
        "steps": [
            {
                "title": "4 つを貼り直す",
                "body": ["右のタブで ● の付いたシェーダー 2 つとスクリプト 2 つを貼り直す。"],
                "ok": "Console と 2 つのシェーダーの Inspector にエラーがない。",
            },
            {
                "title": "外から見る",
                "body": ["夕の間の 2 作品を E で鑑賞し、ホイールで近づいて、つや・水鏡・もや・鳥居の影の縞を見る。"],
                "ok": "マットではなく、つやと透け感がある。",
            },
            {
                "title": "中に入る",
                "body": ["千本鳥居の山に入り、トンネルを歩いて登る。柱にぶつかってみる。棚田にも入ってみる。"],
                "ok": "柱・灯籠・杉・社・家にぶつかる。石段に光と影の縞がある。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["外からと中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "鳥居や木の壁に、つやと映り込みがある",
    "棚田の水面に山や森が映る",
    "もやと光の筋、かまどの煙が見える",
    "鳥居のトンネルに影の縞ができる",
    "中で柱や木や家にぶつかる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("つやが強すぎる・ぎらぎらする",
     "材質ごとのつやの値を調整します。スクリーンショットを送ってください。"),
    ("中で見えない壁にぶつかる・柱をすり抜ける",
     "当たり判定の場所が、見た目とずれています。どこで起きたか教えてください。"),
    ("重くなった",
     "質感の計算と水鏡で、少し重くなります。FPS を送ってください。"),
]

NEXT = "このつやのある質感を、ほかの部屋のジオラマにも広げられます。そのあと、世界の部屋に進みます。"
