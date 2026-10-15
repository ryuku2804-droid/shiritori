"""段階25 (ヨーロッパの間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 25"
STEP_TITLE = "段階25:ヨーロッパの間「夜のパリ」と「ピサの斜塔」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "新規",
     "作品「夜のパリ」。凱旋門・シャンゼリゼの光の川・アパルトマン・セーヌ川・金色のエッフェル塔。仕掛けはきらめきとサーチライト"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "新規",
     "作品「ピサの斜塔」。大理石の斜塔・大聖堂・洗礼堂・芝生・城壁。仕掛けは鐘と鳩の群れ"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "パリとピサの地面・立つ場所・当たり判定 (建物・凱旋門・エッフェル塔の脚・斜塔・大聖堂) を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "パリのきらめきの音・ピサの鐘と鳩の羽音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「夜のパリ」を Paris、「ピサの斜塔」を Pisa で描くようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "そのまま",
     "軽くした: 影は近くだけ細かく・遠くは山の高さの表で、参道の位置の計算を使い回し、霧の計算を半分に"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "つやのある質感・景色を映す水鏡と風のさざ波・夕もやと光の筋・かまどの煙・石垣"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "世界の中に、当たり判定 (柱・木・建物) を置く"),
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
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaParis` と `DioramaPisa` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直すと、ヨーロッパの間の仮の箱が、新しい作品に変わります。",
    ],
}

OVERVIEW = ("世界の部屋の 1 つ目、ヨーロッパの間の 2 作品です。どちらも、夕の間と同じ「つやのある質感」の式で塗っています。"
            "**夜のパリ**: 手前に凱旋門と円い広場。そこから奥へ、シャンゼリゼ通りがまっすぐのび、白いヘッドライトと赤いテールライトの車が光の川になって流れます。"
            "通りの両側は並木と街灯、石造りのアパルトマン (クリーム色の石の壁と、青灰色の亜鉛のマンサード屋根)。窓のあちこちに灯りがつき、1 階のお店は明るく、"
            "濡れたような通りに光が映ります。奥にはセーヌ川、その向こうで金色に輝くエッフェル塔。川面には塔と街灯の光が揺れて映ります。"
            "Space で、**塔が白いフラッシュでキラキラきらめき、頂上の 2 本のサーチライトが夜空をぐるりと照らします**。"
            "**ピサの斜塔**: 午後遅くの金色の光の中、緑の芝生 (刈り込みの縞) に、白い大理石の 3 つの建物。グレーの縞と丸屋根の十字形の大聖堂、"
            "円い洗礼堂、そして約 5 度傾いた斜塔 (30 本の柱の回廊が 6 段、上に鐘楼)。大理石はつやがあり、少し光を通します。奥にはレンガの城壁。"
            "Space で、**3 つの鐘が交互に鳴り響き、芝生の白い鳩の群れが一斉に飛び立って、塔のまわりを旋回します**。")

FLOW = [
    ("街区 (Paris)", "地面を 0.06 のます目に分け、通り・広場・川・公園でなければ、アパルトマンを 1 棟建てる。高さはます目ごとの乱数。屋根は斜めに切ったマンサード"),
    ("エッフェル塔 (Paris)", "高さとともに細くなる幅の式。下は 4 本の脚、上は 1 本の柱、3 つの展望台。鉄の格子は、ななめの線の模様で光らせる"),
    ("光 (Paris)", "車 24 台 (ライト 2 つずつ)、街灯、サーチライトを、線に一番近づく所の距離から光の点・帯として足す。濡れた通りと川面には、反射した線で同じ光を映す"),
    ("斜塔 (Pisa)", "根元を中心に傾きを戻した座標で、まっすぐな塔として作る。柱は、円を 30 に分けて 1 本だけ作り、くり返す"),
    ("鳩 (Pisa)", "ふだんは芝生の上の白い点。仕掛けで 1 羽ずつ時間をずらして飛び立ち、塔のまわりの輪へ移る。羽ばたきで横幅が変わる"),
]

SEE = [
    "パリ: 凱旋門の向こうに光の大通り、奥で金色のエッフェル塔、川面に光が映る",
    "パリで Space: 塔がキラキラきらめき、サーチライトが回る",
    "ピサ: 白い大理石の斜塔が傾いて立ち、大聖堂と洗礼堂が並ぶ",
    "ピサで Space: 鐘が鳴り、鳩の群れが飛び立って塔のまわりを回る",
    "どちらもクリックで中に入れる (パリは凱旋門の手前、ピサは芝生の手前。建物にはぶつかる)",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaParis` にして、中身を全部置き換える。",
                    "同じように `DioramaPisa` を作って、中身を置き換える。",
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
                "ok": "ヨーロッパの間の 2 つの台座が、パリとピサのジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "夜のパリ",
                "body": ["E で鑑賞し、Space で塔をきらめかせる。クリックで中に入り、凱旋門をくぐって大通りを歩く。"],
                "ok": "車の光が流れ、塔がきらめき、サーチライトが回る。",
            },
            {
                "title": "ピサの斜塔",
                "body": ["E で鑑賞し、Space で鐘を鳴らす。クリックで中に入り、斜塔を見上げる。"],
                "ok": "鳩が飛び立って塔のまわりを回る。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "パリの街・光の大通り・エッフェル塔が見える",
    "パリで Space を押すと、塔がきらめき、サーチライトが回る",
    "ピサの斜塔が傾いていて、回廊の柱が見える",
    "ピサで Space を押すと、鳩が飛び立つ",
    "どちらもクリックで中に入れる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("台座が仮の箱のまま",
     "Console に「NightShards/Diorama/Paris (または Pisa) が見つからない」と出ていないか見てください。"),
    ("エッフェル塔や斜塔の形がおかしい",
     "スクリーンショットを送ってください。形の式を直します。"),
]

NEXT = "スクリーンショットを見て、2 作品の見た目を詰めます。そのあと、砂漠と塩の間 (ピラミッド・死海) に進みます。"
