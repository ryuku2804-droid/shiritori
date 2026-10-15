"""段階24 (千本鳥居の山を軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 24"
STEP_TITLE = "段階24:千本鳥居の山を軽くする"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "変更",
     "軽くした: 影は近くだけ細かく・遠くは山の高さの表で、参道の位置の計算を使い回し、霧の計算を半分に"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "つやのある質感・景色を映す水鏡と風のさざ波・夕もやと光の筋・かまどの煙・石垣"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "鳥居の柱・灯籠・杉・社・家の当たり判定の場所を、シェーダーと同じ置き方で作る"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
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
    "title": "貼り直すのは DioramaTorii.shader の 1 つだけです",
    "body": ["組み立て直しは要りません。"],
}

OVERVIEW = ("**視界の外は、もともと計算していません**: ジオラマは、画面のピクセル 1 つずつに「この方向に何が見えるか」を計算して描いています (レイマーチング)。"
            "だから、画面に映っていない所は 1 回も計算されていません。重さは「画面に映っているピクセル 1 つあたりに、どれだけ計算するか」で決まります。"
            "そこで、千本鳥居でピクセル 1 つあたりの計算が多かった所を削りました。"
            "**影**: 夕日が低いので、影を調べる線が山を長く横切り、そのあいだずっと鳥居や木を細かく調べていました。"
            "近く (鳥居の柱の影の縞が落ちる範囲) だけを細かく調べ、遠くは山の高さの表だけで大まかに調べるようにしました。"
            "**参道の位置**: 1 点を調べるたびに「らせんの何周目のどこか」を 3 回計算していたのを、1 回にして使い回すようにしました。"
            "**霧**: 霧は細かく調べなくても見た目がほとんど変わらないので、計算の回数を約半分にしました。")

FLOW = [
    ("SoftShadow (影)", "最初の 0.05 (鳥居 2〜3 基ぶん) だけ、鳥居と木を入れて細かく調べる。その先は 0.04 ずつ、山の高さの表と比べるだけ"),
    ("MapX (世界の形)", "PathCoord (らせんの位置) を 1 回だけ計算し、鳥居 (ToriiRow) と杉 (Cedars) に渡す。杉の根元が参道から離れているかも、その値から近似して求める"),
    ("Mist (霧)", "進む回数を、最大 22 → 12 に"),
]

SEE = [
    "千本鳥居の山を見たときの FPS が上がる",
    "見た目 (鳥居の影の縞・霧・木) は、ほとんど変わらない",
]

PHASES = [
    {
        "title": "入れて測る",
        "steps": [
            {
                "title": "貼り直す",
                "body": ["右のタブで ● の付いた `DioramaTorii.shader` を貼り直す。"],
                "ok": "シェーダーの Inspector にエラーがない。",
            },
            {
                "title": "FPS を比べる",
                "body": ["F1 で FPS を出して、千本鳥居の山を外から鑑賞したときと、中に入ったときの FPS を見る。"],
                "ok": "前より高い。",
            },
            {
                "title": "数字を送る",
                "body": ["外から・中からの FPS を送ってください。まだ低ければ、さらに削ります。"],
            },
        ],
    },
]

CHECKS = [
    "FPS が前より上がっている",
    "鳥居の影の縞が、今まで通りに見える",
]

TROUBLE = [
    ("まだ重い",
     "外から・中から、それぞれの FPS と、F4 で解像度を下げたときの FPS を教えてください。次は、ジオラマだけを少し低い解像度で描いて拡大する方法を入れます。"),
    ("遠くの影が消えた・おかしい",
     "スクリーンショットを送ってください。"),
]

NEXT = "FPS を見て、必要ならさらに軽くします。そのあと、ほかの部屋にもつやのある質感を広げるか、世界の部屋に進みます。"
