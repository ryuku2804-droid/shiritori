"""段階29 (ピラミッドの接地とスフィンクスの細部) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 29"
STEP_TITLE = "段階29:ピラミッドを地面に立たせ、スフィンクスを実物に近づける"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "ピラミッドを地面にしっかり立たせた (地面すれすれの線が届かず、すきまの帯に見えていたのを直す)。スフィンクスを実物の寸法 (m) で作り直し、目・眉・欠けた鼻・唇・耳・ネメス頭巾・尾・夢の碑文まで"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "地面すれすれの線が届かないときの直しを、同じように入れた"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "ピラミッドの下の台の高さを、シェーダーと同じに直した (歩く地面と当たり判定)"),
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
    "title": "3 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた `DioramaPyramids.shader`・`DioramaDeadSea.shader`・`DioramaTerrain.cs` を、中身を全部置き換えてください。",
        "組み立て直しはいりません。",
    ],
}

OVERVIEW = ("**ピラミッドが地面から浮いて見えた原因** は 2 つありました。"
            "1 つ目: 地面すれすれを進む視線は、1 歩がとても小さくなり、決められた回数のうちに地面まで届かず、空の色を出していました。それがピラミッドの足元に、明るいすきまの帯として見えていました。"
            "回数を使い切ったとき、もう地面のすぐそばまで来ていれば、そこを地面として描くようにしました。地面の上の 1 歩も少し大きくしました。"
            "2 つ目: ピラミッドの下の、ならした台が、まわりの砂丘より低く、くぼんでいました。台の高さを砂丘のふつうの高さにそろえました。"
            "さらに、ピラミッドの底の高さを、描いている地面の高さそのもの (中心の真下) に合わせ、いちばん下の段を地面の下 13 m までのばしたので、どこから見ても地面とすきまができません。"
            "ざらざらの砂に空が映りすぎて白く光っていたのも、控えめにしました。"
            "**スフィンクス** は、1 m = 1 の「メートルの座標」で実物の寸法どおりに作り直しました。"
            "顔は幅 4.1 m で、眉、深く彫られたアーモンド形の目 (まぶたと眼球)、付け根だけ残って欠けた鼻 (割れ口はざらざら)、幅 2.3 m の唇と口の線、あご、耳。"
            "顔の細かいくぼみには、近い所だけを調べる陰を付けて、目や唇がくっきり見えるようにしました。顔には赤い顔料のあとがかすかに残ります。"
            "ネメス頭巾は、平らぎみの頭頂、額のふち、聖蛇 (ウラエウス) のあと、下ほど広がる左右の垂れ布 (正面から見ると頭全体が台形)、後ろに垂れる束、横じまの溝。"
            "胴は長さ約 50 m の長い背中で、風に削られた地層が段になり、腰とたたんだ後ろ足、右の腰に巻きつく尾があります。"
            "前足は胸から 15 m 前へのび、先に 4 つの指。前足のあいだには、トトメス 4 世の **夢の碑文** (上の丸い花こう岩の石碑) が立ちます。足元と前足は、あとから修理した明るい石積みです。")

FLOW = [
    ("回数切れの直し", "線を進める回数を使い切ったとき、最後の距離がとても小さければ (遠いほど少し大きく許す)、そこを当たりにする。回数切れのときだけに限るので、ふつうの所は変わらない"),
    ("メートルの座標", "スフィンクスの位置から 0.0011 で割ると、1 = 1 m の座標になる。そこで実物の寸法の数字のまま形を作り、出てきた距離に 0.0011 を掛けて戻す"),
    ("なめらかなつなぎ", "顔・ほお・あご・胸・前足は、なめらかにつなぐ (SMin)。目のくぼみは、なめらかにけずる (SMax)"),
    ("細かい陰", "ふつうの陰 (4 mm ごとに調べる) では目や唇には粗すぎるので、スフィンクスだけ 0.25 mm ごとに 3 回調べる陰を足す"),
]

SEE = [
    "ピラミッドの足元が地面にくっついている (どの向きから見ても、すきまの帯がない)",
    "スフィンクスの目・眉・欠けた鼻・唇・耳",
    "台形のネメス頭巾と横じま、前足のあいだの石碑、右の腰の尾",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "3 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaPyramids.shader`・`DioramaDeadSea.shader`・`DioramaTerrain.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、シェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "ピラミッドの足元",
                "body": ["E で鑑賞し、いろいろな向き・低い角度から、ピラミッドの足元を見る。クリックで中に入り、地面の高さから見る。"],
                "ok": "足元に明るい帯がなく、地面に立っている。",
            },
            {
                "title": "スフィンクスの顔",
                "body": ["中に入り、スフィンクスの正面とななめ前から顔を見る。"],
                "ok": "目・鼻のあと・唇がわかる。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["ピラミッドの足元と、スフィンクスの顔のスクリーンショットを送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "ピラミッドが地面から浮いて見えない",
    "スフィンクスの顔に目・鼻のあと・唇がある",
    "前足のあいだに石碑が立っている",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("まだ足元に帯が見える",
     "どの向き・どの高さから見たときかがわかるスクリーンショットを送ってください。"),
    ("FPS が下がった",
     "F1 の数字を送ってください。スフィンクスの細かい陰を、近くのときだけにして軽くします。"),
]

NEXT = "スクリーンショットを見て詰めます。そのあと、アンデスの間 (ウユニ塩湖・マチュピチュ) に進みます。"
