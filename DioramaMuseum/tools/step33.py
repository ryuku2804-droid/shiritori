"""段階33 (マチュピチュを写真どおりに・アンデスの間を軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 33"
STEP_TITLE = "段階33:マチュピチュを写真の眺めに、アンデスの間を軽く"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "変更",
     "写真の眺めを再現: 青空、すきまなく並ぶ石の家、段になった住居の地区、手前の段々畑と石垣、とがったワイナピチュとウチュイピチュ、左右の高い山並み、谷底の川。軽くした"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "変更",
     "軽くした: 雲は線が通る塊の範囲だけ調べ、2 回目の計算をやめた。映り込みは少ない歩数。山と人は、近くにいないときは計算しない"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "マチュピチュの地面・家の当たり判定・立つ場所を、新しい形に合わせた"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "星空の鈴の音と、アンデスの笛 (ケーナ) の旋律、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「ウユニ塩湖」を Uyuni、「マチュピチュ」を MachuPicchu で描くようにし、説明文を新しくした"),
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
    "title": "5 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた 4 つのシェーダーと `DioramaTerrain.cs` を、中身を全部置き換えてください。組み立て直しはいりません。",
    ],
}

OVERVIEW = ("**マチュピチュ** を、送ってもらった写真 (見張り小屋の高台から見下ろす、いちばん有名な眺め) に合わせて作り直しました。"
            "空は高地の濃い青で、山の上に白いすじ雲。都市は、屋根のない灰色の石の家がすきまなくびっしり並び (高さと向きが少しずつ違い、半分ほどは三角の破風)、"
            "まん中に細長い緑の大広場。左 (西) は少し高い神殿の地区、右 (東) の住居の地区は東へ段々に下がり、段の境は石垣です。"
            "手前は見張り小屋の丘へ上がる明るい緑の段々畑で、段のふちに石垣の線。奥には、とがって急なワイナピチュと、その左の小さなウチュイピチュ。"
            "左右には深い緑の高い山並みがそびえ、右の深い谷の底にはウルバンバ川が白く光ります。遠い山ほど青くかすみます。"
            "雲海の仕掛けはそのままで、ふだんは雲海がなく、晴れた写真の景色です。"
            "**FPS**: 2 作品とも軽くしました。"
            "マチュピチュは、地形を高さの表で進み、地面から遠い所は「いちばん急な崖でも行き過ぎない歩幅」、近い所だけ坂の急さを調べて歩幅を決めます。当たったら、正確な式で 2 回合わせ直します。"
            "神殿・リャマの高さは画素ごとに 1 回だけ調べて使い回し、影は 16 歩・陰は 3 回にしました。雲海は仕掛けの最中だけ計算します。"
            "ウユニ塩湖は、雲を「線が通る雲の塊の範囲」だけで調べ、雲の不透明さを 2 回計算していたのを 1 回にし、映り込みの線は少ない歩数と粗い雲にしました。"
            "山と人は、近くにいないときは計算しません。"
            "(手元の確かめでは、マチュピチュは 1/2〜1/3、ウユニは 1/2 くらいの時間になりました。Unity の GPU では数字が変わるので、FPS を見てください。)"
            "ピラミッドと死海も、影の線が箱の外へ出たら打ち切るようにしました (箱の切り口が影を落とすこともなくなります)。")

FLOW = [
    ("行き過ぎない歩幅", "地面までの高さの差 × 0.31 だけ進めば、傾き 3 (いちばん急な崖) までは地面を通り抜けない。地面の近くでは、その場所の坂の急さで歩幅を広げる"),
    ("合わせ直し", "高さの表は 1.8 mm ごとの点を結んだもので、少しなまっている。当たった前後の 2 点を結ぶ直線で、正確な地面との交わる所をさがす"),
    ("使い回し", "神殿・見張り小屋・リャマの地面の高さは、Map のたびに表を読まず、画素の最初に 1 回だけ読んで覚えておく"),
    ("雲の範囲 (Uyuni)", "6 つの雲の塊を包む球と線の交わりを先に計算し、その範囲の中だけを 14 か所 (映り込みは 8 か所) 調べる"),
]

SEE = [
    "マチュピチュ: 写真と同じ、青空の下の石の都市とワイナピチュ",
    "マチュピチュ: 手前の段々畑、右の谷の川、左右の高い山",
    "2 作品とも FPS が上がっている",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "5 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaMachuPicchu.shader`・`DioramaUyuni.shader`・`DioramaPyramids.shader`・`DioramaDeadSea.shader`・`DioramaTerrain.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、シェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "確かめる",
        "steps": [
            {
                "title": "マチュピチュの眺め",
                "body": ["クリックで中に入る (見張り小屋のそばの段々畑に立つ)。写真と見くらべる。"],
                "ok": "写真に近い眺めになっている。",
            },
            {
                "title": "FPS を送る",
                "body": ["2 作品それぞれ、外からと中からの FPS (F1) と、スクリーンショットを送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "マチュピチュが写真の眺めに近い",
    "ウユニ・マチュピチュの FPS が上がった",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("中に入ると、家にめりこむ・地面の下に落ちる",
     "スクリーンショットを送ってください。当たり判定を直します。"),
    ("まだ FPS が低い",
     "どの作品の、外・中のどちらで低いかと、その数字を送ってください。"),
]

NEXT = "FPS とスクリーンショットを見て詰めます。そのあと、最後の世界の部屋、アジアの間 (万里の長城・日本の庭) に進みます。"
