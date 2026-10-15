"""段階22 (夕の間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 22"
STEP_TITLE = "段階22:夕の間「黄昏の棚田」と「千本鳥居の山」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "新規",
     "作品「黄昏の棚田」。夕焼けを映す棚田・あぜ・杉の森・かやぶきの家。仕掛けは夜になって灯と蛍"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "新規",
     "作品「千本鳥居の山」。らせんに登る約 600 基の鳥居のトンネル・石灯籠・山頂の社・霧。仕掛けは霧が晴れて灯籠に火"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "棚田と鳥居の山の地形 (歩く地面と立つ場所) を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "里の夜の音 (鐘・カエル・コオロギ)・神社の音 (風と鈴) と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「黄昏の棚田」を Terraces、「千本鳥居の山」を Torii で描くようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "そのまま",
     "水を透き通らせ、光の筋をやわらかく、粒を控えめに。崖の面をなめらかな岩の層に"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "水の屈折と色の吸収・3 重の波・砂の波紋と海草・くっきりした光の網目・白い砕け波・魚の影・砂浜の質感"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "世界の中で、氷の上だけすべりやすくする。美術館に戻ったら元に戻す"),
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
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaTerraces` と `DioramaTorii` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直してください。",
    ],
}

OVERVIEW = ("夕の間の 2 作品です。**黄昏の棚田**: 奥へ高くなる山の斜面を段々に切って、水を張った棚田が重なります。"
            "田んぼのひとつひとつの水面が、夕焼けの空を映す鏡になり、水面からは稲の苗が点々と出ています。段のふちには草のあぜ、段の間は土の土手、"
            "斜面の上は杉の森、手前の平らな里には、かやぶき屋根の家が 4 軒。Space で**日が沈んで夜**になり、家の障子に灯がともり、"
            "田んぼの上を蛍が舞い、水面に星が映ります (お寺の鐘のあと、カエルとコオロギの声)。"
            "**千本鳥居の山**: 杉の森におおわれた山のまわりを、石段の参道が 2 周と少し、らせんに巻いて山頂まで登ります。"
            "参道には朱の鳥居が約 600 基、すき間なく並んでトンネルになり (黒い笠木と柱の根元)、12 基ごとに石灯籠。山頂には朱の社、中腹には霧の帯。"
            "Space で**霧が晴れ**、夕日が強く差して、灯籠に火がともり、鳥居のトンネルが金色に輝きます (風の音の中で、鈴が鳴る)。")

FLOW = [
    ("棚田 (Terraces)", "なめらかな斜面の高さを 0.022 ごとに区切って段にする。段の平らな所が田んぼ (空を映す水面)、外側のふちにあぜを盛る"),
    ("夜 (Terraces)", "仕掛けで 6 秒かけて夜へ: 日の光を消し、空を星空へ。障子に灯、蛍は田んぼの上をふわふわ漂って明滅する"),
    ("らせんの参道 (Torii)", "ある点が、らせんの何周目のどこに近いかを、角度と半径から計算する。そこから「道に沿った長さ」で、いちばん近い鳥居 1 基だけを描く (600 基あっても軽い)"),
    ("鳥居 (Torii)", "柱 2 本・反り上がった笠木・島木・貫。朱塗りのつや。笠木と柱の根元は黒"),
    ("霧 (Torii)", "山の中腹の 2 つの高さに、帯のような霧。仕掛けで薄くなって晴れる"),
]

SEE = [
    "棚田: 段々の田んぼの水面が、夕焼けを映してオレンジに光る",
    "棚田で Space: 夜になり、家に灯がともり、蛍が舞う",
    "鳥居の山: 朱の鳥居のトンネルが、らせんに山頂まで登っていく",
    "鳥居の山で Space: 霧が晴れて、トンネルが金色に輝き、灯籠に火がともる",
    "鳥居の山では、クリックで中に入ると参道の入口に立ち、トンネルを歩いて山頂まで登れる",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaTerraces` にして、中身を全部置き換える。",
                    "同じように `DioramaTorii` を作って、中身を置き換える。",
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
                "ok": "夕の間の 2 つの台座が、新しいジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "黄昏の棚田",
                "body": ["E で鑑賞し、Space で夜にする。クリックで中に入り、里から棚田を見上げる。"],
                "ok": "田んぼの水面が空を映し、夜は灯と蛍が見える。",
            },
            {
                "title": "千本鳥居の山",
                "body": ["E で鑑賞し、Space で霧を晴らす。クリックで中に入り、鳥居のトンネルを歩いて登る。"],
                "ok": "鳥居がずっと続き、山頂の社まで行ける。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "棚田の段々と、空を映す水面が見える",
    "棚田で Space を押すと夜になり、灯と蛍が出る",
    "鳥居のトンネルが山を巻いて登っている",
    "鳥居の山で Space を押すと霧が晴れる",
    "どちらもクリックで中に入れる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("棚田の段がギザギザ・ちらつく",
     "段の土手は急なので、描く細かさの問題が出やすい所です。スクリーンショットを送ってください。"),
    ("鳥居が途中で切れて見える・ゆがむ",
     "スクリーンショットと、どのあたりか (ふもと・中腹・山頂) を教えてください。"),
]

NEXT = "スクリーンショットを見て、2 作品の見た目を詰めます。これで自然の部屋 4 つがそろうので、次は世界の部屋に進みます。"
