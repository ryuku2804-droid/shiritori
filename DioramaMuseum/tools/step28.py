"""段階28 (砂漠と塩の間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 28"
STEP_TITLE = "段階28:砂漠と塩の間「ギザのピラミッド」と「死海」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "新規",
     "作品「ギザのピラミッド」。実物の寸法と地図の並びで、三大ピラミッド・王妃のピラミッド・大スフィンクス・ラクダの隊列。仕掛けは砂嵐と、そのあとの赤い夕日"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "新規",
     "作品「死海」。白い塩の岸・青緑の浅瀬・塩のきのこ・浮かんで新聞を読む人・モアブの山並み。仕掛けは岩塩の結晶が育つ"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "ピラミッドと死海の地面・立つ場所・当たり判定・拡大の倍率を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "砂嵐の音と、塩の結晶が育つ音、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
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
    "title": "シェーダーを 2 つ新しく作ります",
    "body": [
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaPyramids` と `DioramaDeadSea` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直すと、砂漠と塩の間の仮の箱が、新しい作品に変わります。",
        "台座の説明文が古いままなら、**設計図を初期設定に戻して組み立てる** を使ってください (部屋の並びを変えていなければ、見た目は同じです)。",
    ],
}

OVERVIEW = ("世界の部屋の 2 つ目、砂漠と塩の間の 2 作品です。"
            "**ギザのピラミッド** は 1 m = 0.0011 の実物の寸法で、並びは実物の地図の位置 (緯度・経度) から決めました (間の距離だけ 0.77 倍に詰めています)。美術館の正面が東です。"
            "**クフ王のピラミッド** は底辺 230 m・今の高さ 139 m で、頂上は平ら。元の頂点の高さを示す目印の柱が立ち、北の面に入口、東に 3 つの王妃のピラミッド。"
            "**カフラー王のピラミッド** は 10 m 高い岩盤の上に立つのでいちばん高く見え、頂上になめらかな化粧石が残ります。"
            "**メンカウラー王のピラミッド** は下の段が赤い花こう岩で、南に 3 つの王妃のピラミッド。"
            "石は約 1.5 m の段に積まれていて、近くで見ると階段のようにギザギザで、石ごとに色が少しずつ違います。"
            "手前の **大スフィンクス** (長さ 73 m・高さ 20 m) は東を向き、掘り下げた岩の囲いの中に伏せています。ネメス頭巾、前にのびる前足、地層の横縞まで作りました。"
            "砂丘には風紋があり、ラクダの隊列がゆっくり横切ります。"
            "Space で、**西から砂嵐が吹き抜けてピラミッドがかすみ、過ぎ去ると夕日がいっそう強く赤く差します**。"
            "**死海** は 1 m = 0.012 です。美術館の正面がイスラエル側の岸で、奥がヨルダン側。"
            "手前は塩が固まった白い岸で、乾いた所は六角形のひび割れ模様。浅瀬は白い塩の底が透けて明るい青緑、沖へ行くほど深い青緑になります。"
            "浅瀬には、エン・ボケックの名物の **塩のきのこ** が 9 つ。ぼこぼこした白い塩のかたまりで、水面の高さに塩のふちが張り出しています。"
            "沖には **仰向けに浮かんで新聞を読む人**。水はとても静かで、向こう岸の **モアブの山並み** (赤茶色の地層の縞) を鏡のように映します。"
            "Space で、**立方体の岩塩の結晶が、水の中から 1 つずつせり上がって育ち、日を受けてきらめきます**。")

FLOW = [
    ("石の段 (Pyramids)", "ピラミッドを 1.5 m ごとの段 (箱) に分け、今の高さの段と上下の段だけを調べる。遠い所は、なめらかな四角すいの距離で早く進む"),
    ("並び (Pyramids)", "4 つの名所の緯度・経度を、クフ王からの東西・南北の距離 (m) に直して置いた。地面は西ほど高い台地で、ピラミッドの下だけ平らにならす"),
    ("砂嵐 (Pyramids)", "視線にそって 12 か所で砂の濃さ (流れるノイズ) を調べ、光を足しながら向こうを隠していく。仕掛けの前半は砂嵐、後半は日差しを強く赤くする"),
    ("水 (DeadSea)", "物の形には水を入れず、地面 (水の底) まで進む。水面を通った線は、水の中を進んだ長さで赤から先に吸われて青緑になる。映り込みは、はね返った線で山ときのこをもう一度たどる"),
    ("結晶 (DeadSea)", "きのこのまわりに 5 つずつ、少し傾けた立方体を置き、1 つずつ時間をずらして水の中から持ち上げる"),
]

SEE = [
    "ピラミッド: 段々の石の積み方、カフラー王の頂上の化粧石、クフ王の頂上の目印の柱",
    "ピラミッド: 掘り下げた囲いの中のスフィンクス、ラクダの隊列",
    "ピラミッドで Space: 砂嵐で一面かすみ、過ぎると赤い夕日",
    "死海: 透き通った浅瀬、塩のきのこ、浮かんで新聞を読む人、水に映る山並み",
    "死海で Space: 岩塩の結晶が水から育ってきらめく",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaPyramids` にして、中身を全部置き換える。",
                    "同じように `DioramaDeadSea` を作って、中身を置き換える。",
                ],
                "ok": "2 つのシェーダーの Inspector に、エラーが出ていない。",
            },
            {
                "title": "スクリプトを 3 つ貼り直す",
                "body": ["右のタブで ● の付いた `DioramaTerrain.cs`・`DioramaWork.cs`・`MuseumLayout.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "砂漠と塩の間の 2 つの台座が、ピラミッドと死海のジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "ギザのピラミッド",
                "body": ["E で鑑賞し、Space で砂嵐を起こす。クリックで中に入り、スフィンクスの前からピラミッドまで歩く。"],
                "ok": "砂嵐で一面かすみ、過ぎると夕日が赤く差す。",
            },
            {
                "title": "死海",
                "body": ["E で鑑賞し、Space で結晶を育てる。クリックで中に入り、岸から浅瀬へ歩いて塩のきのこに近づく。"],
                "ok": "水が透き通り、結晶が水の中から育つ。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "ピラミッドが 3 つと王妃のピラミッド、スフィンクスが見える",
    "ピラミッドで Space: 砂嵐 → 赤い夕日",
    "死海の浅瀬が透けて、塩のきのこと浮かぶ人が見える",
    "死海で Space: 岩塩の結晶が育つ",
    "どちらもクリックで中に入れる (ピラミッドとスフィンクス、塩のきのこにはぶつかる)",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("台座が仮の箱のまま",
     "Console に「NightShards/Diorama/Pyramids (または DeadSea) が見つからない」と出ていないか見てください。シェーダーの名前 (1 行目の Shader \"...\") が合っているかも確かめてください。"),
    ("FPS が下がった",
     "F1 の数字と、どの作品を見ていたかを送ってください。砂嵐や映り込みの細かさを下げて軽くします。"),
]

NEXT = "スクリーンショットを見て、2 作品を詰めます。そのあと、アンデスの間 (ウユニ塩湖・マチュピチュ) に進みます。"
