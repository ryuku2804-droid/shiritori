"""段階27 (ヨーロッパの間: 名所だけを大きく) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 27"
STEP_TITLE = "段階27:エッフェル塔と凱旋門、ピサの斜塔だけを大きく"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "変更",
     "エッフェル塔と凱旋門だけを大きく (塔は 2.2 倍・門は 3 倍)。まわりはエトワール広場の石畳を回る車のライトと、シャン・ド・マルスの芝生"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "変更",
     "斜塔だけを大きく (5.5 倍)。正面から見て右へ傾く。足元は大理石の敷石と芝生、鳩"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "パリとピサの当たり判定・立つ場所・拡大の倍率を、新しい大きさに合わせた"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
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
    "title": "3 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた `DioramaParis.shader`・`DioramaPisa.shader`・`DioramaTerrain.cs` を、中身を全部置き換えてください。",
        "組み立て直しはいりません。",
    ],
}

OVERVIEW = ("ヨーロッパの間の 2 作品を、名所だけを大きく見せる形にしました。形の細部 (格子・彫刻・柱の回廊) は段階26の実物どおりのままです。"
            "**夜のパリ**: アパルトマン・川・橋をなくし、**エッフェル塔と凱旋門だけ** を置きました。"
            "エッフェル塔は 2.2 倍 (箱の高さの 7 割をこえる高さ) で、格子のすき間から夜空が見えます。頂上から灯台の光が回ります。"
            "凱旋門は 3 倍で、手前の左に置き、塔の脚を隠さないようにしました。まわりはエトワール広場の濡れた石畳で、**車のライトが門のまわりをぐるぐる回り**、石畳に映ります。"
            "広場から塔へ街灯の並ぶ道がのび、塔の足元はシャン・ド・マルスの芝生と砂利です。"
            "※ 2 つとも大きく見せるため、塔と門の倍率を変えています (実物どうしの大きさの比は、塔のほうがもっと大きい)。"
            "**ピサの斜塔**: 大聖堂・洗礼堂・城壁をなくし、**斜塔だけを 5.5 倍** (箱の高さの 7 割) で真ん中に置きました。"
            "美術館の正面から見て、右へ 3.97 度傾きます。1 層目のめくらアーチと付け柱、30 本の柱の回廊 6 段、鐘楼と鐘まで、間近で見えます。"
            "足元は大理石の敷石と正面の小道、刈り込みの縞の芝生。Space で鐘が鳴り、鳩が塔のまわりを大きく回ります。"
            "中に入ると、パリは 400 倍、ピサは 85 倍に広がり、どちらも名所が実物に近い大きさに見えます。")

FLOW = [
    ("名所だけを大きく", "形は実物の寸法の式のまま。置く場所を中心に、調べる位置を倍率で縮めてから形の式に入れ、出てきた距離に倍率を掛ける (形がそのまま大きくなる)"),
    ("模様", "石の目地・格子の光・きらめきなどの模様も、縮めた位置で調べるので、大きさに合わせて広がる"),
    ("車の光 (Paris)", "凱旋門のまわりの円の上を、車ごとに違う速さで回る。前に白いライト 2 つ、後ろに赤いライト 2 つ"),
    ("当たり判定", "凱旋門の 4 本の柱・エッフェル塔の 4 本の脚・斜塔を、同じ倍率で大きくした"),
]

SEE = [
    "パリ: 大きなエッフェル塔の格子のすき間と、展望台の灯り",
    "パリ: 凱旋門の彫刻と盾、まわりを回る車のライト",
    "ピサ: 大きな斜塔が右へ傾き、回廊の柱のすき間から奥の壁が見える",
    "ピサで Space: 鳩が塔のまわりを回る",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "3 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaParis.shader`・`DioramaPisa.shader`・`DioramaTerrain.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、2 つのシェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "夜のパリ",
                "body": ["E で鑑賞し、Space で塔をきらめかせる。クリックで中に入り、凱旋門をくぐってエッフェル塔の足元まで歩く。"],
                "ok": "塔と門が大きく、車のライトが門のまわりを回る。",
            },
            {
                "title": "ピサの斜塔",
                "body": ["E で鑑賞し、Space で鐘を鳴らす。クリックで中に入り、斜塔の足元まで歩いて見上げる。"],
                "ok": "斜塔が大きく傾いて立ち、鳩が塔のまわりを回る。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外からと中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "パリはエッフェル塔と凱旋門だけが大きく見える",
    "ピサは斜塔だけが大きく見え、右へ傾いている",
    "どちらもクリックで中に入れ、塔の脚・門の柱・斜塔にぶつかる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("FPS が下がった",
     "F1 の数字と、どの作品を見ていたかを送ってください。遠くの格子・柱を省いて軽くします。"),
]

NEXT = "スクリーンショットを見て、2 作品を詰めます。そのあと、砂漠と塩の間 (ピラミッド・死海) に進みます。"
