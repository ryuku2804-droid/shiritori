"""段階35 (金閣寺の鯉・アジアの間を軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 35"
STEP_TITLE = "段階35:金閣寺の池に鯉、アジアの間を軽く"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "変更",
     "池に 56 匹の鯉 (紅白・大正三色・黄金・山吹・緋鯉・烏鯉)。呼ばれると集まって水面で口をぱくぱく、波の輪。軽くした"),
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "変更",
     "軽くした: 地面の向きを高さの表から測る・山の木々の陰の計算を省く・歩数を減らす"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "金閣寺の世界の中で池をクリックすると、その場所へ鯉を呼ぶ (ぱしゃぱしゃの音つき)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "世界の中のクリックを「クリックで動かした」と DioramaWork に伝える"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "金閣寺の池の水面の高さと「そこが池か」を、ほかのスクリプトから使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「万里の長城」を GreatWall、「日本の庭」を Kinkaku で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "そのまま",
     "写真の眺めを再現: 青空、すきまなく並ぶ石の家、段になった住居の地区、手前の段々畑と石垣、とがったワイナピチュとウチュイピチュ、左右の高い山並み、谷底の川。軽くした"),
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "そのまま",
     "軽くした: 雲は線が通る塊の範囲だけ調べ、2 回目の計算をやめた。映り込みは少ない歩数。山と人は、近くにいないときは計算しない"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "そのまま",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "そのまま",
     "影の線が箱の外へ出たら打ち切る (少し軽くなる)"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "エッフェル塔と凱旋門だけを大きく (塔は 2.2 倍・門は 3 倍)。まわりはエトワール広場の石畳を回る車のライトと、シャン・ド・マルスの芝生"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "斜塔だけを大きく (5.5 倍)。正面から見て右へ傾く。足元は大理石の敷石と芝生、鳩"),
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
        "右のタブで ● の付いた 2 つのシェーダーと 3 つのスクリプトを、中身を全部置き換えてください。組み立て直しはいりません。",
    ],
}

OVERVIEW = ("**鯉**: 鏡湖池に、56 匹の鯉を放しました。紅白・大正三色 (紅白に黒)・黄金・山吹・緋鯉・烏鯉で、模様は 1 匹ずつ違います。"
            "それぞれ池の中のすみかのまわりを、ゆっくり大きな輪をえがいて泳ぎ、体をくねらせ、尾びれと胸びれは少しすけて明るく見えます。深い所を泳ぐ鯉ほど、水の緑に沈んで暗く見えます。"
            "**金閣寺の世界の中で池をクリックすると (画面のまん中の照準の先)、近くの鯉から順に、その場所へ集まってきます**。"
            "水面のすぐ下まで上がって、口を寄せ合うように小さく回り、水面に波の輪が広がって、ぱしゃぱしゃと音がします。12 秒ほどすると、またもとの泳ぎにもどります。"
            "池以外の所をクリックすると、これまでどおり、もみじが舞い散ります (鑑賞モードの Space も、もみじ)。"
            "**FPS**: 2 作品とも軽くしました。"
            "いちばん効くのは、地面の面の向きを、高さの表から 4 回読むだけで測るようにしたことです (前は、山・池・島・木々の式を 4 回計算していました)。細かいでこぼこは、塗るときの凹凸で足しています。"
            "金閣寺は、池の映り込みを 64 歩から 40 歩にし、上を向いてはね返る線 (空しか映らない) はたどらないようにしました。鯉は、近くを通るかを先に安く調べ、遠い鯉はすぐに飛ばします。"
            "長城は、山の木々の陰の計算を省き (木の頭の明暗で十分)、歩数を 160 から 130 にしました。")

FLOW = [
    ("鯉の場所", "鯉ごとに、池の中のすみか・泳ぐ輪の大きさ・速さ・向きを乱数で決める。呼ばれると、すみかからの距離に応じて遅れて、呼んだ場所のまわりの小さな輪へ移る"),
    ("鯉を描く", "水面を通った線が、鯉の泳ぐ深さの平らな面と交わる所で、鯉の向きにそった座標 (頭〜尾・左右) を作り、体・尾びれ・胸びれの形と模様を塗る"),
    ("クリックの場所", "画面のまん中からの線を、ジオラマの箱の座標に直して、水面の高さの面と交わる所を求める。そこが池なら、その場所と時刻をシェーダーの _KoiCall に渡す"),
    ("地面の向き", "高さの表を、前後左右に 1.5 mm ずらして 4 回読み、その差から坂の向きを出す"),
]

SEE = [
    "金閣寺の池に、色とりどりの鯉が泳いでいる",
    "世界の中で池をクリックすると、鯉が集まってきて、波の輪が広がる",
    "2 作品とも FPS が上がっている",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "5 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaKinkaku.shader`・`DioramaGreatWall.shader`・`DioramaWork.cs`・`DioramaWorld.cs`・`DioramaTerrain.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがなく、シェーダーの Inspector にもエラーがない。",
            },
        ],
    },
    {
        "title": "確かめる",
        "steps": [
            {
                "title": "鯉を呼ぶ",
                "body": ["金閣寺をクリックして中に入り、池の水面に照準を合わせてクリックする。"],
                "ok": "鯉が集まってきて、水面で口をぱくぱくさせる。",
            },
            {
                "title": "FPS を送る",
                "body": ["2 作品それぞれ、外からと中からの FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "金閣寺の池に鯉が泳いでいる",
    "池をクリックすると鯉が集まる",
    "長城・金閣寺の FPS が上がった",
]

TROUBLE = [
    ("池をクリックしても鯉が来ない",
     "照準 (画面のまん中) が池の水面を向いているか確かめてください。それでも来ないときは、カメラに MainCamera の札 (Tag) が付いているか見てください。"),
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("まだ FPS が低い",
     "どの作品の、外・中のどちらで低いかと、その数字を送ってください。"),
]

NEXT = "FPS とスクリーンショットを見て詰めます。そのあと、最後に VR に対応させます。"
