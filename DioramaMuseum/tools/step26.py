"""段階26 (ヨーロッパの間を実物どおりに作り直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 26"
STEP_TITLE = "段階26:ヨーロッパの間を、実物の細部まで作り直す"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "変更",
     "実物の寸法 (1 m = 0.001) で作り直した。格子に穴の空いたエッフェル塔、凱旋門の彫刻と盾、オスマン様式のアパルトマン、星形の大通り、イエナ橋、遊覧船"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "変更",
     "実物の寸法と並びで作り直した。斜塔の 15 のめくらアーチと 30 本の柱の回廊、大聖堂の正面の 4 段の柱廊とブロンズの扉、洗礼堂の破風と赤い瓦、カンポサント"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "パリとピサの当たり判定・立つ場所を新しい形に合わせた。作品ごとに、中に入ったときの拡大の倍率を決められるようにした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "作品が決めた拡大の倍率で世界を作る (実物の寸法の作品は、もっと大きくして人の大きさに近づける)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "パリのきらめきの音・ピサの鐘と鳩の羽音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「夜のパリ」を Paris、「ピサの斜塔」を Pisa で描くようにした"),
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
    "title": "4 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた `DioramaParis.shader`・`DioramaPisa.shader`・`DioramaTerrain.cs`・`DioramaWorld.cs` を、中身を全部置き換えてください。",
        "組み立て直しはいりません (Play を押せば、新しい形で見えます)。",
    ],
}

OVERVIEW = ("ヨーロッパの間の 2 作品を、実物の寸法・形・並び方に合わせて作り直しました。"
            "**夜のパリ** は 1 m = 0.001 (箱の幅が 940 m)。"
            "**凱旋門** は高さ 50 m・幅 45 m・奥行き 22 m。前後に抜ける大アーチ (幅 14.6 m・高さ 29 m) と左右に抜ける小アーチ、アーチの付け根の帯、軒と帯、"
            "軒の下に並ぶ 30 の盾、4 本の柱に浮き出る彫刻群 (ラ・マルセイエーズなど)、大アーチの天井の格間、足元で燃え続ける無名戦士の墓の炎。"
            "まわりのエトワール広場は濡れた石畳で、そこから **12 本の大通りが星形** にのび、その 1 本がシャンゼリゼ通り (8 車線・2 列の並木・街灯)。"
            "**アパルトマン** はオスマン様式: 角を斜めに切った街区と中庭、軒の高さ約 20 m、1 階のお店と中 2 階、2 階と 5 階の鉄のバルコニー、"
            "45 度の亜鉛のマンサード屋根と屋根窓、テラコッタの煙突。窓の灯りは家ごとに違い、テレビの青い光の窓も。"
            "**エッフェル塔** は高さ 300 m (アンテナ込み 330 m)、土台 125 m 四方。4 本の脚が 2 階の上で 1 本にまとまり、展望台は 57 m・116 m・276 m。"
            "脚の間の飾りアーチ。鉄の格子は **本当に穴が空いていて**、向こうの夜空がすけて見えます。"
            "セーヌ川は 8 m 下を流れ、岸には一段低い川辺の道。塔の前には 5 つのアーチの **イエナ橋**、川には明かりのついた **遊覧船** が行き来します。"
            "**ピサの斜塔** は 1 m = 0.003 で、建物の向きも実物どおり。美術館の正面が南で、左から **洗礼堂・大聖堂・斜塔** が並ぶ、絵はがきと同じ眺めです。"
            "**斜塔** は高さ 56 m・直径 15.5 m で、南へ 3.97 度。1 層目は 15 のめくらアーチと付け柱 (中にひし形の象眼)、2〜7 層目は 30 本の柱の回廊が 6 段で、"
            "柱のすき間から回廊の奥が見えます。上に 12 のアーチ窓の鐘楼と、中のブロンズの鐘。"
            "**大聖堂** は長さ 100 m の十字形で 5 つの廊。下のほうはグレーと白の縞の大理石、壁には付け柱とめくらアーチ。正面は 1 階の 7 つのめくらアーチと 3 つのブロンズの扉、"
            "その上に **細い柱の回廊が 4 段** と三角の切妻。交差部に楕円の丸屋根、東に半円の後陣、翼廊の両端にも小さな後陣。"
            "**洗礼堂** は直径 34 m・高さ 55 m。20 のアーチ、細い柱の回廊、ゴシックの破風と小尖塔、**東半分が赤い瓦・西半分が鉛** の丸屋根と、てっぺんの像。"
            "北には **カンポサント** (墓所の回廊)、北と西にはレンガの城壁。芝生には灰色の鳩。"
            "仕掛けは前と同じです (パリ: 塔のきらめき、ピサ: 鐘と鳩)。"
            "中に入ると、実物の大きさに近づくよう、パリは 400 倍、ピサは 250 倍に広がります (前は 120 倍)。")

FLOW = [
    ("実物の寸法", "パリは 1 m = 0.001、ピサは 1 m = 0.0022 で形を作り、全体を 1.35 倍にして置く。寸法は実物の図面の値 (高さ・幅・展望台の高さ・柱の数) をそのまま使う"),
    ("エッフェル塔の格子", "塔の幅の式を、展望台での実物の幅に合わせた。面の上に X 字の筋交いと横の梁だけを残し、残りを穴にする。遠くの細い格子は、当たったとみなす近さを距離に合わせて大きくして、1 画素くらいの太さで描く"),
    ("アパルトマン", "街区の外形 (角を斜めに切る)・中庭・マンサード屋根を 1 つの式で作り、窓・バルコニー・お店は、壁の上の位置から塗り分ける"),
    ("円く並ぶもの", "斜塔の柱・アーチ、洗礼堂の破風は、円をいくつかに分けて 1 つ分だけ作り、くり返す。アーチは「下は四角・上は半円」の形で壁をくり抜く"),
    ("ピサの向き", "形の式は西 → 東の向きのまま、Frag の最初でカメラの向きを回して、美術館の正面が南になるようにする"),
    ("拡大の倍率", "DioramaTerrain の作品の情報に worldScale を足し、DioramaWorld がその倍率で世界と当たり判定を作る"),
]

SEE = [
    "パリ: 凱旋門の彫刻と盾、アーチの天井の格間、足元の炎",
    "パリ: アパルトマンのバルコニー・屋根窓・煙突、1 階のお店の灯り",
    "パリ: エッフェル塔の格子のすき間から夜空が見える。展望台の窓の灯り",
    "パリ: 星形の大通り、イエナ橋、川の遊覧船",
    "ピサ: 正面から見て、左に洗礼堂・まん中に大聖堂・右に斜塔",
    "ピサ: 斜塔の回廊の柱のすき間、鐘楼の鐘、大聖堂の正面の 4 段の柱廊とブロンズの扉",
    "ピサ: 洗礼堂の東半分が赤い瓦",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "4 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaParis.shader`・`DioramaPisa.shader`・`DioramaTerrain.cs`・`DioramaWorld.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、2 つのシェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "夜のパリ",
                "body": ["E で鑑賞し、近づいて凱旋門・アパルトマン・エッフェル塔を見る。クリックで中に入り、凱旋門をくぐってシャンゼリゼを歩き、イエナ橋をわたる。"],
                "ok": "塔の格子のすき間から向こうが見え、街が実物の大きさに近く感じる。",
            },
            {
                "title": "ピサの斜塔",
                "body": ["E で鑑賞し、Space で鐘を鳴らす。クリックで中に入り、斜塔の足元まで歩いて見上げる。"],
                "ok": "斜塔の回廊の柱のすき間から奥の壁が見え、鳩が塔のまわりを回る。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外からと中からのスクリーンショットと、FPS (F1) を送ってください。重ければ、格子や柱を軽くする手があります。"],
            },
        ],
    },
]

CHECKS = [
    "凱旋門・エッフェル塔・アパルトマンの細部が見える",
    "エッフェル塔の格子が透けている",
    "ピサは左から洗礼堂・大聖堂・斜塔の順に並ぶ",
    "斜塔の回廊の柱のすき間が見える",
    "どちらもクリックで中に入れ、建物にぶつかる。パリはイエナ橋で川をわたれる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("FPS が下がった",
     "F1 の数字と、どの作品を見ていたかを送ってください。遠くの格子・柱を省く「遠いほど簡単にする」しかけを足します。"),
    ("中に入ったら、建物の中に立っていた / すぐ落ちた",
     "スクリーンショットを送ってください。立つ場所を直します。"),
]

NEXT = "スクリーンショットを見て、2 作品を詰めます。そのあと、砂漠と塩の間 (ピラミッド・死海) に進みます。"
