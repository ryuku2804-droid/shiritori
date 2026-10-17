"""段階34 (アジアの間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 34"
STEP_TITLE = "段階34:アジアの間「万里の長城」と「日本の庭 (金閣寺)」"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaGreatWall.shader", "新規",
     "作品「万里の長城」。秋の山の尾根をうねる城壁と 4 つの望楼 (狭間・アーチ窓・のろし台)、紅葉と松の山、谷の雲海。仕掛けは夕暮れと、望楼から望楼へ伝わるのろし"),
    ("Assets/NightShards/Museum/Shaders/DioramaKinkaku.shader", "新規",
     "作品「日本の庭」(金閣寺)。3 層の舎利殿 (白木と蔀戸・金箔・花頭窓・鳳凰)、鏡湖池の映り込み、松の島、もみじの山。仕掛けはもみじが舞い散って池に浮かぶ"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "長城と金閣寺の地面・立つ場所・当たり判定・拡大の倍率を足した (同じ名前の関数 Ridged がぶつかるエラーを直した)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "のろしの角笛と火の音、お寺の鐘と木々のざわめき、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
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
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaGreatWall` と `DioramaKinkaku` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直します。",
        "台座の説明文が古いままなら、**設計図を初期設定に戻して組み立てる** を使ってください。",
    ],
}

OVERVIEW = ("最後の世界の部屋、アジアの間の 2 作品です。これで 8 つの部屋の 16 作品がすべてそろいます。"
            "**万里の長城** は、慕田峪・金山嶺のあたりの明代の長城です (形は 1 m = 0.002 の実物の寸法で作り、城壁と望楼は 2 倍に大きくして置いています)。"
            "城壁 (高さ 7 m・上の幅 7 m) は、急な尾根のいちばん高い所をうねりながら上り下りします。上は歩ける石畳の通路で、外側にのこぎりの歯のような狭間、内側に低い胸壁。灰色のれんがを 1 段ずつずらして積んでいます。"
            "望楼 (敵楼) が 4 つ。11 m 四方・2 階建てで、各面にアーチ窓が 3 つ、通路が中を通り抜け、屋上に狭間とのろし台があります。"
            "まわりは秋の山で、赤・橙・黄色の紅葉に緑の松がまだらに混ざり、谷には雲海。"
            "Space で、**夕暮れになり、手前の望楼から奥の望楼へ、のろしが 1.3 秒ずつ遅れて次々にともり、煙を上げながら尾根を伝っていきます**。"
            "**日本の庭** は、秋の金閣寺 (鹿苑寺) です (1 m = 0.008。金閣は 2 倍)。美術館の正面が南で、池の南の岸から北の金閣を見る、いちばん有名な眺めです。"
            "舎利殿は 3 層。1 層 (法水院) は白木の柱と白い格子の蔀戸、2 層 (潮音洞) は金箔で縁の手すり、3 層 (究竟頂) は金箔の正方形の仏殿で、上が火炎の形にとがる花頭窓。"
            "こけら葺きのこげ茶の屋根が 3 重に張り出し、てっぺんに金の鳳凰。池に張り出した石の舟着きもあります。"
            "金箔は金属として塗っているので、空ともみじの色を映して光ります。"
            "鏡湖池の静かな水面は、金閣ともみじの山と空を鏡のように映し、葦原島 (松の島) と小さな島々が浮かびます。奥は衣笠山。"
            "Space で、**風が吹いて水面にさざ波が立ち、もみじの葉がくるくる舞い散って、池の水面にだんだん浮かんでいきます**。お寺の鐘がゴーンと響きます。")

FLOW = [
    ("城壁の線 (GreatWall)", "城壁が通る線 x = Path(z) と、尾根の高さ Crest(z) を、なめらかな式で決める。地形は、その線から離れるほど急に下がる"),
    ("城壁と望楼 (GreatWall)", "線からの横の距離と、線にそった位置と、尾根からの高さの 3 つで、城壁の断面 (通路・狭間・胸壁) と望楼の形を作る"),
    ("雲海 (GreatWall)", "雲海の層の中を通る長さから、一度に濃さを決める (何か所も調べない)"),
    ("金閣 (Kinkaku)", "柱は、前後の面では x の位置、左右の面では z の位置に、外まわりの薄い所だけに並べる。屋根は、上へ行くほどすぼまる台形と、宝形造りの反った四角すい"),
    ("鏡湖池 (Kinkaku)", "水面は平らな 1 枚として別に計算し、はね返った線で景色をもう一度たどる。もみじが浮かぶのは、水面を細かいます目に分け、時間とともに葉のあるます目をふやす"),
]

SEE = [
    "長城: 尾根をうねる城壁と望楼、紅葉の山、谷の雲海",
    "長城で Space: 夕暮れ → のろしが手前から奥へ伝わる",
    "金閣寺: 池に映る金閣 (白い 1 層・金色の 2 層と 3 層・鳳凰)",
    "金閣寺で Space: もみじが舞い散り、池に浮かぶ",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaGreatWall` にして、中身を全部置き換える。",
                    "同じように `DioramaKinkaku` を作って、中身を置き換える。",
                ],
                "ok": "シェーダーの Inspector に、エラーが出ていない。",
            },
            {
                "title": "スクリプトを 3 つ貼り直す",
                "body": ["右のタブで ● の付いた `DioramaTerrain.cs`・`DioramaWork.cs`・`MuseumLayout.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "アジアの間の 2 つの台座が、長城と金閣寺のジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "万里の長城",
                "body": ["E で鑑賞し、Space でのろしを上げる。クリックで中に入り、城壁の通路を歩いて、望楼の中を通り抜ける。"],
                "ok": "のろしが望楼から望楼へ伝わる。",
            },
            {
                "title": "日本の庭",
                "body": ["E で鑑賞し、Space で風を吹かせる。クリックで中に入り、池の岸から金閣を見る。"],
                "ok": "金閣が池に映り、もみじが舞い散る。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "長城の城壁と望楼が、尾根にそってうねる",
    "長城で Space: のろしが伝わる",
    "金閣が池に映る",
    "金閣寺で Space: もみじが舞って池に浮かぶ",
    "どちらもクリックで中に入れる",
]

TROUBLE = [
    ("「already defines a member called \'Ridged\'」のエラー",
     "直しました。`DioramaTerrain.cs` を最新に貼り直してください (長城の関数の名前を WallRidged に変えました)。"),
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("台座が仮の箱のまま",
     "Console に「NightShards/Diorama/GreatWall (または Kinkaku) が見つからない」と出ていないか見てください。"),
    ("FPS が低い",
     "F1 の数字と、どの作品を見ていたかを送ってください。"),
]

NEXT = "これで世界の部屋もすべてそろいました。スクリーンショットを見て詰めたあと、最後に VR に対応させます。"
