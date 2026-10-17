"""段階32 (アンデスの間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 32"
STEP_TITLE = "段階32:アンデスの間「ウユニ塩湖」と「マチュピチュ」"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaUyuni.shader", "新規",
     "作品「ウユニ塩湖」。天空の鏡: 水の張った塩の平原が、空・積雲・車・人・トゥヌパ火山を映す。仕掛けは夕焼けから満天の星と天の川へ"),
    ("Assets/NightShards/Museum/Shaders/DioramaMachuPicchu.shader", "新規",
     "作品「マチュピチュ」。尾根の上の石の都市・大広場・インティワタナ・太陽の神殿・段々畑・見張り小屋・ワイナピチュ・リャマ。仕掛けは雲海がわき上がって包み、引くと朝日"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "ウユニ塩湖とマチュピチュの地面・立つ場所・当たり判定・拡大の倍率を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "星空の鈴の音と、アンデスの笛 (ケーナ) の旋律、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「ウユニ塩湖」を Uyuni、「マチュピチュ」を MachuPicchu で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "変更",
     "なだらかな所で面の向きが短くなる小さな誤りを直した (見た目はほぼ同じ)"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "同じ小さな誤りを直した"),
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
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaUyuni` と `DioramaMachuPicchu` にして、中身を全部置き換えてください。",
        "`DioramaPyramids.shader`・`DioramaDeadSea.shader` と、スクリプト 3 つも貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直します。",
        "台座の説明文が古いままなら、**設計図を初期設定に戻して組み立てる** を使ってください。",
    ],
}

OVERVIEW = ("世界の部屋の 3 つ目、アンデスの間の 2 作品です。"
            "**ウユニ塩湖** は 1 m = 0.01。雨季の「天空の鏡」です。真っ白な塩の平原に数 cm の雨水が張り、空と雲を鏡のように映します。"
            "ガラスケースの中には、もくもくの積雲が浮かび、その下の鏡にも上下さかさまに映ります。真上から見ると、水の下の塩の六角形の模様が透けます。"
            "鏡の上には、屋根に荷物を積んだ白いランドクルーザーと、写真を撮る 5 人 (両手を上げる人、ジャンプする人)。足元から小さな波の輪が広がります。"
            "奥には、赤・黄土色の地層のトゥヌパ火山と低い山並み。"
            "Space で、**夕焼けに染まって太陽が沈み、やがて満天の星と天の川が、空と鏡の上下に広がって、星の中に浮かびます**。車のヘッドライトとランタンがともります。"
            "**マチュピチュ** は 1 m = 0.0007。美術館の正面が南で、南の見張り小屋の高台から北を見る、絵はがきと同じ眺めです。"
            "標高 2430 m の尾根の上に、まん中の芝生の大広場をはさんで、西 (左) に神殿の地区、東 (右) に住居の地区。屋根のない石の家が並び、両はしに三角の破風が立ち、いくつかは復元したかやぶき屋根です。"
            "4 段の石垣の丘のてっぺんにインティワタナ (日時計の石)、大きな岩の上に半円の壁の太陽の神殿。南と両側の斜面には、高さ約 3 m の石垣の段々畑。"
            "見張り小屋のまわりの段々畑には、リャマがのんびり歩きます。奥には、上のまるい急な山ワイナピチュがそびえ、両側は雲霧林の深い緑の谷へ落ちます。"
            "谷には雲海がたまっています。Space で、**雲海がわき上がって都市をすっかり包み、やがて引いて、朝日が都市を金色に照らし出します**。")

FLOW = [
    ("鏡 (Uyuni)", "水面は平らな 1 枚として、別に計算する。水面に当たった線は、はね返った向きで、もう一度、物と雲と空をたどる。そのまま映るので、地平線が消える"),
    ("雲 (Uyuni)", "6 つの雲の塊 (それぞれ大小 3 つのふくらみ) の中を 14 か所調べ、太陽の方向に 1 か所だけ調べた濃さで、上が明るく下が暗い雲にする"),
    ("星空 (Uyuni)", "空の向きを細かいます目に分け、ます目ごとの乱数で星を置く。天の川の帯の中は星を多く、暗い筋を混ぜる"),
    ("尾根の地形 (MachuPicchu)", "くねる尾根の線から離れるほど急に下がる。都市の所は平らにし、段々畑の所は高さを 3 m ごとの段に切る。斜面は、深い所ほど大きな谷筋と尾根"),
    ("家 (MachuPicchu)", "都市の地区を 11 m × 7.7 m のます目に分け、ます目ごとに家を 1 軒。壁だけの箱に、短い辺の三角の破風と戸口。家ごとに少しずらし、大きさを変える"),
    ("雲海 (MachuPicchu)", "雲の上面の高さを、仕掛けで谷底から都市の上まで上げて、また下げる。上面より下を通る線だけ、16 か所で濃さを調べる"),
]

SEE = [
    "ウユニ: 空と雲が足元に映り、地平線が消える。車と人も映る",
    "ウユニで Space: 夕焼け → 満天の星と天の川が上下に",
    "マチュピチュ: 尾根の上の石の都市、大広場、段々畑、ワイナピチュ",
    "マチュピチュで Space: 雲海が都市を包み、引くと朝日",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaUyuni` にして、中身を全部置き換える。",
                    "同じように `DioramaMachuPicchu` を作って、中身を置き換える。",
                    "`DioramaPyramids.shader` と `DioramaDeadSea.shader` も貼り直す。",
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
                "ok": "アンデスの間の 2 つの台座が、ウユニ塩湖とマチュピチュのジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "ウユニ塩湖",
                "body": ["E で鑑賞し、Space で夜にする。クリックで中に入り、鏡の上を歩く (足元に空が映る)。"],
                "ok": "雲と空が鏡に映り、夜には星の中に浮かぶ。",
            },
            {
                "title": "マチュピチュ",
                "body": ["E で鑑賞し、Space で雲海を起こす。クリックで中に入り、見張り小屋のそばから都市へ下りる。"],
                "ok": "雲海が都市を包み、引くと朝日に照らされる。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "ウユニの鏡に、空・雲・車・人が映る",
    "ウユニで Space: 夕焼け → 星空",
    "マチュピチュの都市とワイナピチュが見える",
    "マチュピチュで Space: 雲海 → 朝日",
    "どちらもクリックで中に入れる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("台座が仮の箱のまま",
     "Console に「NightShards/Diorama/Uyuni (または MachuPicchu) が見つからない」と出ていないか見てください。"),
    ("FPS が下がった",
     "F1 の数字と、どの作品を見ていたかを送ってください。雲や鏡の計算を軽くします。"),
]

NEXT = "スクリーンショットを見て詰めます。そのあと、最後の世界の部屋、アジアの間 (万里の長城・日本の庭) に進みます。"
