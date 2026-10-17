"""段階30 (漫画のスフィンクス) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 30"
STEP_TITLE = "段階30:スフィンクスを漫画の絵のとおりに"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "スフィンクスを、送ってもらった漫画の絵のスフィンクスにした (橙色のセル塗り・黒い輪郭線・二重の丸い目・困ったまぶた・鼻・口・額の U・耳の C・指の線)"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "スフィンクスの当たり判定を、大きめの頭に合わせた"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "そのまま",
     "地面すれすれの線が届かないときの直しを、同じように入れた"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "砂嵐の音と、塩の結晶が育つ音、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「ギザのピラミッド」を Pyramids、「死海」を DeadSea で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "エッフェル塔と凱旋門だけを大きく (塔は 2.2 倍・門は 3 倍)。まわりはエトワール広場の石畳を回る車のライトと、シャン・ド・マルスの芝生"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "斜塔だけを大きく (5.5 倍)。正面から見て右へ傾く。足元は大理石の敷石と芝生、鳩"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた拡大の倍率で世界を作る (実物の寸法の作品は、もっと大きくして人の大きさに近づける)"),
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
    "title": "2 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた `DioramaPyramids.shader`・`DioramaTerrain.cs` を、中身を全部置き換えてください。組み立て直しはいりません。",
    ],
}

OVERVIEW = ("スフィンクスを、送ってもらった漫画の絵のスフィンクスにしました。ピラミッドはこれまでどおり本物らしいままで、スフィンクスだけが漫画の絵になります。"
            "**形**: 伏せた獅子の、まるくなめらかな体。頭は体より大きめ (1.35 倍) で、まるい頭頂から左右の垂れ布が肩の上へ広がるネメス頭巾。顔はつるんと平らぎみで、両わきに丸い耳。前足はまっすぐ前へのび、先はまるい。"
            "**塗り**: 平らな橙色を、日が当たる所と影の 2 段だけで塗ります (セル塗り)。輪郭は黒い線。"
            "**顔の線**: 二重の丸い目と、まん中の黒い点。内側が上がった、困ったようなななめのまぶた。たての短い鼻と、下の小さなかぎ。くねっとした小さな口。額の「U」。耳の「C」。顔のふちのたての長い線。前足の先には 3 本の指の線。")

FLOW = [
    ("セル塗り", "日の当たり方 (光の向きと面の向き、影) を、なめらかに 2 段に分ける。明るい所はそのままの橙、暗い所は少し赤みのある影の色"),
    ("輪郭線", "面が見る向きに対して横を向いている所 (向きの内積が小さい所) を黒くする。体のふちに、ペンで描いたような線ができる"),
    ("顔の線", "頭の前を向いた面の上で、顔の平面の座標 (メートル) に、丸・線・U の形の距離を測り、近い所を黒くする。頭を大きくした分は、頭の座標にもどしてから測る"),
]

SEE = [
    "スフィンクスが、橙色の漫画の絵になっている",
    "二重の丸い目・困ったまぶた・鼻・口・額の U・耳の C",
    "前足の先の指の線",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "2 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaPyramids.shader`・`DioramaTerrain.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、シェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "スフィンクスの顔",
                "body": ["E で鑑賞して近づくか、クリックで中に入り、スフィンクスの正面に立つ。"],
                "ok": "漫画の顔が見える。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["正面とななめからのスクリーンショットを送ってください。線の太さ・目の大きさ・色は、すぐに合わせられます。"],
            },
        ],
    },
]

CHECKS = [
    "スフィンクスが漫画の絵のようになっている",
    "顔の線が、絵と同じ並びになっている",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("絵とちがう所がある",
     "どこがちがうか (目の大きさ・線の太さ・色・頭の形など) を教えてください。"),
]

NEXT = "スクリーンショットを見て詰めます。そのあと、アンデスの間 (ウユニ塩湖・マチュピチュ) に進みます。"
